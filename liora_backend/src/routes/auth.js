import express from 'express';
import { body, validationResult } from 'express-validator';
import User from '../models/User.js';
import smsService from '../services/smsService.js';
import otpService from '../services/otpService.js';
import jwt from 'jsonwebtoken';

const router = express.Router();

// Generate JWT token
const generateToken = (userId) => {
  return jwt.sign({ userId }, process.env.JWT_SECRET, { expiresIn: '7d' });
};

// Send OTP to phone number
router.post('/send-otp', [
  body('phoneNumber')
    .isMobilePhone()
    .withMessage('Please provide a valid phone number')
    .custom((value) => {
      if (!smsService.isValidPhoneNumber(value)) {
        throw new Error('Phone number must be in E.164 format (+1234567890)');
      }
      return true;
    })
], async (req, res) => {
  try {
    // Validate input
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { phoneNumber } = req.body;
    const formattedPhone = smsService.formatPhoneNumber(phoneNumber);

    // Check if user already exists
    const existingUser = await User.findOne({ phoneNumber: formattedPhone });
    
    // Generate OTP
    const otp = otpService.generateOTP();
    
    // Store OTP in Redis
    const otpStored = await otpService.storeOTP(formattedPhone, otp);
    if (!otpStored) {
      return res.status(500).json({
        success: false,
        error: 'Failed to generate OTP. Please try again.'
      });
    }

    // Send SMS
    const smsResult = await smsService.sendOTP(formattedPhone, otp);
    
    if (!smsResult.success) {
      // Clean up stored OTP if SMS failed
      await otpService.deleteOTP(formattedPhone);
      
      return res.status(500).json({
        success: false,
        error: 'Failed to send SMS. Please try again.',
        details: smsResult.error
      });
    }

    res.json({
      success: true,
      message: 'OTP sent successfully',
      phoneNumber: formattedPhone,
      isExistingUser: !!existingUser
    });

  } catch (error) {
    console.error('Send OTP error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

// Verify OTP and register/login user
router.post('/verify-otp', [
  body('phoneNumber')
    .isMobilePhone()
    .withMessage('Please provide a valid phone number'),
  body('otp')
    .isLength({ min: 6, max: 6 })
    .isNumeric()
    .withMessage('OTP must be a 6-digit number')
], async (req, res) => {
  try {
    // Validate input
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { phoneNumber, otp } = req.body;
    const formattedPhone = smsService.formatPhoneNumber(phoneNumber);

    // Verify OTP
    const otpResult = await otpService.verifyOTP(formattedPhone, otp);
    
    if (!otpResult.success) {
      return res.status(400).json({
        success: false,
        error: otpResult.error,
        code: otpResult.code,
        remainingAttempts: otpResult.remainingAttempts
      });
    }

    // Find or create user
    let user = await User.findOne({ phoneNumber: formattedPhone });
    
    if (!user) {
      // Create new user
      user = new User({
        phoneNumber: formattedPhone,
        isPhoneVerified: true,
        username: `user_${Date.now()}`, // Temporary username
        displayName: '', // Will be set in profile setup
        isOnline: true
      });
      
      await user.save();
    } else {
      // Update existing user
      user.isPhoneVerified = true;
      user.isOnline = true;
      user.lastSeen = new Date();
      await user.save();
    }

    // Generate JWT token
    const token = generateToken(user._id);

    res.json({
      success: true,
      message: 'Phone number verified successfully',
      token,
      user: {
        id: user._id,
        phoneNumber: user.phoneNumber,
        username: user.username,
        displayName: user.displayName,
        avatarUrl: user.avatarUrl,
        isPhoneVerified: user.isPhoneVerified
      }
    });

  } catch (error) {
    console.error('Verify OTP error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

// Update user profile after phone verification
router.post('/update-profile', [
  body('displayName')
    .isLength({ min: 2, max: 50 })
    .withMessage('Display name must be between 2 and 50 characters')
    .optional(),
  body('username')
    .isLength({ min: 3, max: 30 })
    .matches(/^[a-zA-Z0-9_]+$/)
    .withMessage('Username must be 3-30 characters and contain only letters, numbers, and underscores')
    .optional()
], async (req, res) => {
  try {
    const { displayName, username, avatarUrl } = req.body;
    const userId = req.user?.userId;

    if (!userId) {
      return res.status(401).json({
        success: false,
        error: 'Authentication required'
      });
    }

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
    if (displayName) updateData.displayName = displayName;
    if (username) updateData.username = username.toLowerCase();
    if (avatarUrl) updateData.avatarUrl = avatarUrl;

    const user = await User.findByIdAndUpdate(
      userId,
      updateData,
      { new: true, select: '-password -refreshToken' }
    );

    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    res.json({
      success: true,
      message: 'Profile updated successfully',
      user: {
        id: user._id,
        phoneNumber: user.phoneNumber,
        username: user.username,
        displayName: user.displayName,
        avatarUrl: user.avatarUrl,
        isPhoneVerified: user.isPhoneVerified
      }
    });

  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

// Get current user info
router.get('/me', async (req, res) => {
  try {
    const userId = req.user?.userId;

    if (!userId) {
      return res.status(401).json({
        success: false,
        error: 'Authentication required'
      });
    }

    const user = await User.findById(userId).select('-password -refreshToken');
    
    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    res.json({
      success: true,
      user: {
        id: user._id,
        phoneNumber: user.phoneNumber,
        username: user.username,
        displayName: user.displayName,
        avatarUrl: user.avatarUrl,
        isPhoneVerified: user.isPhoneVerified,
        isOnline: user.isOnline,
        lastSeen: user.lastSeen
      }
    });

  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

export default router;
