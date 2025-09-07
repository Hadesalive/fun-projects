import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/services/media_service.dart';
import '../../../core/services/firebase_auth_service.dart';
import '../../../core/services/api_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final MediaService _mediaService = MediaService();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _isUploadingImage = false;
  String? _selectedAvatar;
  String? _selectedImagePath;
  String? _uploadedImageUrl;

  @override
  void initState() {
    super.initState();
    _apiService.initialize();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _selectProfilePhoto() async {
    HapticFeedback.lightImpact();
    
    // Show iOS-style action sheet for photo selection
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(
          'Select Profile Photo',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        message: Text(
          'Choose how you\'d like to add your profile picture',
          style: GoogleFonts.inter(
            fontSize: 13,
          ),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              await _pickImage(ImageSource.camera);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.camera,
                  size: 20,
                  color: AppColors.systemBlue,
                ),
                const SizedBox(width: 8),
                Text(
                  'Take Photo',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    color: AppColors.systemBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              await _pickImage(ImageSource.gallery);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.image,
                  size: 20,
                  color: AppColors.systemBlue,
                ),
                const SizedBox(width: 8),
                Text(
                  'Choose from Gallery',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    color: AppColors.systemBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      MediaResult<String> result;
      
      if (source == ImageSource.camera) {
        result = await _mediaService.takePhoto();
      } else {
        result = await _mediaService.pickImageFromLibrary();
      }
      
      if (result.isSuccess && result.data != null) {
        setState(() {
          _selectedImagePath = result.data;
          _selectedAvatar = null; // Clear any preset avatar
        });
        HapticFeedback.lightImpact();
        _showSuccessDialog('Photo selected successfully!');
      } else if (result.isCancelled) {
        // User cancelled, do nothing
      } else {
        // Show specific error message for permission issues
        final errorMessage = result.error ?? 'Failed to select image. Please try again.';
        _showErrorDialog(errorMessage);
        
        // If permission was permanently denied, offer to open settings
        if (errorMessage.contains('permanently denied') || errorMessage.contains('Settings')) {
          _showPermissionSettingsDialog();
        }
      }
    } catch (e) {
      _showErrorDialog('Error selecting image: ${e.toString()}');
    }
  }

  void _showPermissionSettingsDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Permission Required',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Photo library access is required to select photos. Please enable it in Settings.',
          style: GoogleFonts.inter(
            fontSize: 13,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              _mediaService.openAppSettings();
            },
            child: Text(
              'Open Settings',
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

  Future<void> _completeSetup() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();
    
    try {
      // Step 1: Upload image if selected (for now, we'll use a placeholder URL)
      String? avatarUrl;
      if (_selectedImagePath != null) {
        setState(() => _isUploadingImage = true);
        
        // TODO: Implement actual image upload to your backend or cloud storage
        // For now, we'll use a placeholder URL based on the user's name
        final firstName = _nameController.text.trim().split(' ').first.toLowerCase();
        avatarUrl = 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(_nameController.text.trim())}&size=200&background=6366f1&color=ffffff';
        
        setState(() => _isUploadingImage = false);
      }
      
      // Step 2: Update profile on backend
      final result = await _apiService.updateProfileAuth(
        displayName: _nameController.text.trim(),
        username: _usernameController.text.trim().isNotEmpty 
            ? _usernameController.text.trim() 
            : null,
        avatarUrl: avatarUrl,
      );
      
      if (mounted) {
        setState(() => _isLoading = false);
        
        if (result.success) {
          // Show success message
          _showSuccessDialog('Profile setup complete! Welcome to Liora.');
          
          // Navigate to messages screen after a short delay
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            context.go(AppRouter.messages);
          }
        } else {
          _showErrorDialog(result.error ?? 'Failed to update profile');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploadingImage = false;
        });
        _showErrorDialog('An unexpected error occurred: ${e.toString()}');
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
                'Set up your profile',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.darkBackground,
                ),
              ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2),
              
              const SizedBox(height: 12),
              
              Text(
                'Add your name and profile picture',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: isDark ? Colors.white70 : AppColors.darkBackground.withOpacity(0.7),
                ),
              ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.1),
              
              const SizedBox(height: 60),
              
              // Avatar selection
              GestureDetector(
                onTap: _selectProfilePhoto,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    border: Border.all(
                      color: AppColors.primary,
                      width: 3,
                    ),
                  ),
                  child: _selectedImagePath != null
                      ? ClipOval(
                          child: Image.file(
                            File(_selectedImagePath!),
                            fit: BoxFit.cover,
                            width: 120,
                            height: 120,
                          ),
                        )
                      : _selectedAvatar != null
                          ? ClipOval(
                              child: Image.asset(
                                _selectedAvatar!,
                                fit: BoxFit.cover,
                                width: 120,
                                height: 120,
                              ),
                            )
                          : Icon(
                              LucideIcons.camera,
                              size: 40,
                              color: isDark ? Colors.white70 : AppColors.darkBackground.withOpacity(0.7),
                            ),
                ),
              ).animate().fadeIn(duration: 1000.ms).scale(),
              
              const SizedBox(height: 20),
              
              Text(
                'Tap to add photo',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ).animate().fadeIn(duration: 1200.ms),
              
              const SizedBox(height: 60),
              
              // Name and username input form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Full Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        labelStyle: GoogleFonts.inter(
                          color: isDark ? Colors.white70 : AppColors.darkBackground.withOpacity(0.7),
                        ),
                        hintText: 'Enter your full name',
                        hintStyle: GoogleFonts.inter(
                          color: isDark ? Colors.white54 : AppColors.darkBackground.withOpacity(0.5),
                        ),
                        prefixIcon: Icon(
                          LucideIcons.user,
                          color: isDark ? Colors.white70 : AppColors.darkBackground.withOpacity(0.7),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white24 : AppColors.darkBackground.withOpacity(0.2),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white24 : AppColors.darkBackground.withOpacity(0.2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
                      ),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: isDark ? Colors.white : AppColors.darkBackground,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        if (value.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Username Field (Optional)
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username (Optional)',
                        labelStyle: GoogleFonts.inter(
                          color: isDark ? Colors.white70 : AppColors.darkBackground.withOpacity(0.7),
                        ),
                        hintText: 'Choose a unique username',
                        hintStyle: GoogleFonts.inter(
                          color: isDark ? Colors.white54 : AppColors.darkBackground.withOpacity(0.5),
                        ),
                        prefixIcon: Icon(
                          LucideIcons.atSign,
                          color: isDark ? Colors.white70 : AppColors.darkBackground.withOpacity(0.7),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white24 : AppColors.darkBackground.withOpacity(0.2),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white24 : AppColors.darkBackground.withOpacity(0.2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
                      ),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: isDark ? Colors.white : AppColors.darkBackground,
                      ),
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          if (value.trim().length < 3) {
                            return 'Username must be at least 3 characters';
                          }
                          if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
                            return 'Username can only contain letters, numbers, and underscores';
                          }
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 1400.ms).slideY(begin: 0.2),
              
              const SizedBox(height: 40),
              
              // Complete setup button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _completeSetup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _isUploadingImage ? 'Processing image...' : 'Setting up profile...',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.checkCircle,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Complete Setup',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ).animate().fadeIn(duration: 1600.ms).slideY(begin: 0.2),
              
              const Spacer(),
              
              // Skip for now
              TextButton(
                onPressed: _isLoading ? null : _completeSetup,
                child: Text(
                  'Skip for now',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : AppColors.darkBackground.withOpacity(0.7),
                  ),
                ),
              ).animate().fadeIn(duration: 1800.ms),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
