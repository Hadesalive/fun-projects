# Environment Variables Setup

Create a `.env` file in the backend root directory with the following variables:

```env
# Server Configuration
NODE_ENV=development
PORT=3000
CORS_ORIGIN=http://localhost:3000,http://localhost:8080

# Database
MONGODB_URI=mongodb://localhost:27017/liora
REDIS_URL=redis://localhost:6379

# JWT
JWT_SECRET=your-super-secret-jwt-key-here

# Twilio SMS Configuration
TWILIO_ACCOUNT_SID=your-twilio-account-sid
TWILIO_AUTH_TOKEN=your-twilio-auth-token
TWILIO_PHONE_NUMBER=+1234567890

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# Cloudinary (for media uploads)
CLOUDINARY_CLOUD_NAME=your-cloudinary-cloud-name
CLOUDINARY_API_KEY=your-cloudinary-api-key
CLOUDINARY_API_SECRET=your-cloudinary-api-secret
```

## Twilio Setup Instructions:

1. Go to [Twilio Console](https://console.twilio.com/)
2. Sign up for a free account
3. Get your Account SID and Auth Token from the dashboard
4. Buy a phone number (free trial includes $15 credit)
5. Add the phone number to your .env file

## Quick Test:
- Free tier: 100 SMS/month
- Perfect for 40 students (2.5 SMS per student)
- No credit card required for testing
