// Mock SMS service for Firebase phone authentication
// Since Firebase handles SMS sending, we just need phone validation

class SMSService {
  constructor() {
    console.log('📱 SMS Service initialized (Firebase mode - no Twilio needed)');
  }

  /**
   * Mock send OTP - Firebase handles this
   * @param {string} phoneNumber - Phone number in E.164 format (+1234567890)
   * @param {string} otp - 6-digit OTP code
   * @returns {Promise<Object>} - Mock success result
   */
  async sendOTP(phoneNumber, otp) {
    console.log(`📱 Mock SMS: OTP ${otp} would be sent to ${phoneNumber} (Firebase handles actual sending)`);
    
    return {
      success: true,
      messageSid: `mock_${Date.now()}`,
      status: 'sent',
      provider: 'firebase'
    };
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
    // If already in E.164 format (starts with +), return as-is
    if (phoneNumber.startsWith('+')) {
      return phoneNumber;
    }
    
    // Remove all non-digit characters
    const cleaned = phoneNumber.replace(/\D/g, '');
    
    // Add country code if not present and looks like a US number
    if (!cleaned.startsWith('1') && countryCode === 'US' && cleaned.length === 10) {
      return `+1${cleaned}`;
    }
    
    // Add + if not present
    return `+${cleaned}`;
  }

  /**
   * Check if SMS service is available
   * @returns {boolean} - Always true for Firebase mode
   */
  isAvailable() {
    return true;
  }
}

export default new SMSService();