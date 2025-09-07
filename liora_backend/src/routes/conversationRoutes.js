import express from 'express';
import { body, query, param, validationResult } from 'express-validator';
import { protect } from '../middleware/authMiddleware.js';
import Conversation from '../models/Conversation.js';
import User from '../models/User.js';

const router = express.Router();

// All routes require authentication
router.use(protect);

// Get conversations for current user
router.get('/', [
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
  query('includeArchived')
    .optional()
    .isBoolean()
    .withMessage('includeArchived must be a boolean')
    .toBoolean()
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

    const { limit = 20, skip = 0, includeArchived = false } = req.query;
    const userId = req.user.userId;

    const conversations = await Conversation.findForUser(userId, {
      limit,
      skip,
      includeArchived
    });

    // Transform conversations for frontend
    const transformedConversations = conversations.map(conv => {
      const convObj = conv.toObject();
      
      // For direct conversations, get the other user's info
      if (conv.type === 'direct') {
        const otherMember = conv.members.find(
          member => member.user._id.toString() !== userId
        );
        
        if (otherMember) {
          convObj.name = otherMember.user.displayName || otherMember.user.username;
          convObj.avatarUrl = otherMember.user.avatarUrl;
        }
      }
      
      // Get current user's member info for unread count
      const currentUserMember = conv.members.find(
        member => member.user._id.toString() === userId
      );
      
      if (currentUserMember) {
        convObj.unreadCount = currentUserMember.unreadCount;
        convObj.isPinned = currentUserMember.isPinned;
        convObj.isMuted = currentUserMember.isMuted;
      }
      
      return convObj;
    });

    res.json({
      success: true,
      conversations: transformedConversations,
      pagination: {
        limit,
        skip,
        total: conversations.length
      }
    });

  } catch (error) {
    console.error('Get conversations error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

// Sync unread counts for a specific conversation
router.post('/:conversationId/sync-unread', [
  param('conversationId')
    .isMongoId()
    .withMessage('Invalid conversation ID'),
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

    // Get current user's member info
    const currentUserMember = conversation.members.find(
      member => member.user.toString() === userId
    );

    if (!currentUserMember) {
      return res.status(404).json({
        success: false,
        error: 'User not found in conversation'
      });
    }

    res.json({
      success: true,
      unreadCount: currentUserMember.unreadCount,
      lastReadMessageId: currentUserMember.lastReadMessageId
    });

  } catch (error) {
    console.error('Sync unread count error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

// Create new conversation
router.post('/', [
  body('type')
    .isIn(['direct', 'group', 'channel'])
    .withMessage('Type must be direct, group, or channel'),
  body('name')
    .optional()
    .isLength({ min: 1, max: 100 })
    .withMessage('Name must be between 1 and 100 characters'),
  body('description')
    .optional()
    .isLength({ max: 500 })
    .withMessage('Description cannot exceed 500 characters'),
  body('memberIds')
    .isArray({ min: 1 })
    .withMessage('Member IDs must be an array with at least one member'),
  body('memberIds.*')
    .isMongoId()
    .withMessage('Each member ID must be a valid MongoDB ObjectId')
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

    const { type, name, description, memberIds, avatarUrl } = req.body;
    const userId = req.user.userId;

    // Validate member count for direct conversations
    if (type === 'direct' && memberIds.length !== 1) {
      return res.status(400).json({
        success: false,
        error: 'Direct conversations must have exactly one other member'
      });
    }

    // Check if direct conversation already exists
    if (type === 'direct') {
      const existingConversation = await Conversation.findDirectConversation(
        userId,
        memberIds[0]
      );
      
      if (existingConversation) {
        return res.status(400).json({
          success: false,
          error: 'Direct conversation already exists',
          conversation: existingConversation
        });
      }
    }

    // Verify all members exist
    const members = await User.find({
      _id: { $in: memberIds }
    }).select('_id username displayName');

    if (members.length !== memberIds.length) {
      return res.status(400).json({
        success: false,
        error: 'One or more member IDs are invalid'
      });
    }

    // Create conversation
    const conversationData = {
      type,
      name: type === 'direct' ? undefined : name,
      description,
      avatarUrl,
      createdBy: userId,
      members: [
        // Creator
        {
          user: userId,
          role: type === 'direct' ? 'member' : 'admin',
          joinedAt: new Date()
        },
        // Other members
        ...memberIds.map(memberId => ({
          user: memberId,
          role: 'member',
          joinedAt: new Date()
        }))
      ]
    };

    const conversation = new Conversation(conversationData);
    await conversation.save();

    // Populate member details
    await conversation.populate('members.user', 'username displayName avatarUrl isOnline lastSeen');
    await conversation.populate('createdBy', 'username displayName');

    res.status(201).json({
      success: true,
      message: 'Conversation created successfully',
      conversation: conversation.toObject()
    });

  } catch (error) {
    console.error('Create conversation error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

// Get conversation details
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.userId;

    const conversation = await Conversation.findOne({
      _id: id,
      'members.user': userId
    })
    .populate('members.user', 'username displayName avatarUrl isOnline lastSeen')
    .populate('lastMessage')
    .populate('createdBy', 'username displayName');

    if (!conversation) {
      return res.status(404).json({
        success: false,
        error: 'Conversation not found or access denied'
      });
    }

    res.json({
      success: true,
      conversation: conversation.toObject()
    });

  } catch (error) {
    console.error('Get conversation error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

// Update conversation
router.patch('/:id', [
  body('name')
    .optional()
    .isLength({ min: 1, max: 100 })
    .withMessage('Name must be between 1 and 100 characters'),
  body('description')
    .optional()
    .isLength({ max: 500 })
    .withMessage('Description cannot exceed 500 characters'),
  body('avatarUrl')
    .optional()
    .isURL()
    .withMessage('Avatar URL must be a valid URL'),
  body('settings')
    .optional()
    .isObject()
    .withMessage('Settings must be an object')
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

    const { id } = req.params;
    const userId = req.user.userId;
    const { name, description, avatarUrl, settings } = req.body;

    const conversation = await Conversation.findOne({
      _id: id,
      'members.user': userId
    });

    if (!conversation) {
      return res.status(404).json({
        success: false,
        error: 'Conversation not found or access denied'
      });
    }

    // Check if user has permission to update (admin or moderator for groups)
    const userMember = conversation.members.find(
      member => member.user.toString() === userId
    );

    if (conversation.type !== 'direct' && !['admin', 'moderator'].includes(userMember.role)) {
      return res.status(403).json({
        success: false,
        error: 'Insufficient permissions to update conversation'
      });
    }

    // Update conversation
    const updateData = {};
    if (name !== undefined) updateData.name = name;
    if (description !== undefined) updateData.description = description;
    if (avatarUrl !== undefined) updateData.avatarUrl = avatarUrl;
    if (settings !== undefined) updateData.settings = { ...conversation.settings, ...settings };

    const updatedConversation = await Conversation.findByIdAndUpdate(
      id,
      updateData,
      { new: true }
    )
    .populate('members.user', 'username displayName avatarUrl isOnline lastSeen')
    .populate('createdBy', 'username displayName');

    res.json({
      success: true,
      message: 'Conversation updated successfully',
      conversation: updatedConversation.toObject()
    });

  } catch (error) {
    console.error('Update conversation error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

// Add member to conversation
router.post('/:id/members', [
  body('userId')
    .isMongoId()
    .withMessage('User ID must be a valid MongoDB ObjectId'),
  body('role')
    .optional()
    .isIn(['admin', 'moderator', 'member'])
    .withMessage('Role must be admin, moderator, or member')
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

    const { id } = req.params;
    const currentUserId = req.user.userId;
    const { userId, role = 'member' } = req.body;

    const conversation = await Conversation.findOne({
      _id: id,
      'members.user': currentUserId
    });

    if (!conversation) {
      return res.status(404).json({
        success: false,
        error: 'Conversation not found or access denied'
      });
    }

    // Can't add members to direct conversations
    if (conversation.type === 'direct') {
      return res.status(400).json({
        success: false,
        error: 'Cannot add members to direct conversations'
      });
    }

    // Check permissions
    const currentUserMember = conversation.members.find(
      member => member.user.toString() === currentUserId
    );

    if (!['admin', 'moderator'].includes(currentUserMember.role)) {
      return res.status(403).json({
        success: false,
        error: 'Insufficient permissions to add members'
      });
    }

    // Verify user exists
    const userToAdd = await User.findById(userId);
    if (!userToAdd) {
      return res.status(404).json({
        success: false,
        error: 'User to add not found'
      });
    }

    // Add member
    await conversation.addMember(userId, role);
    await conversation.populate('members.user', 'username displayName avatarUrl isOnline lastSeen');

    res.json({
      success: true,
      message: 'Member added successfully',
      conversation: conversation.toObject()
    });

  } catch (error) {
    if (error.message === 'User is already a member of this conversation') {
      return res.status(400).json({
        success: false,
        error: error.message
      });
    }

    console.error('Add member error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

// Remove member from conversation
router.delete('/:id/members/:userId', async (req, res) => {
  try {
    const { id, userId } = req.params;
    const currentUserId = req.user.userId;

    const conversation = await Conversation.findOne({
      _id: id,
      'members.user': currentUserId
    });

    if (!conversation) {
      return res.status(404).json({
        success: false,
        error: 'Conversation not found or access denied'
      });
    }

    // Can't remove members from direct conversations
    if (conversation.type === 'direct') {
      return res.status(400).json({
        success: false,
        error: 'Cannot remove members from direct conversations'
      });
    }

    // Check permissions (admin/moderator can remove others, anyone can leave)
    const currentUserMember = conversation.members.find(
      member => member.user.toString() === currentUserId
    );

    const isLeavingSelf = userId === currentUserId;
    const hasPermission = ['admin', 'moderator'].includes(currentUserMember.role);

    if (!isLeavingSelf && !hasPermission) {
      return res.status(403).json({
        success: false,
        error: 'Insufficient permissions to remove members'
      });
    }

    // Remove member
    await conversation.removeMember(userId);
    await conversation.populate('members.user', 'username displayName avatarUrl isOnline lastSeen');

    res.json({
      success: true,
      message: isLeavingSelf ? 'Left conversation successfully' : 'Member removed successfully',
      conversation: conversation.toObject()
    });

  } catch (error) {
    console.error('Remove member error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

// Update member role
router.patch('/:id/members/:userId/role', [
  body('role')
    .isIn(['admin', 'moderator', 'member'])
    .withMessage('Role must be admin, moderator, or member')
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

    const { id, userId } = req.params;
    const currentUserId = req.user.userId;
    const { role } = req.body;

    const conversation = await Conversation.findOne({
      _id: id,
      'members.user': currentUserId
    });

    if (!conversation) {
      return res.status(404).json({
        success: false,
        error: 'Conversation not found or access denied'
      });
    }

    // Only admins can change roles
    const currentUserMember = conversation.members.find(
      member => member.user.toString() === currentUserId
    );

    if (currentUserMember.role !== 'admin') {
      return res.status(403).json({
        success: false,
        error: 'Only admins can change member roles'
      });
    }

    // Update role
    await conversation.updateMemberRole(userId, role);
    await conversation.populate('members.user', 'username displayName avatarUrl isOnline lastSeen');

    res.json({
      success: true,
      message: 'Member role updated successfully',
      conversation: conversation.toObject()
    });

  } catch (error) {
    if (error.message === 'User is not a member of this conversation') {
      return res.status(404).json({
        success: false,
        error: error.message
      });
    }

    console.error('Update member role error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

export default router;
