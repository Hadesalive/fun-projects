// App-wide constants
class AppConstants {
  // App Info
  static const String appName = 'Liora';
  static const String appVersion = '1.0.0';
  
  // API Configuration
  static const String baseUrl = 'https://api.liora.app';
  static const String wsUrl = 'wss://ws.liora.app';
  
  // Clerk Configuration
  static const String clerkPublishableKey = 'pk_test_your-clerk-key';
  
  // Database
  static const String dbName = 'liora.db';
  static const int dbVersion = 1;
  
  // Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userDataKey = 'user_data';
  static const String themeKey = 'app_theme';
  static const String onboardingKey = 'onboarding_completed';
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Chat Settings
  static const int maxMessageLength = 4000;
  static const int maxMediaSize = 50 * 1024 * 1024; // 50MB
  static const int messagesPerPage = 50;
  
  // Media Settings
  static const List<String> supportedImageTypes = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
  static const List<String> supportedVideoTypes = ['mp4', 'mov', 'avi'];
  
  // Network
  static const Duration networkTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
}
