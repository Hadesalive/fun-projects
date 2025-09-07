import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/services/firebase_auth_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  
  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  TextEditingController? _otpController;
  Timer? _resendTimer;
  bool _isLoading = false;
  bool _isResending = false;
  int _resendCountdown = 0;
  String _otp = '';

  @override
  void initState() {
    super.initState();
    _otpController = TextEditingController();
    _startResendCountdown();
  }

  @override
  void deactivate() {
    // Cancel timer when widget is deactivated
    _resendTimer?.cancel();
    _resendTimer = null;
    super.deactivate();
  }

  @override
  void dispose() {
    // Cancel timer first to prevent setState calls after disposal
    _resendTimer?.cancel();
    _resendTimer = null;
    
    // Dispose controller safely - check if it's not null and not already disposed
    if (_otpController != null) {
      _otpController!.dispose();
      _otpController = null;
    }
    
    super.dispose();
  }

  void _startResendCountdown() {
    // Cancel any existing timer first
    _resendTimer?.cancel();
    
    setState(() => _resendCountdown = 30);
    
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Check if widget is still mounted before calling setState
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _verifyOTP() async {
    if (_otp.length != 6) {
      _showErrorDialog('Please enter the 6-digit code');
      return;
    }
    
    if (!mounted) return;
    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();
    
    try {
      final authService = FirebaseAuthService();
      final result = await authService.verifyOTP(_otp);
      
      if (mounted) {
        setState(() => _isLoading = false);
        
        if (result.success) {
          // Navigate to profile setup screen
          context.go(AppRouter.profileSetup);
        } else {
          _showErrorDialog(result.error ?? 'Verification failed');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog('An unexpected error occurred');
      }
    }
  }

  Future<void> _resendOTP() async {
    if (_resendCountdown > 0 || !mounted) return;
    
    setState(() => _isResending = true);
    HapticFeedback.lightImpact();
    
    try {
      final authService = FirebaseAuthService();
      final result = await authService.sendOTP(widget.phoneNumber);
      
      if (mounted) {
        setState(() => _isResending = false);
        
        if (result.success) {
          _startResendCountdown();
          _showSuccessDialog('Code sent successfully');
        } else {
          _showErrorDialog(result.error ?? 'Failed to resend code');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isResending = false);
        _showErrorDialog('An unexpected error occurred');
      }
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Error',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(
            fontSize: 13,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.systemBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Success',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(
            fontSize: 13,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.systemBlue,
              ),
            ),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            CupertinoIcons.back,
            color: isDark ? Colors.white : AppColors.darkBackground,
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              context.pop();
            } else {
              context.go(AppRouter.phoneInput);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // Header
              Text(
                'Enter verification code',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.darkBackground,
                ),
              ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2),
              
              const SizedBox(height: 12),
              
              Text(
                'We sent a 6-digit code to',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: isDark ? Colors.white70 : AppColors.darkBackground.withOpacity(0.7),
                ),
              ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.1),
              
              const SizedBox(height: 8),
              
              Text(
                widget.phoneNumber,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ).animate().fadeIn(duration: 1000.ms),
              
              const SizedBox(height: 60),
              
              // OTP input
              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: _otpController,
                onChanged: (value) {
                  if (mounted) {
                    setState(() => _otp = value);
                  }
                },
                onCompleted: (value) {
                  _verifyOTP();
                },
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12),
                  fieldHeight: 56,
                  fieldWidth: 48,
                  activeColor: AppColors.primary,
                  inactiveColor: isDark ? Colors.white24 : AppColors.darkBackground.withOpacity(0.2),
                  selectedColor: AppColors.primary,
                  activeFillColor: Colors.transparent,
                  inactiveFillColor: Colors.transparent,
                  selectedFillColor: Colors.transparent,
                ),
                enableActiveFill: true,
                keyboardType: TextInputType.number,
                textStyle: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.darkBackground,
                ),
                animationType: AnimationType.fade,
                animationDuration: const Duration(milliseconds: 300),
              ).animate().fadeIn(duration: 1200.ms).slideY(begin: 0.2),
              
              const SizedBox(height: 40),
              
              // Verify button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOTP,
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
                              LucideIcons.check,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Verify Code',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ).animate().fadeIn(duration: 1400.ms).slideY(begin: 0.2),
              
              const SizedBox(height: 30),
              
              // Resend code
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Didn\'t receive the code? ',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : AppColors.darkBackground.withOpacity(0.7),
                    ),
                  ),
                  GestureDetector(
                    onTap: _resendCountdown > 0 ? null : _resendOTP,
                    child: Text(
                      _resendCountdown > 0 
                          ? 'Resend in ${_resendCountdown}s'
                          : _isResending 
                              ? 'Sending...'
                              : 'Resend',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _resendCountdown > 0 
                            ? (isDark ? Colors.white54 : AppColors.darkBackground.withOpacity(0.5))
                            : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 1600.ms),
              
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
