import crypto from 'crypto';
import redisClient from '../config/redis.js';

class OTPService {
  constructor() {
    this.otpExpiry = 5 * 60; // 5 minutes in seconds
    this.maxAttempts = 3; // Maximum verification attempts
  }

  /**
   * Generate a 6-digit OTP
   * @returns {string} - 6-digit OTP code
   */
  generateOTP() {
    return crypto.randomInt(100000, 999999).toString();
  }

  /**
   * Store OTP in Redis with expiry
   * @param {string} phoneNumber - Phone number
   * @param {string} otp - OTP code
   * @returns {Promise<boolean>} - Success status
   */
  async storeOTP(phoneNumber, otp) {
    try {
      const key = `otp:${phoneNumber}`;
      const data = {
        otp,
        attempts: 0,
        createdAt: Date.now()
      };

      await redisClient.setex(key, this.otpExpiry, JSON.stringify(data));
      console.log(`OTP stored for ${phoneNumber}`);
      return true;
    } catch (error) {
      console.error('Error storing OTP:', error);
      return false;
    }
  }

  /**
   * Verify OTP code
   * @param {string} phoneNumber - Phone number
   * @param {string} inputOTP - User input OTP
   * @returns {Promise<Object>} - Verification result
   */
  async verifyOTP(phoneNumber, inputOTP) {
    try {
      const key = `otp:${phoneNumber}`;
      const storedData = await redisClient.get(key);

      if (!storedData) {
        return {
          success: false,
          error: 'OTP expired or not found',
          code: 'OTP_EXPIRED'
        };
      }

      const { otp, attempts } = JSON.parse(storedData);

      // Check if max attempts exceeded
      if (attempts >= this.maxAttempts) {
        await redisClient.del(key); // Delete OTP after max attempts
        return {
          success: false,
          error: 'Maximum verification attempts exceeded',
          code: 'MAX_ATTEMPTS_EXCEEDED'
        };
      }

      // Verify OTP
      if (otp === inputOTP) {
        await redisClient.del(key); // Delete OTP after successful verification
        return {
          success: true,
          message: 'OTP verified successfully'
        };
      } else {
        // Increment attempt count
        const updatedData = {
          ...JSON.parse(storedData),
          attempts: attempts + 1
        };
        await redisClient.setex(key, this.otpExpiry, JSON.stringify(updatedData));

        return {
          success: false,
          error: 'Invalid OTP code',
          code: 'INVALID_OTP',
          remainingAttempts: this.maxAttempts - (attempts + 1)
        };
      }
    } catch (error) {
      console.error('Error verifying OTP:', error);
      return {
        success: false,
        error: 'Internal server error',
        code: 'VERIFICATION_ERROR'
      };
    }
  }

  /**
   * Check if OTP exists for phone number
   * @param {string} phoneNumber - Phone number
   * @returns {Promise<boolean>} - Whether OTP exists
   */
  async hasOTP(phoneNumber) {
    try {
      const key = `otp:${phoneNumber}`;
      const exists = await redisClient.exists(key);
      return exists === 1;
    } catch (error) {
      console.error('Error checking OTP existence:', error);
      return false;
    }
  }

  /**
   * Delete OTP for phone number
   * @param {string} phoneNumber - Phone number
   * @returns {Promise<boolean>} - Success status
   */
  async deleteOTP(phoneNumber) {
    try {
      const key = `otp:${phoneNumber}`;
      await redisClient.del(key);
      return true;
    } catch (error) {
      console.error('Error deleting OTP:', error);
      return false;
    }
  }
}

export default new OTPService();
