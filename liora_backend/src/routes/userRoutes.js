import express from 'express';
import { query, body, validationResult } from 'express-validator';
import { protect, optionalAuth } from '../middleware/authMiddleware.js';
import User from '../models/User.js';
import Conversation from '../models/Conversation.js';

const router = express.Router();

// Search users (public endpoint with optional auth)
router.get('/search', [
  optionalAuth,
  query('q')
    .notEmpty()
    .withMessage('Search query is required')
    .isLength({ min: 2, max: 50 })
    .withMessage('Search query must be between 2 and 50 characters'),
  query('limit')
    .optional()
    .isInt({ min: 1, max: 50 })
    .withMessage('Limit must be between 1 and 50')
    .toInt()
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

    const { q, limit = 20 } = req.query;
    const currentUserId = req.user?.userId;

    // Search users
    const users = await User.searchUsers(q, currentUserId, limit);

    // Transform users for frontend (remove sensitive info)
    const transformedUsers = users.map(user => ({
      id: user._id,
      username: user.username,
      displayName: user.displayName,
      phoneNumber: user.phoneNumber,
      avatarUrl: user.avatarUrl,
      isOnline: user.isOnline,
      lastSeen: user.lastSeen
    }));

    res.json({
      success: true,
      users: transformedUsers,
      query: q,
      total: transformedUsers.length
    });

  } catch (error) {
    console.error('Search users error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

// Get user profile by ID
router.get('/:id', [
  optionalAuth
], async (req, res) => {
  try {
    const { id } = req.params;
    const currentUserId = req.user?.userId;

    const user = await User.findById(id).select(
      'username displayName phoneNumber avatarUrl bio isOnline lastSeen settings.privacy'
    );

    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    // Apply privacy settings
    const userProfile = {
      id: user._id,
      username: user.username,
      displayName: user.displayName,
      avatarUrl: user.avatarUrl,
      bio: user.bio,
      isOnline: user.isOnline
    };

    // Check privacy settings for last seen
    const lastSeenPrivacy = user.settings?.privacy?.lastSeen || 'everyone';
    if (lastSeenPrivacy === 'everyone' || (currentUserId && id === currentUserId)) {
      userProfile.lastSeen = user.lastSeen;
    }

    // Check privacy settings for phone number
    const phonePrivacy = user.settings?.privacy?.phoneNumber || 'contacts';
    if (phonePrivacy === 'everyone' || (currentUserId && id === currentUserId)) {
      userProfile.phoneNumber = user.phoneNumber;
    }

    res.json({
      success: true,
      user: userProfile
    });

  } catch (error) {
    console.error('Get user profile error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

// All routes below require authentication
router.use(protect);

// Get current user's contacts/recent conversations
router.get('/me/contacts', async (req, res) => {
  try {
    const userId = req.user.userId;

    // Get all conversations for the user
    const conversations = await Conversation.findForUser(userId)
      .populate('members.user', 'username displayName avatarUrl isOnline lastSeen');

    // Extract unique contacts from conversations
    const contactsMap = new Map();
    
    conversations.forEach(conv => {
      conv.members.forEach(member => {
        const user = member.user;
        if (user._id.toString() !== userId && !contactsMap.has(user._id.toString())) {
          contactsMap.set(user._id.toString(), {
            id: user._id,
            username: user.username,
            displayName: user.displayName,
            avatarUrl: user.avatarUrl,
            isOnline: user.isOnline,
            lastSeen: user.lastSeen,
            conversationType: conv.type,
            lastActivity: conv.lastActivity
          });
        }
      });
    });

    const contacts = Array.from(contactsMap.values())
      .sort((a, b) => new Date(b.lastActivity) - new Date(a.lastActivity));

    res.json({
      success: true,
      contacts,
      total: contacts.length
    });

  } catch (error) {
    console.error('Get contacts error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

// Update current user's profile
router.patch('/me', [
  body('displayName')
    .optional()
    .isLength({ min: 1, max: 50 })
    .withMessage('Display name must be between 1 and 50 characters'),
  body('username')
    .optional()
    .isLength({ min: 3, max: 30 })
    .matches(/^[a-zA-Z0-9_]+$/)
    .withMessage('Username must be 3-30 characters and contain only letters, numbers, and underscores'),
  body('bio')
    .optional()
    .isLength({ max: 160 })
    .withMessage('Bio cannot exceed 160 characters'),
  body('avatarUrl')
    .optional()
    .isURL()
    .withMessage('Avatar URL must be valid')
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

    const userId = req.user.userId;
    const { displayName, username, bio, avatarUrl } = req.body;

    // Check if username is already taken
    if (username) {
      const existingUser = await User.findOne({
        username: username.toLowerCase(),
        _id: { $ne: userId }
      });

      if (existingUser) {
        return res.status(400).json({
          success: false,
          error: 'Username already taken'
        });
      }
    }

    // Update user
    const updateData = {};
    if (displayName !== undefined) updateData.displayName = displayName;
    if (username !== undefined) updateData.username = username.toLowerCase();
    if (bio !== undefined) updateData.bio = bio;
    if (avatarUrl !== undefined) updateData.avatarUrl = avatarUrl;

    const user = await User.findByIdAndUpdate(
      userId,
      updateData,
      { new: true }
    ).select('-password -refreshToken -deviceTokens');

    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    res.json({
      success: true,
      message: 'Profile updated successfully',
      user: user.getPublicProfile()
    });

  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

// Update user settings
router.patch('/me/settings', [
  body('notifications')
    .optional()
    .isObject()
    .withMessage('Notifications must be an object'),
  body('privacy')
    .optional()
    .isObject()
    .withMessage('Privacy must be an object'),
  body('theme')
    .optional()
    .isIn(['light', 'dark', 'system'])
    .withMessage('Theme must be light, dark, or system')
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

    const userId = req.user.userId;
    const { notifications, privacy, theme } = req.body;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    // Update settings
    if (notifications) {
      user.settings.notifications = { ...user.settings.notifications, ...notifications };
    }
    if (privacy) {
      user.settings.privacy = { ...user.settings.privacy, ...privacy };
    }
    if (theme) {
      user.settings.theme = theme;
    }

    await user.save();

    res.json({
      success: true,
      message: 'Settings updated successfully',
      settings: user.settings
    });

  } catch (error) {
    console.error('Update settings error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

// Block/unblock user
router.post('/me/block/:userId', async (req, res) => {
  try {
    const currentUserId = req.user.userId;
    const { userId } = req.params;

    if (currentUserId === userId) {
      return res.status(400).json({
        success: false,
        error: 'Cannot block yourself'
      });
    }

    // Check if user exists
    const userToBlock = await User.findById(userId);
    if (!userToBlock) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    const currentUser = await User.findById(currentUserId);
    const isBlocked = currentUser.blockedUsers.includes(userId);

    if (isBlocked) {
      // Unblock user
      currentUser.blockedUsers = currentUser.blockedUsers.filter(
        id => id.toString() !== userId
      );
      await currentUser.save();

      res.json({
        success: true,
        message: 'User unblocked successfully',
        action: 'unblock'
      });
    } else {
      // Block user
      currentUser.blockedUsers.push(userId);
      await currentUser.save();

      res.json({
        success: true,
        message: 'User blocked successfully',
        action: 'block'
      });
    }

  } catch (error) {
    console.error('Block/unblock user error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

// Get blocked users
router.get('/me/blocked', async (req, res) => {
  try {
    const userId = req.user.userId;

    const user = await User.findById(userId)
      .populate('blockedUsers', 'username displayName avatarUrl');

    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    const blockedUsers = user.blockedUsers.map(blockedUser => ({
      id: blockedUser._id,
      username: blockedUser.username,
      displayName: blockedUser.displayName,
      avatarUrl: blockedUser.avatarUrl
    }));

    res.json({
      success: true,
      blockedUsers,
      total: blockedUsers.length
    });

  } catch (error) {
    console.error('Get blocked users error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

// Update online status manually (optional - usually handled by socket connection)
router.patch('/me/presence', [
  body('isOnline')
    .isBoolean()
    .withMessage('isOnline must be a boolean')
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

    const userId = req.user.userId;
    const { isOnline } = req.body;

    const updateData = { isOnline };
    if (!isOnline) {
      updateData.lastSeen = new Date();
    }

    const user = await User.findByIdAndUpdate(
      userId,
      updateData,
      { new: true }
    ).select('isOnline lastSeen');

    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    res.json({
      success: true,
      message: 'Presence updated successfully',
      presence: {
        isOnline: user.isOnline,
        lastSeen: user.lastSeen
      }
    });

  } catch (error) {
    console.error('Update presence error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

// Add/update device token for push notifications
router.post('/me/device-token', [
  body('token')
    .notEmpty()
    .withMessage('Device token is required'),
  body('platform')
    .isIn(['ios', 'android', 'web'])
    .withMessage('Platform must be ios, android, or web')
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

    const userId = req.user.userId;
    const { token, platform } = req.body;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    // Remove existing token for this platform
    user.deviceTokens = user.deviceTokens.filter(dt => dt.platform !== platform);

    // Add new token
    user.deviceTokens.push({
      token,
      platform,
      createdAt: new Date()
    });

    await user.save();

    res.json({
      success: true,
      message: 'Device token updated successfully'
    });

  } catch (error) {
    console.error('Update device token error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

// Remove device token
router.delete('/me/device-token/:platform', async (req, res) => {
  try {
    const userId = req.user.userId;
    const { platform } = req.params;

    if (!['ios', 'android', 'web'].includes(platform)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid platform'
      });
    }

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    user.deviceTokens = user.deviceTokens.filter(dt => dt.platform !== platform);
    await user.save();

    res.json({
      success: true,
      message: 'Device token removed successfully'
    });

  } catch (error) {
    console.error('Remove device token error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

export default router;
