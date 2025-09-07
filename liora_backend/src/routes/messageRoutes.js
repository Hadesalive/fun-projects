import express from 'express';
import { body, query, param, validationResult } from 'express-validator';
import { protect } from '../middleware/authMiddleware.js';
import Message from '../models/Message.js';
import Conversation from '../models/Conversation.js';

// We need to access the Socket.IO instance
// This will be set by the server when it starts
let io = null;
export const setSocketIO = (socketIO) => {
  io = socketIO;
};

const router = express.Router();

// All routes require authentication
router.use(protect);

// Get messages for a conversation
router.get('/:conversationId', [
  param('conversationId')
    .isMongoId()
    .withMessage('Invalid conversation ID'),
  query('limit')
    .optional()
    .isInt({ min: 1, max: 100 })
    .withMessage('Limit must be between 1 and 100')
    .toInt(),
  query('skip')
    .optional()
    .isInt({ min: 0 })
    .withMessage('Skip must be a non-negative integer')
    .toInt(),
  query('before')
    .optional()
    .isISO8601()
    .withMessage('Before must be a valid ISO date'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { conversationId } = req.params;
    const { limit = 50, skip = 0, before } = req.query;
    const userId = req.user.userId;

    // Check if user is member of the conversation
    const conversation = await Conversation.findOne({
      _id: conversationId,
      'members.user': userId
    });

    if (!conversation) {
      return res.status(404).json({
        success: false,
        error: 'Conversation not found or access denied'
      });
    }

    // Get messages
    const messages = await Message.findForConversation(conversationId, {
      limit,
      skip,
      before
    });

    // Transform messages for frontend
    const transformedMessages = messages.map(message => {
      const messageObj = message.toObject();
      
      // Add status for current user
      const isRead = message.readBy.some(read => 
        read.user._id.toString() === userId
      );
      const isDelivered = message.deliveredTo.some(delivery => 
        delivery.user._id.toString() === userId
      );
      
      messageObj.status = isRead ? 'read' : (isDelivered ? 'delivered' : 'sent');
      messageObj.isMe = message.sender._id.toString() === userId;
      
      // Add reaction info for current user
      messageObj.reactions = message.reactions.map(reaction => ({
        emoji: reaction.emoji,
        count: reaction.count,
        hasReacted: reaction.users.some(user => user.toString() === userId)
      }));
      
      return messageObj;
    });

    res.json({
      success: true,
      messages: transformedMessages.reverse(), // Reverse to get chronological order
      pagination: {
        limit,
        skip,
        hasMore: messages.length === limit
      }
    });

  } catch (error) {
    console.error('Get messages error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

// Send a new message
router.post('/:conversationId', [
  param('conversationId')
    .isMongoId()
    .withMessage('Invalid conversation ID'),
  body('type')
    .isIn(['text', 'image', 'video', 'audio', 'file'])
    .withMessage('Invalid message type'),
  body('content')
    .notEmpty()
    .withMessage('Message content is required'),
  body('replyTo')
    .optional()
    .isMongoId()
    .withMessage('Reply to must be a valid message ID'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { conversationId } = req.params;
    const { type, content, replyTo } = req.body;
    const userId = req.user.userId;

    // Check if user is member of the conversation
    const conversation = await Conversation.findOne({
      _id: conversationId,
      'members.user': userId
    });

    if (!conversation) {
      return res.status(404).json({
        success: false,
        error: 'Conversation not found or access denied'
      });
    }

    // Create message data based on type
    let messageData = {
      conversation: conversationId,
      sender: userId,
      type,
      replyTo
    };

    if (type === 'text') {
      messageData.content = { text: content };
    } else {
      // For media messages, content should contain media info
      messageData.content = { media: content };
    }

    // Create and save message
    const message = new Message(messageData);
    await message.save();

    // Populate sender info
    await message.populate('sender', 'username displayName avatarUrl');
    
    // Mark as delivered to all other members
    const otherMembers = conversation.members.filter(
      member => member.user.toString() !== userId
    );
    
    for (const member of otherMembers) {
      await message.markAsDelivered(member.user);
    }

    // Update conversation's last message and activity
    conversation.lastMessage = message._id;
    conversation.lastActivity = new Date();
    await conversation.save();

    // Increment unread count for other members
    await conversation.incrementUnreadCount(userId);

    // Transform message for response
    const messageObj = message.toObject();
    messageObj.status = 'sent';
    messageObj.isMe = true;
    messageObj.reactions = [];

    // Emit Socket.IO event for real-time updates
    if (io) {
      // Emit to all members in conversation room
      io.to(`conv:${conversationId}`).emit('message_new', {
        ...messageObj,
        status: 'delivered' // Mark as delivered for other users
      });
      
      console.log(`💬 Message sent via API and emitted via Socket.IO in conversation ${conversationId}`);
    } else {
      console.log('⚠️ Socket.IO not available for message emission');
    }

    res.status(201).json({
      success: true,
      message: 'Message sent successfully',
      data: messageObj
    });

  } catch (error) {
    console.error('Send message error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

// Mark messages as read
router.patch('/:conversationId/read', [
  param('conversationId')
    .isMongoId()
    .withMessage('Invalid conversation ID'),
  body('messageId')
    .isMongoId()
    .withMessage('Invalid message ID'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { conversationId } = req.params;
    const { messageId } = req.body;
    const userId = req.user.userId;

    // Check if user is member of the conversation
    const conversation = await Conversation.findOne({
      _id: conversationId,
      'members.user': userId
    });

    if (!conversation) {
      return res.status(404).json({
        success: false,
        error: 'Conversation not found or access denied'
      });
    }

    // Mark message as read
    const message = await Message.findById(messageId);
    if (!message) {
      return res.status(404).json({
        success: false,
        error: 'Message not found'
      });
    }

    await message.markAsRead(userId);

    // Update conversation's read status
    await conversation.markAsRead(userId, messageId);

    res.json({
      success: true,
      message: 'Message marked as read'
    });

  } catch (error) {
    console.error('Mark as read error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

// Add reaction to message
router.post('/:conversationId/messages/:messageId/reactions', [
  param('conversationId')
    .isMongoId()
    .withMessage('Invalid conversation ID'),
  param('messageId')
    .isMongoId()
    .withMessage('Invalid message ID'),
  body('emoji')
    .notEmpty()
    .withMessage('Emoji is required'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { conversationId, messageId } = req.params;
    const { emoji } = req.body;
    const userId = req.user.userId;

    // Check if user is member of the conversation
    const conversation = await Conversation.findOne({
      _id: conversationId,
      'members.user': userId
    });

    if (!conversation) {
      return res.status(404).json({
        success: false,
        error: 'Conversation not found or access denied'
      });
    }

    // Add reaction to message
    const message = await Message.findById(messageId);
    if (!message) {
      return res.status(404).json({
        success: false,
        error: 'Message not found'
      });
    }

    await message.addReaction(emoji, userId);

    res.json({
      success: true,
      message: 'Reaction added successfully'
    });

  } catch (error) {
    console.error('Add reaction error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

// Remove reaction from message
router.delete('/:conversationId/messages/:messageId/reactions', [
  param('conversationId')
    .isMongoId()
    .withMessage('Invalid conversation ID'),
  param('messageId')
    .isMongoId()
    .withMessage('Invalid message ID'),
  body('emoji')
    .notEmpty()
    .withMessage('Emoji is required'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { conversationId, messageId } = req.params;
    const { emoji } = req.body;
    const userId = req.user.userId;

    // Check if user is member of the conversation
    const conversation = await Conversation.findOne({
      _id: conversationId,
      'members.user': userId
    });

    if (!conversation) {
      return res.status(404).json({
        success: false,
        error: 'Conversation not found or access denied'
      });
    }

    // Remove reaction from message
    const message = await Message.findById(messageId);
    if (!message) {
      return res.status(404).json({
        success: false,
        error: 'Message not found'
      });
    }

    await message.removeReaction(emoji, userId);

    res.json({
      success: true,
      message: 'Reaction removed successfully'
    });

  } catch (error) {
    console.error('Remove reaction error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

// Delete message
router.delete('/:conversationId/messages/:messageId', [
  param('conversationId')
    .isMongoId()
    .withMessage('Invalid conversation ID'),
  param('messageId')
    .isMongoId()
    .withMessage('Invalid message ID'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { conversationId, messageId } = req.params;
    const userId = req.user.userId;

    // Check if user is member of the conversation
    const conversation = await Conversation.findOne({
      _id: conversationId,
      'members.user': userId
    });

    if (!conversation) {
      return res.status(404).json({
        success: false,
        error: 'Conversation not found or access denied'
      });
    }

    // Find message and check if user can delete it
    const message = await Message.findById(messageId);
    if (!message) {
      return res.status(404).json({
        success: false,
        error: 'Message not found'
      });
    }

    // Only sender can delete their message
    if (message.sender.toString() !== userId) {
      return res.status(403).json({
        success: false,
        error: 'You can only delete your own messages'
      });
    }

    // Soft delete the message
    await message.softDelete();

    res.json({
      success: true,
      message: 'Message deleted successfully'
    });

  } catch (error) {
    console.error('Delete message error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

export default router;