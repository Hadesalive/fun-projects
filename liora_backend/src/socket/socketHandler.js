import jwt from 'jsonwebtoken';
import User from '../models/User.js';
import Conversation from '../models/Conversation.js';
import Message from '../models/Message.js';

export const setupSocketIO = (io) => {
  // Authentication middleware for Socket.IO
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth.token;
      
      if (!token) {
        return next(new Error('Authentication error: No token provided'));
      }
      
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      const user = await User.findById(decoded.userId);
      
      if (!user) {
        return next(new Error('Authentication error: User not found'));
      }
      
      socket.userId = user._id.toString();
      socket.user = user;
      next();
    } catch (error) {
      next(new Error('Authentication error: Invalid token'));
    }
  });

  io.on('connection', async (socket) => {
    console.log(`🔌 User ${socket.user.username} connected: ${socket.id}`);
    
    try {
      // Update user online status
      await User.findByIdAndUpdate(socket.userId, {
        isOnline: true,
        lastSeen: new Date()
      });
      
      // Join user's personal room for direct notifications
      socket.join(`user:${socket.userId}`);
      
      // Join all conversation rooms for this user
      const conversations = await Conversation.findForUser(socket.userId);
      conversations.forEach(conv => {
        socket.join(`conv:${conv._id}`);
      });
      
    } catch (error) {
      console.error('Socket connection setup error:', error);
    }

    // Join conversation room
    socket.on('join_conversation', async (data) => {
      try {
        const { conversationId } = data;
        
        // Verify user is member of conversation
        const conversation = await Conversation.findOne({
          _id: conversationId,
          'members.user': socket.userId
        });
        
        if (!conversation) {
          socket.emit('error_generic', {
            code: 'FORBIDDEN',
            message: 'Not a member of this conversation'
          });
          return;
        }
        
        socket.join(`conv:${conversationId}`);
        console.log(`📱 User ${socket.user.username} joined conversation: ${conversationId}`);
        
      } catch (error) {
        console.error('Join conversation error:', error);
        socket.emit('error_generic', {
          code: 'SERVER_ERROR',
          message: 'Failed to join conversation'
        });
      }
    });

    // Leave conversation room
    socket.on('leave_conversation', (data) => {
      const { conversationId } = data;
      socket.leave(`conv:${conversationId}`);
      console.log(`📱 User ${socket.user.username} left conversation: ${conversationId}`);
    });

    // Send message
    socket.on('message_send', async (data) => {
      try {
        const { conversationId, type, content, clientId, replyTo } = data;
        
        // Verify user is member of conversation
        const conversation = await Conversation.findOne({
          _id: conversationId,
          'members.user': socket.userId
        });
        
        if (!conversation) {
          socket.emit('error_generic', {
            code: 'FORBIDDEN',
            message: 'Not a member of this conversation'
          });
          return;
        }
        
        // Create message
        const message = new Message({
          conversation: conversationId,
          sender: socket.userId,
          type: type || 'text',
          content,
          replyTo: replyTo || undefined
        });
        
        await message.save();
        
        // Populate sender info
        await message.populate('sender', 'username displayName avatarUrl');
        if (replyTo) {
          await message.populate('replyTo', 'content.text sender');
        }
        
        // Update conversation
        conversation.lastMessage = message._id;
        conversation.lastActivity = new Date();
        await conversation.incrementUnreadCount(socket.userId);
        

        // Mark as delivered to all members except sender
        for (const member of conversation.members) {
          if (member.user.toString() !== socket.userId) {
            await message.markAsDelivered(member.user);
          }
        }
        
        // Emit to all members in conversation room with delivery status
        io.to(`conv:${conversationId}`).emit('message_new', {
          ...message.toObject(),
          clientId, // Include clientId for sender to match with their pending message
          status: 'delivered' // Add delivery status
        });
        
        console.log(`💬 Message sent by ${socket.user.username} in conversation ${conversationId}`);
        
      } catch (error) {
        console.error('Send message error:', error);
        socket.emit('error_generic', {
          code: 'SERVER_ERROR',
          message: 'Failed to send message'
        });
      }
    });

    // Edit message
    socket.on('message_edit', async (data) => {
      try {
        const { messageId, content } = data;
        
        const message = await Message.findOne({
          _id: messageId,
          sender: socket.userId
        });
        
        if (!message) {
          socket.emit('error_generic', {
            code: 'FORBIDDEN',
            message: 'Cannot edit this message'
          });
          return;
        }
        
        message.content = content;
        message.editedAt = new Date();
        await message.save();
        
        // Emit to conversation room
        io.to(`conv:${message.conversation}`).emit('message_edited', {
          messageId: message._id,
          content: message.content,
          editedAt: message.editedAt
        });
        
      } catch (error) {
        console.error('Edit message error:', error);
        socket.emit('error_generic', {
          code: 'SERVER_ERROR',
          message: 'Failed to edit message'
        });
      }
    });

    // Delete message
    socket.on('message_delete', async (data) => {
      try {
        const { messageId } = data;
        
        const message = await Message.findOne({
          _id: messageId,
          sender: socket.userId
        });
        
        if (!message) {
          socket.emit('error_generic', {
            code: 'FORBIDDEN',
            message: 'Cannot delete this message'
          });
          return;
        }
        
        await message.softDelete();
        
        // Emit to conversation room
        io.to(`conv:${message.conversation}`).emit('message_deleted', {
          messageId: message._id
        });
        
      } catch (error) {
        console.error('Delete message error:', error);
        socket.emit('error_generic', {
          code: 'SERVER_ERROR',
          message: 'Failed to delete message'
        });
      }
    });

    // Mark message as read
    socket.on('message_read', async (data) => {
      try {
        const { conversationId, messageId } = data;
        
        // Verify user is member of conversation
        const conversation = await Conversation.findOne({
          _id: conversationId,
          'members.user': socket.userId
        });
        
        if (!conversation) {
          socket.emit('error_generic', {
            code: 'FORBIDDEN',
            message: 'Not a member of this conversation'
          });
          return;
        }
        
        // Mark message as read
        await Message.findByIdAndUpdate(messageId, {
          $addToSet: {
            readBy: {
              user: socket.userId,
              readAt: new Date()
            }
          }
        });
        
        // Update conversation member's read status and decrement unread count
        await conversation.markAsRead(socket.userId, messageId);
        
        // Get updated conversation with unread counts (re-fetch to ensure we have latest data)
        const updatedConversation = await Conversation.findById(conversationId)
          .populate('members.user', 'username displayName avatarUrl');
        
        // Debug: Log unread counts
        console.log('📊 Updated unread counts for conversation:', conversationId);
        updatedConversation.members.forEach(member => {
          console.log(`  - User ${member.user.username}: ${member.unreadCount} unread`);
        });
        
        // Emit to conversation room with updated unread counts
        io.to(`conv:${conversationId}`).emit('message_read', {
          userId: socket.userId,
          messageId,
          readAt: new Date(),
          conversationId,
          unreadCounts: updatedConversation.members.map(member => ({
            userId: member.user._id.toString(),
            unreadCount: member.unreadCount
          }))
        });
        
        console.log(`👁️ Message marked as read by ${socket.user.username} in conversation ${conversationId}`);
        
      } catch (error) {
        console.error('Mark read error:', error);
        socket.emit('error_generic', {
          code: 'SERVER_ERROR',
          message: 'Failed to mark message as read'
        });
      }
    });

    // Add reaction to message
    socket.on('message_react', async (data) => {
      try {
        const { messageId, emoji } = data;
        
        const message = await Message.findById(messageId);
        if (!message) {
          socket.emit('error_generic', {
            code: 'NOT_FOUND',
            message: 'Message not found'
          });
          return;
        }
        
        // Check if user already reacted with this emoji
        const reaction = message.reactions.find(r => r.emoji === emoji);
        const hasReacted = reaction && reaction.users.includes(socket.userId);
        
        if (hasReacted) {
          // Remove reaction
          await message.removeReaction(emoji, socket.userId);
        } else {
          // Add reaction
          await message.addReaction(emoji, socket.userId);
        }
        
        await message.populate('reactions.users', 'username displayName');
        
        // Emit to conversation room
        io.to(`conv:${message.conversation}`).emit('message_reaction', {
          messageId: message._id,
          reactions: message.reactions,
          userId: socket.userId,
          emoji,
          action: hasReacted ? 'remove' : 'add'
        });
        
      } catch (error) {
        console.error('Message reaction error:', error);
        socket.emit('error_generic', {
          code: 'SERVER_ERROR',
          message: 'Failed to update reaction'
        });
      }
    });

    // Typing indicator
    socket.on('typing', (data) => {
      const { conversationId, isTyping } = data;
      
      // Emit to conversation room (excluding sender)
      socket.to(`conv:${conversationId}`).emit('typing', {
        userId: socket.userId,
        username: socket.user.username,
        displayName: socket.user.displayName,
        isTyping
      });
    });

    // Handle disconnection
    socket.on('disconnect', async () => {
      console.log(`🔌 User ${socket.user.username} disconnected: ${socket.id}`);
      
      try {
        // Update user offline status
        await User.findByIdAndUpdate(socket.userId, {
          isOnline: false,
          lastSeen: new Date()
        });
        
        // Emit user offline status to relevant conversations
        const conversations = await Conversation.findForUser(socket.userId);
        conversations.forEach(conv => {
          socket.to(`conv:${conv._id}`).emit('user_offline', {
            userId: socket.userId,
            lastSeen: new Date()
          });
        });
        
      } catch (error) {
        console.error('Socket disconnect cleanup error:', error);
      }
    });
  });
  
  console.log('🚀 Socket.IO handlers setup complete');
};
