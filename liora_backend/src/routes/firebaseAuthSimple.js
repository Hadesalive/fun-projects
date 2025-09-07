import express from 'express';
import { body, validationResult } from 'express-validator';
import User from '../models/User.js';
import jwt from 'jsonwebtoken';
import firebaseAdminService from '../services/firebaseAdminService.js';

const router = express.Router();

// Initialize Firebase Admin
firebaseAdminService.initialize();

// Generate JWT token
const generateToken = (userId) => {
  return jwt.sign({ userId }, process.env.JWT_SECRET, { expiresIn: '7d' });
};

// Authenticate with Firebase ID token
router.post('/login', [
  body('firebaseToken')
    .notEmpty()
    .withMessage('Firebase ID token is required')
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

    const { firebaseToken, displayName } = req.body;

    // Verify Firebase ID token
    const verificationResult = await firebaseAdminService.verifyIdToken(firebaseToken);
    
    if (!verificationResult.success) {
      return res.status(401).json({
        success: false,
        error: verificationResult.error,
        code: verificationResult.code
      });
    }

    const { uid, phoneNumber, email, name, picture } = verificationResult;

    if (!phoneNumber) {
      return res.status(400).json({
        success: false,
        error: 'Phone number not found in Firebase token'
      });
    }

    // Find or create user
    let user = await User.findOne({ phoneNumber });
    
    if (!user) {
      // Create new user
      user = new User({
        phoneNumber,
        isPhoneVerified: true,
        username: `user_${Date.now()}`,
        displayName: displayName || name || '',
        avatarUrl: picture || null,
        isOnline: true
      });
      
      await user.save();
      console.log(`🔥 New Firebase user created: ${phoneNumber}`);
    } else {
      // Update existing user
      user.isPhoneVerified = true;
      user.isOnline = true;
      user.lastSeen = new Date();
      if (displayName) user.displayName = displayName;
      if (name && !user.displayName) user.displayName = name;
      if (picture && !user.avatarUrl) user.avatarUrl = picture;
      await user.save();
      console.log(`🔥 Firebase user updated: ${phoneNumber}`);
    }

    // Generate JWT token for backend API access
    const backendToken = generateToken(user._id);

    res.json({
      success: true,
      message: 'Firebase authentication successful',
      token: backendToken,
      user: {
        id: user._id,
        phoneNumber: user.phoneNumber,
        username: user.username,
        displayName: user.displayName,
        avatarUrl: user.avatarUrl,
        bio: user.bio,
        isPhoneVerified: user.isPhoneVerified,
        isOnline: user.isOnline,
        lastSeen: user.lastSeen,
        settings: user.settings
      }
    });

  } catch (error) {
    console.error('Firebase auth error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

// Fallback route for development (accepts any token for testing)
router.post('/dev-login', [
  body('phoneNumber')
    .isMobilePhone()
    .withMessage('Valid phone number is required')
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

    const { phoneNumber, displayName } = req.body;

    console.log('🧪 Development login (Firebase verification skipped)');

    // Find or create user (development mode)
    let user = await User.findOne({ phoneNumber });
    
    if (!user) {
      user = new User({
        phoneNumber,
        isPhoneVerified: true,
        username: `user_${Date.now()}`,
        displayName: displayName || '',
        isOnline: true
      });
      await user.save();
    } else {
      user.isPhoneVerified = true;
      user.isOnline = true;
      user.lastSeen = new Date();
      if (displayName) user.displayName = displayName;
      await user.save();
    }

    const token = generateToken(user._id);

    res.json({
      success: true,
      message: 'Development authentication successful',
      token,
      user: {
        id: user._id,
        phoneNumber: user.phoneNumber,
        username: user.username,
        displayName: user.displayName,
        avatarUrl: user.avatarUrl,
        bio: user.bio,
        isPhoneVerified: user.isPhoneVerified,
        isOnline: user.isOnline,
        lastSeen: user.lastSeen,
        settings: user.settings
      }
    });

  } catch (error) {
    console.error('Dev auth error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

export default router;
