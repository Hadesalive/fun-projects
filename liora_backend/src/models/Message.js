import mongoose from 'mongoose';

const messageSchema = new mongoose.Schema({
  conversation: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Conversation',
    required: true,
  },
  sender: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  type: {
    type: String,
    enum: ['text', 'image', 'video', 'audio', 'file', 'system'],
    required: true,
    default: 'text',
  },
  content: {
    text: {
      type: String,
      maxlength: [4000, 'Message text cannot exceed 4000 characters'],
    },
    media: {
      url: String,
      thumbnailUrl: String,
      filename: String,
      size: Number,
      mimeType: String,
      duration: Number, // For audio/video files
      dimensions: {
        width: Number,
        height: Number,
      },
    },
    system: {
      action: {
        type: String,
        enum: ['user_joined', 'user_left', 'user_added', 'user_removed', 'name_changed', 'avatar_changed'],
      },
      data: mongoose.Schema.Types.Mixed,
    },
  },
  replyTo: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Message',
  },
  reactions: [{
    emoji: {
      type: String,
      required: true,
    },
    users: [{
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    }],
    count: {
      type: Number,
      default: 0,
    },
  }],
  readBy: [{
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
    readAt: {
      type: Date,
      default: Date.now,
    },
  }],
  deliveredTo: [{
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
    deliveredAt: {
      type: Date,
      default: Date.now,
    },
  }],
  editedAt: {
    type: Date,
  },
  deletedAt: {
    type: Date,
  },
  isDeleted: {
    type: Boolean,
    default: false,
  },
  expiresAt: {
    type: Date,
    // For disappearing messages
  },
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true },
});

// Indexes for better query performance
messageSchema.index({ conversation: 1, createdAt: -1 });
messageSchema.index({ sender: 1, createdAt: -1 });
messageSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 }); // TTL index for disappearing messages

// Validate message content based on type
messageSchema.pre('save', function(next) {
  switch (this.type) {
    case 'text':
      if (!this.content.text || this.content.text.trim() === '') {
        return next(new Error('Text message must have content'));
      }
      break;
    case 'image':
    case 'video':
    case 'audio':
    case 'file':
      if (!this.content.media || !this.content.media.url) {
        return next(new Error('Media message must have media URL'));
      }
      break;
    case 'system':
      if (!this.content.system || !this.content.system.action) {
        return next(new Error('System message must have action'));
      }
      break;
  }
  next();
});

// Virtual for reaction summary
messageSchema.virtual('reactionSummary').get(function() {
  return this.reactions.map(reaction => ({
    emoji: reaction.emoji,
    count: reaction.count,
    hasReacted: false, // This will be set in the API based on current user
  }));
});

// Instance method to add reaction
messageSchema.methods.addReaction = function(emoji, userId) {
  let reaction = this.reactions.find(r => r.emoji === emoji);
  
  if (!reaction) {
    reaction = { emoji, users: [], count: 0 };
    this.reactions.push(reaction);
  }
  
  if (!reaction.users.includes(userId)) {
    reaction.users.push(userId);
    reaction.count += 1;
  }
  
  return this.save();
};

// Instance method to remove reaction
messageSchema.methods.removeReaction = function(emoji, userId) {
  const reaction = this.reactions.find(r => r.emoji === emoji);
  
  if (reaction) {
    reaction.users = reaction.users.filter(id => id.toString() !== userId.toString());
    reaction.count = reaction.users.length;
    
    if (reaction.count === 0) {
      this.reactions = this.reactions.filter(r => r.emoji !== emoji);
    }
  }
  
  return this.save();
};

// Instance method to mark as read by user
messageSchema.methods.markAsRead = function(userId) {
  const existingRead = this.readBy.find(read => 
    read.user.toString() === userId.toString()
  );
  
  if (!existingRead) {
    this.readBy.push({
      user: userId,
      readAt: new Date(),
    });
  }
  
  return this.save();
};

// Instance method to mark as delivered to user
messageSchema.methods.markAsDelivered = function(userId) {
  const existingDelivery = this.deliveredTo.find(delivery => 
    delivery.user.toString() === userId.toString()
  );
  
  if (!existingDelivery) {
    this.deliveredTo.push({
      user: userId,
      deliveredAt: new Date(),
    });
  }
  
  return this.save();
};

// Instance method to soft delete message
messageSchema.methods.softDelete = function() {
  this.isDeleted = true;
  this.deletedAt = new Date();
  this.content = {}; // Clear content
  return this.save();
};

// Static method to find messages for conversation
messageSchema.statics.findForConversation = function(conversationId, options = {}) {
  const {
    limit = 50,
    skip = 0,
    before = null, // Message ID to load messages before
  } = options;
  
  const query = {
    conversation: conversationId,
    isDeleted: false,
  };
  
  if (before) {
    // Find messages before a specific message (for pagination)
    query.createdAt = { $lt: new Date(before) };
  }
  
  return this.find(query)
    .populate('sender', 'username displayName avatarUrl')
    .populate('replyTo', 'content.text sender')
    .populate('readBy.user', 'username')
    .populate('deliveredTo.user', 'username')
    .sort({ createdAt: -1 })
    .limit(limit)
    .skip(skip);
};

// Static method to get unread message count for user in conversation
messageSchema.statics.getUnreadCount = function(conversationId, userId, lastReadMessageId) {
  const query = {
    conversation: conversationId,
    sender: { $ne: userId },
    isDeleted: false,
  };
  
  if (lastReadMessageId) {
    query._id = { $gt: lastReadMessageId };
  }
  
  return this.countDocuments(query);
};

export default mongoose.model('Message', messageSchema);
