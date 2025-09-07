import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';

const userSchema = new mongoose.Schema({
  // Phone number authentication (primary)
  phoneNumber: {
    type: String,
    unique: true,
    sparse: true, // Allow null values but ensure uniqueness when present
    trim: true,
    match: [/^\+[1-9]\d{1,14}$/, 'Please enter a valid phone number with country code'],
  },
  isPhoneVerified: {
    type: Boolean,
    default: false,
  },
  phoneVerificationCode: String,
  phoneVerificationExpires: Date,
  
  // Email (optional for class project)
  email: {
    type: String,
    required: false, // Made optional
    unique: true,
    sparse: true, // Allow null values but ensure uniqueness when present
    lowercase: true,
    trim: true,
    match: [/^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/, 'Please enter a valid email'],
  },
  username: {
    type: String,
    required: false, // Made optional - will be generated from phone
    unique: true,
    sparse: true, // Allow null values but ensure uniqueness when present
    lowercase: true,
    trim: true,
    minlength: [3, 'Username must be at least 3 characters'],
    maxlength: [30, 'Username cannot exceed 30 characters'],
    match: [/^[a-zA-Z0-9_]+$/, 'Username can only contain letters, numbers, and underscores'],
  },
  displayName: {
    type: String,
    trim: true,
    maxlength: [50, 'Display name cannot exceed 50 characters'],
  },
  // Password not needed for phone auth
  password: {
    type: String,
    required: false, // Not required for phone authentication
    minlength: [6, 'Password must be at least 6 characters'],
    select: false, // Don't include password in queries by default
  },
  avatarUrl: {
    type: String,
    default: null,
  },
  bio: {
    type: String,
    maxlength: [160, 'Bio cannot exceed 160 characters'],
    default: '',
  },
  isOnline: {
    type: Boolean,
    default: false,
  },
  lastSeen: {
    type: Date,
    default: Date.now,
  },
  isEmailVerified: {
    type: Boolean,
    default: false,
  },
  emailVerificationToken: String,
  passwordResetToken: String,
  passwordResetExpires: Date,
  refreshToken: String,
  deviceTokens: [{
    token: String,
    platform: {
      type: String,
      enum: ['ios', 'android', 'web'],
    },
    createdAt: {
      type: Date,
      default: Date.now,
    },
  }],
  blockedUsers: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
  }],
  settings: {
    notifications: {
      messages: {
        type: Boolean,
        default: true,
      },
      mentions: {
        type: Boolean,
        default: true,
      },
      sounds: {
        type: Boolean,
        default: true,
      },
    },
    privacy: {
      lastSeen: {
        type: String,
        enum: ['everyone', 'contacts', 'nobody'],
        default: 'everyone',
      },
      profilePhoto: {
        type: String,
        enum: ['everyone', 'contacts', 'nobody'],
        default: 'everyone',
      },
    },
    theme: {
      type: String,
      enum: ['light', 'dark', 'system'],
      default: 'system',
    },
  },
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true },
});

// Indexes for better query performance
userSchema.index({ phoneNumber: 1 });
userSchema.index({ email: 1 });
userSchema.index({ username: 1 });
userSchema.index({ isOnline: 1, lastSeen: -1 });

// Virtual for user's full name
userSchema.virtual('fullName').get(function() {
  return this.displayName || this.username;
});

// Hash password before saving (only if password exists)
userSchema.pre('save', async function(next) {
  if (!this.isModified('password') || !this.password) return next();
  
  try {
    const salt = await bcrypt.genSalt(12);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (error) {
    next(error);
  }
});

// Update lastSeen when user comes online
userSchema.pre('save', function(next) {
  if (this.isModified('isOnline') && this.isOnline) {
    this.lastSeen = new Date();
  }
  next();
});

// Instance method to check password
userSchema.methods.comparePassword = async function(candidatePassword) {
  try {
    return await bcrypt.compare(candidatePassword, this.password);
  } catch (error) {
    throw error;
  }
};

// Instance method to get public profile
userSchema.methods.getPublicProfile = function() {
  const user = this.toObject();
  delete user.password;
  delete user.emailVerificationToken;
  delete user.passwordResetToken;
  delete user.passwordResetExpires;
  delete user.refreshToken;
  delete user.deviceTokens;
  return user;
};

// Static method to find users for search
userSchema.statics.searchUsers = function(query, currentUserId, limit = 20) {
  const searchRegex = new RegExp(query, 'i');
  return this.find({
    _id: { $ne: currentUserId },
    $or: [
      { username: searchRegex },
      { displayName: searchRegex },
      { phoneNumber: searchRegex },
      { email: searchRegex },
    ],
  })
  .select('username displayName phoneNumber avatarUrl isOnline lastSeen')
  .limit(limit);
};

export default mongoose.model('User', userSchema);
