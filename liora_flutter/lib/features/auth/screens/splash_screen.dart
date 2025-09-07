import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/firebase_auth_service.dart';
import 'onboarding_screen.dart';
import '../../../screens/messages_screen.dart';
import 'package:go_router/go_router.dart';
import '../../../core/navigation/app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    // Initialize services
    final apiService = ApiService();
    apiService.initialize();

    // Simulate app initialization
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Check authentication status
    final prefs = await SharedPreferences.getInstance();
    final hasCompletedOnboarding = prefs.getBool(AppConstants.onboardingKey) ?? false;
    final backendToken = prefs.getString('backend_token');
    
    print('🔍 Auth Check: Backend token exists: ${backendToken != null}');
    print('🔍 Auth Check: Onboarding completed: $hasCompletedOnboarding');

    // Navigate based on authentication state
    if (backendToken != null && backendToken.isNotEmpty) {
      // User has backend token, verify it's still valid
      print('🔑 Found backend token, verifying with server...');
      
      try {
        final userResult = await apiService.getCurrentUser();
        
        if (userResult.success) {
          print('✅ User authenticated, going to messages');
          _navigateToMessages();
          return;
        } else {
          print('❌ Backend token invalid, clearing and going to auth');
          // Clear invalid token
          await prefs.remove('backend_token');
        }
      } catch (e) {
        print('❌ Error verifying token: $e');
        // Clear potentially corrupted token
        await prefs.remove('backend_token');
      }
    }

    // User not authenticated or token invalid
    if (hasCompletedOnboarding) {
      // User has seen onboarding but not authenticated, go to auth
      print('📱 Going to auth screen');
      _navigateToAuth();
    } else {
      // First time user, show onboarding
      print('👋 First time user, showing onboarding');
      _navigateToOnboarding();
    }
  }

  void _navigateToOnboarding() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go(AppRouter.onboarding);
    });
  }

  void _navigateToAuth() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go(AppRouter.auth);
    });
  }

  void _navigateToMessages() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go(AppRouter.messages);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.systemBlue,
              AppColors.systemTeal,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Text(
                    '💬',
                    style: TextStyle(fontSize: 50),
                  ),
                ),
              )
                  .animate()
                  .scale(
                    duration: 800.ms,
                    curve: Curves.elasticOut,
                  )
                  .then(delay: 200.ms)
                  .shimmer(
                    duration: 1000.ms,
                    color: Colors.white.withOpacity(0.5),
                  ),

              const SizedBox(height: 32),

              // App name
              Text(
                AppConstants.appName,
                style: GoogleFonts.inter(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 600.ms)
                  .slideY(begin: 0.3, end: 0),

              const SizedBox(height: 8),

              // App tagline
              Text(
                'Beautiful messaging',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.9),
                ),
              )
                  .animate()
                  .fadeIn(delay: 600.ms, duration: 600.ms)
                  .slideY(begin: 0.3, end: 0),

              const SizedBox(height: 80),

              // Loading indicator
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.8),
                  ),
                ),
              ).animate().fadeIn(delay: 1000.ms),
            ],
          ),
        ),
      ),
    );
  }
}
