import mongoose from 'mongoose';

const conversationSchema = new mongoose.Schema({
  type: {
    type: String,
    enum: ['direct', 'group', 'channel'],
    required: true,
    default: 'direct',
  },
  name: {
    type: String,
    trim: true,
    maxlength: [100, 'Conversation name cannot exceed 100 characters'],
    // Required for group and channel conversations
    required: function() {
      return this.type !== 'direct';
    },
  },
  description: {
    type: String,
    trim: true,
    maxlength: [500, 'Description cannot exceed 500 characters'],
  },
  avatarUrl: {
    type: String,
    default: null,
  },
  members: [{
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    joinedAt: {
      type: Date,
      default: Date.now,
    },
    role: {
      type: String,
      enum: ['admin', 'moderator', 'member'],
      default: 'member',
    },
    lastReadMessageId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Message',
    },
    unreadCount: {
      type: Number,
      default: 0,
    },
    isMuted: {
      type: Boolean,
      default: false,
    },
    isPinned: {
      type: Boolean,
      default: false,
    },
  }],
  lastMessage: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Message',
  },
  lastActivity: {
    type: Date,
    default: Date.now,
  },
  isArchived: {
    type: Boolean,
    default: false,
  },
  settings: {
    allowMemberInvites: {
      type: Boolean,
      default: true,
    },
    allowMemberMessages: {
      type: Boolean,
      default: true,
    },
    disappearingMessages: {
      enabled: {
        type: Boolean,
        default: false,
      },
      duration: {
        type: Number, // Duration in seconds
        default: 86400, // 24 hours
      },
    },
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true },
});

// Indexes for better query performance
conversationSchema.index({ members: 1 });
conversationSchema.index({ lastActivity: -1 });
conversationSchema.index({ type: 1, isArchived: 1 });

// Ensure direct conversations have exactly 2 members
conversationSchema.pre('save', function(next) {
  if (this.type === 'direct' && this.members.length !== 2) {
    return next(new Error('Direct conversations must have exactly 2 members'));
  }
  next();
});

// Update lastActivity when conversation is modified
conversationSchema.pre('save', function(next) {
  if (this.isModified() && !this.isModified('lastActivity')) {
    this.lastActivity = new Date();
  }
  next();
});

// Virtual for member count
conversationSchema.virtual('memberCount').get(function() {
  return this.members.length;
});

// Instance method to add member
conversationSchema.methods.addMember = function(userId, role = 'member') {
  const existingMember = this.members.find(member => 
    member.user.toString() === userId.toString()
  );
  
  if (existingMember) {
    throw new Error('User is already a member of this conversation');
  }
  
  this.members.push({
    user: userId,
    role,
    joinedAt: new Date(),
  });
  
  return this.save();
};

// Instance method to remove member
conversationSchema.methods.removeMember = function(userId) {
  this.members = this.members.filter(member => 
    member.user.toString() !== userId.toString()
  );
  
  return this.save();
};

// Instance method to update member role
conversationSchema.methods.updateMemberRole = function(userId, newRole) {
  const member = this.members.find(member => 
    member.user.toString() === userId.toString()
  );
  
  if (!member) {
    throw new Error('User is not a member of this conversation');
  }
  
  member.role = newRole;
  return this.save();
};

// Instance method to mark message as read for user
conversationSchema.methods.markAsRead = function(userId, messageId) {
  const member = this.members.find(member => 
    member.user.toString() === userId.toString()
  );
  
  if (member) {
    member.lastReadMessageId = messageId;
    member.unreadCount = 0;
  }
  
  return this.save();
};

// Instance method to increment unread count for members
conversationSchema.methods.incrementUnreadCount = function(excludeUserId) {
  this.members.forEach(member => {
    if (member.user.toString() !== excludeUserId.toString()) {
      member.unreadCount += 1;
    }
  });
  
  return this.save();
};

// Static method to find conversations for a user
conversationSchema.statics.findForUser = function(userId, options = {}) {
  const {
    limit = 20,
    skip = 0,
    includeArchived = false,
  } = options;
  
  const query = {
    'members.user': userId,
  };
  
  if (!includeArchived) {
    query.isArchived = false;
  }
  
  return this.find(query)
    .populate('members.user', 'username displayName avatarUrl isOnline lastSeen')
    .populate('lastMessage')
    .populate('createdBy', 'username displayName')
    .sort({ lastActivity: -1 })
    .limit(limit)
    .skip(skip);
};

// Static method to find direct conversation between two users
conversationSchema.statics.findDirectConversation = function(userId1, userId2) {
  return this.findOne({
    type: 'direct',
    'members.user': { $all: [userId1, userId2] },
  })
  .populate('members.user', 'username displayName avatarUrl isOnline lastSeen')
  .populate('lastMessage');
};

export default mongoose.model('Conversation', conversationSchema);
