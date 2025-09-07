# Liora - Beautiful Messaging App 💬

A cross-platform messaging app built with Flutter and Node.js, featuring Apple-quality UI design and modern messaging capabilities.

## ✨ Features

### 🎨 UI/UX
- **Apple HIG-first design** - iOS-style interface with translucent bars, haptics, and smooth animations
- **Dark/Light theme support** - Seamless theme switching with system preference detection
- **Responsive design** - Works beautifully on phones, tablets, and desktop
- **Accessibility** - VoiceOver/TalkBack support, large text scaling, high contrast

### 💬 Messaging
- **Real-time messaging** - Instant message delivery with WebSocket connections
- **Rich media support** - Send photos, videos, voice notes, and files
- **Message status indicators** - Sent, delivered, and read receipts
- **Typing indicators** - See when someone is typing
- **Message reactions** - React with emojis to messages
- **Reply to messages** - Quote and reply to specific messages

### 🔐 Authentication & Security
- **Multiple sign-in options** - Apple, Google, and email authentication
- **Secure messaging** - End-to-end encryption for all messages
- **Privacy controls** - Control who can see your online status and profile

### 🚀 Performance
- **Offline support** - Queue messages when offline, sync when back online
- **Image optimization** - Automatic image compression and caching
- **Smooth animations** - 60fps animations with Flutter's performance

## 📱 Screenshots

| Onboarding | Messages List | Chat View |
|------------|---------------|-----------|
| ![Onboarding](screenshots/onboarding.png) | ![Messages](screenshots/messages.png) | ![Chat](screenshots/chat.png) |

## 🛠 Tech Stack

### Frontend (Flutter)
- **Flutter 3.24+** - Cross-platform framework
- **Riverpod** - State management
- **GoRouter** - Navigation and routing
- **Dio** - HTTP client for API calls
- **WebSocket** - Real-time messaging
- **Cached Network Image** - Image loading and caching
- **Flutter Animate** - Smooth animations
- **Google Fonts** - Typography

### Backend (Node.js)
- **Express.js** - Web framework
- **Socket.IO** - Real-time WebSocket communication
- **MongoDB** - Database for messages and user data
- **Redis** - Caching and session management
- **JWT** - Authentication tokens
- **Cloudinary** - Media storage and optimization
- **Firebase** - Push notifications

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.24 or higher
- Node.js 18 or higher
- MongoDB (local or Atlas)
- Redis (optional, for caching)

### Backend Setup

1. **Clone and navigate to backend**
   ```bash
   cd liora_backend
   npm install
   ```

2. **Environment setup**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

3. **Start the server**
   ```bash
   npm run dev
   ```

### Flutter App Setup

1. **Navigate to Flutter directory**
   ```bash
   cd liora_flutter
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code**
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## 📁 Project Structure

### Flutter App Structure
```
lib/
├── core/                    # Core app functionality
│   ├── constants/          # App constants and colors
│   ├── models/            # Data models
│   ├── services/          # API and business logic services
│   └── utils/             # Utility functions and themes
├── features/               # Feature-based modules
│   ├── auth/              # Authentication screens and logic
│   ├── chat/              # Chat and messaging functionality
│   ├── profile/           # User profile management
│   └── media/             # Media handling and viewers
├── shared/                 # Shared components
│   ├── providers/         # Riverpod providers
│   ├── widgets/           # Reusable UI components
│   └── utils/             # Shared utilities
└── screens/               # Legacy screens (being migrated)
```

### Backend Structure
```
src/
├── config/                # Database and service configurations
├── models/                # MongoDB schemas
├── routes/                # API route handlers
├── middleware/            # Express middleware
├── controllers/           # Business logic controllers
├── services/              # External service integrations
├── socket/                # WebSocket event handlers
└── utils/                 # Utility functions
```

## 🎨 Design System

### Colors (iOS HIG Compliant)
- **Primary**: System Blue (#007AFF)
- **Success**: System Green (#34C759)
- **Warning**: System Orange (#FF9500)
- **Error**: System Red (#FF3B30)

### Typography
- **Font**: Inter (Google Fonts)
- **Scales**: iOS-style type scales (Large Title, Title 1-3, Headline, Body, etc.)

### Components
- **Message Bubbles**: iOS-style with rounded corners and proper spacing
- **Input Fields**: Rounded with subtle shadows and focus states
- **Buttons**: iOS-style with proper touch feedback and animations

## 🔧 Configuration

### Environment Variables (Backend)
```env
PORT=3000
MONGODB_URI=mongodb://localhost:27017/liora
REDIS_URL=redis://localhost:6379
JWT_SECRET=your-super-secret-key
CLOUDINARY_CLOUD_NAME=your-cloud-name
FIREBASE_PROJECT_ID=your-project-id
```

### App Configuration (Flutter)
Update `lib/core/constants/app_constants.dart` with your backend URL and API keys.

## 🧪 Testing

### Backend Tests
```bash
cd liora_backend
npm test
```

### Flutter Tests
```bash
cd liora_flutter
flutter test
```

## 📦 Deployment

### Backend (Production)
1. **Deploy to your preferred platform** (Railway, Heroku, DigitalOcean, etc.)
2. **Set up MongoDB Atlas** for production database
3. **Configure Redis** for session management
4. **Set up Cloudinary** for media storage
5. **Configure Firebase** for push notifications

### Flutter App
1. **iOS**: Build and deploy to App Store
2. **Android**: Build and deploy to Google Play Store
3. **Web**: Deploy to Firebase Hosting or Vercel

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Apple** for the Human Interface Guidelines
- **Flutter Team** for the amazing framework
- **Material Design** for design inspiration
- **Open Source Community** for the incredible packages

## 📞 Support

- **Documentation**: [docs.liora.app](https://docs.liora.app)
- **Issues**: [GitHub Issues](https://github.com/your-username/liora/issues)
- **Discord**: [Join our community](https://discord.gg/liora)
- **Email**: support@liora.app

---

Built with ❤️ by the Liora Team