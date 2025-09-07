import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/services/firebase_auth_service.dart';

class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _countryCode = '+232';
  String _phoneNumber = '';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();
    
    try {
      final authService = FirebaseAuthService();
      final result = await authService.sendOTP(_countryCode + _phoneNumber);
      
      if (mounted) {
        setState(() => _isLoading = false);
        
        if (result.success) {
          // Navigate to OTP verification screen
          context.go('${AppRouter.otpVerification}?phone=${Uri.encodeComponent(_countryCode + _phoneNumber)}');
        } else {
          // Show error dialog
          _showErrorDialog(result.error ?? 'Failed to send OTP');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog('An unexpected error occurred');
      }
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // Header
              Text(
                'Enter your phone number',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.darkBackground,
                ),
              ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2),
              
              const SizedBox(height: 12),
              
              Text(
                'We\'ll send you a verification code',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: isDark ? Colors.white70 : AppColors.darkBackground.withOpacity(0.7),
                ),
              ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.1),
              
              const SizedBox(height: 60),
              
              // Phone input form
              Form(
                key: _formKey,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDark ? Colors.white24 : AppColors.darkBackground.withOpacity(0.2),
                    ),
                    borderRadius: BorderRadius.circular(16),
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
                  ),
                  child: Row(
                    children: [
                      // Fixed country code with flag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Sierra Leone flag emoji
                            const Text(
                              '🇸🇱',
                              style: TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 8),
                            // Country code
                            Text(
                              '+232',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : AppColors.darkBackground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Divider
                      Container(
                        height: 24,
                        width: 1,
                        color: isDark ? Colors.white24 : AppColors.darkBackground.withOpacity(0.2),
                      ),
                      // Phone number input
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          onChanged: (value) {
                            _phoneNumber = value;
                            _countryCode = '+232';
                          },
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            labelStyle: GoogleFonts.inter(
                              color: isDark ? Colors.white70 : AppColors.darkBackground.withOpacity(0.7),
                            ),
                            hintText: 'Enter your phone number',
                            hintStyle: GoogleFonts.inter(
                              color: isDark ? Colors.white54 : AppColors.darkBackground.withOpacity(0.5),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: isDark ? Colors.white : AppColors.darkBackground,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            if (value.length < 8) {
                              return 'Please enter a valid phone number';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 1000.ms).slideY(begin: 0.2),
              
              const SizedBox(height: 40),
              
              // Send OTP button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.messageCircle,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Send Code',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ).animate().fadeIn(duration: 1200.ms).slideY(begin: 0.2),
              
              const Spacer(),
              
              // Terms and privacy
              Text(
                'By continuing, you agree to our Terms of Service and Privacy Policy',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : AppColors.darkBackground.withOpacity(0.6),
                ),
              ).animate().fadeIn(duration: 1400.ms),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
