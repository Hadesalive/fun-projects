import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/auth_screen.dart';
import '../../features/auth/screens/phone_input_screen.dart';
import '../../features/auth/screens/otp_verification_screen.dart';
import '../../features/auth/screens/profile_setup_screen.dart';
import '../../features/chat/screens/enhanced_messages_screen.dart';
import '../../features/chat/screens/enhanced_chat_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/discover/screens/discover_screen.dart';
import '../../features/media/screens/media_viewer_screen.dart';
import '../../features/groups/screens/create_group_screen.dart';
import '../../features/chat/screens/contact_info_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String auth = '/auth';
  static const String phoneInput = '/phone-input';
  static const String otpVerification = '/otp-verification';
  static const String profileSetup = '/profile-setup';
  static const String messages = '/messages';
  static const String chat = '/chat';
  static const String profile = '/profile';
  static const String discover = '/discover';
  static const String groups = '/groups';
  static const String createGroup = '/groups/create';
  static const String mediaViewer = '/media-viewer';
  static const String contactInfo = '/contact-info';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: [
      // Splash Screen
      GoRoute(
        path: splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Onboarding
      GoRoute(
        path: onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      
      // Authentication
      GoRoute(
        path: auth,
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),
      
      // Phone Input
      GoRoute(
        path: phoneInput,
        name: 'phoneInput',
        builder: (context, state) => const PhoneInputScreen(),
      ),
      
      // OTP Verification
      GoRoute(
        path: otpVerification,
        name: 'otpVerification',
        builder: (context, state) {
          final phoneNumber = state.uri.queryParameters['phone'] ?? '';
          return OtpVerificationScreen(phoneNumber: phoneNumber);
        },
      ),
      
      // Profile Setup
      GoRoute(
        path: profileSetup,
        name: 'profileSetup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      
      // Main Messages Screen
      GoRoute(
        path: messages,
        name: 'messages',
        builder: (context, state) => const EnhancedMessagesScreen(),
      ),
      
      // Chat Screen
      GoRoute(
        path: chat,
        name: 'chat',
        builder: (context, state) {
          final peerName = state.extra as String? ?? 'Unknown';
          final peerAvatarUrl = state.uri.queryParameters['avatarUrl'] ?? '';
          return EnhancedChatScreen(
            peerName: peerName,
            peerAvatarUrl: peerAvatarUrl,
          );
        },
      ),
      
      // Profile Screen
      GoRoute(
        path: profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      
      // Discover Screen
      GoRoute(
        path: discover,
        name: 'discover',
        builder: (context, state) => const DiscoverScreen(),
      ),
      // Groups list (placeholder)
      GoRoute(
        path: groups,
        name: 'groups',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Groups')),
          body: const Center(child: Text('Groups coming soon')),
        ),
      ),
      // Create Group
      GoRoute(
        path: createGroup,
        name: 'createGroup',
        builder: (context, state) => const CreateGroupScreen(),
      ),
      
      // Contact Info
      GoRoute(
        path: contactInfo,
        name: 'contactInfo',
        builder: (context, state) {
          final contactName = state.uri.queryParameters['name'] ?? 'Unknown';
          final contactAvatarUrl = state.uri.queryParameters['avatar'] ?? '';
          final isMuted = state.uri.queryParameters['muted'] == 'true';
          final isBlocked = state.uri.queryParameters['blocked'] == 'true';
          return ContactInfoScreen(
            contactName: contactName,
            contactAvatarUrl: contactAvatarUrl,
            initialMuteState: isMuted,
            initialBlockState: isBlocked,
          );
        },
      ),
      
      // Media Viewer
      GoRoute(
        path: mediaViewer,
        name: 'media-viewer',
        builder: (context, state) {
          final mediaUrl = state.uri.queryParameters['url'] ?? '';
          final mediaType = state.uri.queryParameters['type'] ?? 'image';
          return MediaViewerScreen(
            mediaUrl: mediaUrl,
            mediaType: mediaType,
          );
        },
      ),
    ],
  );
}
