import express from 'express';
import { body, validationResult } from 'express-validator';
import admin from 'firebase-admin';
import User from '../models/User.js';
import jwt from 'jsonwebtoken';

const router = express.Router();

// Initialize Firebase Admin (you'll need to add your service account key)
// admin.initializeApp({
//   credential: admin.credential.cert(serviceAccount),
// });

// Generate JWT token
const generateToken = (userId) => {
  return jwt.sign({ userId }, process.env.JWT_SECRET, { expiresIn: '7d' });
};

// Verify Firebase ID token and create/login user
router.post('/firebase-verify', [
  body('firebaseToken')
    .notEmpty()
    .withMessage('Firebase ID token is required'),
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

    const { firebaseToken, phoneNumber } = req.body;

    // Verify Firebase ID token
    let decodedToken;
    try {
      decodedToken = await admin.auth().verifyIdToken(firebaseToken);
    } catch (error) {
      console.error('Firebase token verification failed:', error);
      return res.status(401).json({
        success: false,
        error: 'Invalid Firebase token'
      });
    }

    // Ensure phone number matches
    if (decodedToken.phone_number !== phoneNumber) {
      return res.status(400).json({
        success: false,
        error: 'Phone number mismatch'
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
        displayName: '',
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
      message: 'Firebase authentication successful',
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
    console.error('Firebase auth error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

export default router;
