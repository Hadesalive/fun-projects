import twilio from 'twilio';
import dotenv from 'dotenv';

dotenv.config();

class SMSService {
  constructor() {
    this.client = twilio(
      process.env.TWILIO_ACCOUNT_SID,
      process.env.TWILIO_AUTH_TOKEN
    );
    this.fromNumber = process.env.TWILIO_PHONE_NUMBER;
  }

  /**
   * Send OTP SMS to phone number
   * @param {string} phoneNumber - Phone number in E.164 format (+1234567890)
   * @param {string} otp - 6-digit OTP code
   * @returns {Promise<Object>} - Twilio message result
   */
  async sendOTP(phoneNumber, otp) {
    try {
      const message = await this.client.messages.create({
        body: `Your Liora verification code is: ${otp}. This code will expire in 5 minutes.`,
        from: this.fromNumber,
        to: phoneNumber
      });

      console.log(`SMS sent successfully to ${phoneNumber}. SID: ${message.sid}`);
      return {
        success: true,
        messageSid: message.sid,
        status: message.status
      };
    } catch (error) {
      console.error('Error sending SMS:', error);
      return {
        success: false,
        error: error.message,
        code: error.code
      };
    }
  }

  /**
   * Validate phone number format
   * @param {string} phoneNumber - Phone number to validate
   * @returns {boolean} - Whether phone number is valid
   */
  isValidPhoneNumber(phoneNumber) {
    // E.164 format validation
    const phoneRegex = /^\+[1-9]\d{1,14}$/;
    return phoneRegex.test(phoneNumber);
  }

  /**
   * Format phone number to E.164 format
   * @param {string} phoneNumber - Raw phone number
   * @param {string} countryCode - Country code (e.g., 'US', 'CA')
   * @returns {string} - Formatted phone number
   */
  formatPhoneNumber(phoneNumber, countryCode = 'US') {
    // Remove all non-digit characters
    const cleaned = phoneNumber.replace(/\D/g, '');
    
    // Add country code if not present
    if (!cleaned.startsWith('1') && countryCode === 'US') {
      return `+1${cleaned}`;
    }
    
    // Add + if not present
    if (!phoneNumber.startsWith('+')) {
      return `+${cleaned}`;
    }
    
    return phoneNumber;
  }
}

export default new SMSService();
