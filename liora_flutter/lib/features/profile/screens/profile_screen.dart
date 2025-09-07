import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/firebase_auth_service.dart';
import '../../../core/services/media_service.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../core/navigation/app_router.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final ApiService _apiService = ApiService();
  final FirebaseAuthService _authService = FirebaseAuthService();
  final MediaService _mediaService = MediaService();
  
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _userSettings;
  bool _isLoading = true;
  bool _isUpdatingSettings = false;
  
  // Settings state (will be loaded from backend)
  bool _notifications = true;
  bool _readReceipts = true;
  bool _typingIndicators = true;
  bool _soundEffects = true;
  
  @override
  void initState() {
    super.initState();
    _apiService.initialize();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final result = await _apiService.getCurrentUser();
      
      if (result.success && mounted) {
        setState(() {
          _userProfile = result.data;
        });
        
        // Load user settings from profile data
        _loadSettingsFromProfile();
        
        print('👤 User profile loaded: ${result.data}');
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          _showError('Failed to load profile: ${result.error}');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Error loading profile: $e');
      }
    }
  }

  void _loadSettingsFromProfile() {
    if (_userProfile != null) {
      final settings = _userProfile!['settings'] as Map<String, dynamic>?;
      
      if (settings != null) {
        _userSettings = settings;
        
        // Load notification settings
        final notifications = settings['notifications'] as Map<String, dynamic>?;
        if (notifications != null) {
          _notifications = notifications['messages'] ?? true;
          _soundEffects = notifications['sounds'] ?? true;
        }
        
        // For now, map read receipts and typing indicators to privacy settings
        final privacy = settings['privacy'] as Map<String, dynamic>?;
        if (privacy != null) {
          // These could be mapped to specific privacy settings
          _readReceipts = privacy['lastSeen'] != 'nobody';
          _typingIndicators = true; // Default for now
        }
        
        print('⚙️ Settings loaded: $_userSettings');
      }
      
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateNotificationSetting(String settingKey, bool value) async {
    if (_isUpdatingSettings) return;
    
    setState(() => _isUpdatingSettings = true);
    
    try {
      final currentNotifications = _userSettings?['notifications'] as Map<String, dynamic>? ?? {};
      final updatedNotifications = Map<String, dynamic>.from(currentNotifications);
      updatedNotifications[settingKey] = value;
      
      final result = await _apiService.updateSettings(
        notifications: updatedNotifications,
      );
      
      if (result.success) {
        setState(() {
          _userSettings = result.data;
          // Update local state based on the setting
          switch (settingKey) {
            case 'messages':
              _notifications = value;
              break;
            case 'sounds':
              _soundEffects = value;
              break;
          }
        });
        
        HapticFeedback.lightImpact();
        _showSuccessMessage('${_getSettingDisplayName(settingKey)} ${value ? 'enabled' : 'disabled'}');
      } else {
        _showError('Failed to update setting: ${result.error}');
        // Revert the UI state
        _loadSettingsFromProfile();
      }
    } catch (e) {
      _showError('Error updating setting: $e');
      _loadSettingsFromProfile();
    } finally {
      setState(() => _isUpdatingSettings = false);
    }
  }

  Future<void> _updatePrivacySetting(String settingKey, String value) async {
    if (_isUpdatingSettings) return;
    
    setState(() => _isUpdatingSettings = true);
    
    try {
      final currentPrivacy = _userSettings?['privacy'] as Map<String, dynamic>? ?? {};
      final updatedPrivacy = Map<String, dynamic>.from(currentPrivacy);
      updatedPrivacy[settingKey] = value;
      
      final result = await _apiService.updateSettings(
        privacy: updatedPrivacy,
      );
      
      if (result.success) {
        setState(() {
          _userSettings = result.data;
          // Update local state
          if (settingKey == 'lastSeen') {
            _readReceipts = value != 'nobody';
          }
        });
        
        HapticFeedback.lightImpact();
        _showSuccessMessage('Privacy setting updated');
      } else {
        _showError('Failed to update privacy setting: ${result.error}');
        _loadSettingsFromProfile();
      }
    } catch (e) {
      _showError('Error updating privacy setting: $e');
      _loadSettingsFromProfile();
    } finally {
      setState(() => _isUpdatingSettings = false);
    }
  }

  String _getSettingDisplayName(String settingKey) {
    switch (settingKey) {
      case 'messages':
        return 'Notifications';
      case 'sounds':
        return 'Sound effects';
      default:
        return settingKey;
    }
  }

  void _showSuccessMessage(String message) {
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
            onPressed: () => Navigator.of(context).pop(),
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

  Future<void> _signOut() async {
    try {
      // Show confirmation dialog
      final shouldSignOut = await showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(
            'Sign Out',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Are you sure you want to sign out?',
            style: GoogleFonts.inter(
              fontSize: 13,
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Sign Out',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );

      if (shouldSignOut == true) {
        // Sign out from both services
        await _apiService.signOut();
        await _authService.signOut();
        
        if (mounted) {
          // Navigate to auth screen
          context.go(AppRouter.auth);
        }
      }
    } catch (e) {
      _showError('Error signing out: $e');
    }
  }

  void _showEditProfileDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditProfileBottomSheet(
        userProfile: _userProfile,
        onProfileUpdated: (updatedProfile) {
          setState(() {
            _userProfile = updatedProfile;
          });
        },
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    
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
            onPressed: () => Navigator.of(context).pop(),
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
    final appThemeMode = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        title: Text(
          'Profile',
          style: GoogleFonts.inter(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(
              CupertinoIcons.xmark,
              color: AppColors.systemBlue,
              size: 22,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Profile Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: _isLoading 
                ? _buildLoadingHeader(isDark)
                : _buildProfileHeader(isDark),
          ),
          
          // Settings List
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                // Theme Section
                _buildSettingsSection(
                  isDark,
                  children: [
                    _buildSettingsTile(
                      'Dark Mode',
                      isDark,
                      icon: CupertinoIcons.moon_fill,
                      trailing: _buildThemeToggle(appThemeMode, isDark),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Groups Section
                _buildSettingsSection(
                  isDark,
                  children: [
                    _buildSettingsTile(
                      'My Groups',
                      isDark,
                      icon: CupertinoIcons.group_solid,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.push(AppRouter.groups);
                      },
                    ),
                    _buildDivider(isDark),
                    _buildSettingsTile(
                      'Create Group',
                      isDark,
                      icon: CupertinoIcons.person_add_solid,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.push(AppRouter.createGroup);
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Privacy & Chat Settings
                _buildSettingsSection(
                  isDark,
                  children: [
                    // Settings loading indicator
                    if (_isUpdatingSettings)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.systemBlue),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Updating settings...',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.systemGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_isUpdatingSettings)
                      _buildDivider(isDark),
                    _buildSettingsTile(
                      'Notifications',
                      isDark,
                      icon: CupertinoIcons.bell_fill,
                      trailing: Switch(
                        value: _notifications,
                        onChanged: _isUpdatingSettings ? null : (value) {
                          _updateNotificationSetting('messages', value);
                        },
                        activeColor: AppColors.systemBlue,
                      ),
                    ),
                    _buildDivider(isDark),
                    _buildSettingsTile(
                      'Read Receipts',
                      isDark,
                      icon: CupertinoIcons.checkmark_circle_fill,
                      trailing: Switch(
                        value: _readReceipts,
                        onChanged: _isUpdatingSettings ? null : (value) {
                          // Map read receipts to lastSeen privacy setting
                          final privacyValue = value ? 'everyone' : 'nobody';
                          _updatePrivacySetting('lastSeen', privacyValue);
                        },
                        activeColor: AppColors.systemBlue,
                      ),
                    ),
                    _buildDivider(isDark),
                    _buildSettingsTile(
                      'Typing Indicators',
                      isDark,
                      icon: CupertinoIcons.ellipsis_circle_fill,
                      trailing: Switch(
                        value: _typingIndicators,
                        onChanged: _isUpdatingSettings ? null : (value) {
                          // For now, this is a local setting (could be extended to backend)
                          setState(() => _typingIndicators = value);
                          HapticFeedback.lightImpact();
                          _showSuccessMessage('Typing indicators ${value ? 'enabled' : 'disabled'}');
                        },
                        activeColor: AppColors.systemBlue,
                      ),
                    ),
                    _buildDivider(isDark),
                    _buildSettingsTile(
                      'Sound Effects',
                      isDark,
                      icon: CupertinoIcons.speaker_2_fill,
                      trailing: Switch(
                        value: _soundEffects,
                        onChanged: _isUpdatingSettings ? null : (value) {
                          _updateNotificationSetting('sounds', value);
                        },
                        activeColor: AppColors.systemBlue,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Support Section
                _buildSettingsSection(
                  isDark,
                  children: [
                    _buildSettingsTile(
                      'Help & Support',
                      isDark,
                      icon: CupertinoIcons.question_circle_fill,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _showHelp();
                      },
                    ),
                    _buildDivider(isDark),
                    _buildSettingsTile(
                      'About',
                      isDark,
                      icon: CupertinoIcons.info_circle_fill,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _showAbout();
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Account Section
                _buildSettingsSection(
                  isDark,
                  children: [
                    _buildSettingsTile(
                      'Sign Out',
                      isDark,
                      icon: CupertinoIcons.square_arrow_right,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _signOut();
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Loading Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
            ),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          
          const SizedBox(width: 20),
          
          // Loading User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Loading Name
                Container(
                  width: double.infinity,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Loading Username/Phone and Status
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Loading Username
                          Container(
                            width: 120,
                            height: 16,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          
                          const SizedBox(height: 6),
                          
                          // Loading Status
                          Container(
                            width: 80,
                            height: 14,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Loading Edit Button
                    Container(
                      width: 50,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(bool isDark) {
    final displayName = _userProfile?['displayName'] ?? 'Unknown User';
    final username = _userProfile?['username'] ?? '';
    final phoneNumber = _userProfile?['phoneNumber'] ?? '';
    final avatarUrl = _userProfile?['avatarUrl'];
    final isOnline = _userProfile?['isOnline'] == true;
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Profile Picture with Online Indicator
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isOnline ? AppColors.systemGreen : AppColors.systemBlue.withOpacity(0.3),
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: avatarUrl != null
                      ? CachedNetworkImage(
                          imageUrl: avatarUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppColors.systemBlue.withOpacity(0.1),
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.systemBlue.withOpacity(0.15),
                            child: Center(
                              child: Text(
                                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                style: GoogleFonts.inter(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.systemBlue,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.systemBlue.withOpacity(0.15),
                          child: Center(
                            child: Text(
                              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                              style: GoogleFonts.inter(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                color: AppColors.systemBlue,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              // Online Indicator Dot
              if (isOnline)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.systemGreen,
                      border: Border.all(
                        color: isDark ? AppColors.darkSecondaryBackground : AppColors.lightSecondaryBackground,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(width: 20),
          
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name
                Text(
                  displayName,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 8),
                
                // Username/Phone and Status Row
                Row(
                  children: [
                    // Username or Phone
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (username.isNotEmpty)
                            Text(
                              '@$username',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.systemBlue,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          else if (phoneNumber.isNotEmpty)
                            Text(
                              phoneNumber,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.systemGray,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          
                          const SizedBox(height: 4),
                          
                          // Status Text
                          Text(
                            isOnline ? 'Online now' : 'Last seen recently',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: isOnline ? AppColors.systemGreen : AppColors.systemGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Edit Profile Button
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _showEditProfileDialog();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.systemBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.systemBlue.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Edit',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.systemBlue,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(String title, bool isDark, {IconData? icon, Widget? trailing, VoidCallback? onTap}) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: AppColors.systemBlue,
                size: 22,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                ),
              ),
            ),
            if (trailing != null) trailing,
            if (onTap != null && trailing == null)
              Icon(
                CupertinoIcons.chevron_right,
                color: AppColors.systemGray,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(bool isDark, {required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: children),
    );
  }

  Widget _buildThemeToggle(AppThemeMode appThemeMode, bool isDark) {
    return Switch(
      value: appThemeMode == AppThemeMode.dark,
      onChanged: (value) {
        ref.read(themeProvider.notifier).setTheme(
          value ? AppThemeMode.dark : AppThemeMode.light,
        );
        HapticFeedback.lightImpact();
      },
      activeColor: AppColors.systemBlue,
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 0.5,
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
      margin: const EdgeInsets.only(left: 16),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Help & Support', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: Text(
          'Need help with Liora?\n\n• Swipe left on messages for options\n• Pull down to refresh chat list\n• Tap profile picture to view media\n• Long press messages for reactions\n\nFor more help, contact support.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it', style: GoogleFonts.inter(color: AppColors.systemBlue)),
          ),
        ],
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('About', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: Text(
          'Liora — fun, minimal messaging for our uni group.\nVersion 1.0.0\n\nBuilt with Flutter 💙',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: GoogleFonts.inter(color: AppColors.systemBlue)),
          ),
        ],
      ),
    );
  }
}

// Edit Profile Bottom Sheet Widget
class _EditProfileBottomSheet extends StatefulWidget {
  final Map<String, dynamic>? userProfile;
  final Function(Map<String, dynamic>) onProfileUpdated;

  const _EditProfileBottomSheet({
    required this.userProfile,
    required this.onProfileUpdated,
  });

  @override
  State<_EditProfileBottomSheet> createState() => _EditProfileBottomSheetState();
}

class _EditProfileBottomSheetState extends State<_EditProfileBottomSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final MediaService _mediaService = MediaService();
  
  bool _isLoading = false;
  bool _isUploadingImage = false;
  String? _selectedImagePath;
  String? _newAvatarUrl;

  @override
  void initState() {
    super.initState();
    _apiService.initialize();
    
    // Pre-fill with current user data
    if (widget.userProfile != null) {
      _nameController.text = widget.userProfile!['displayName'] ?? '';
      _usernameController.text = widget.userProfile!['username'] ?? '';
      _bioController.text = widget.userProfile!['bio'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _selectProfilePhoto() async {
    HapticFeedback.lightImpact();
    
    // Show iOS-style action sheet for photo selection
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(
          'Update Profile Photo',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        message: Text(
          'Choose how you\'d like to update your profile picture',
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
                  CupertinoIcons.camera,
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
                  CupertinoIcons.photo,
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
      setState(() => _isUploadingImage = true);
      
      MediaResult<String> result;
      
      if (source == ImageSource.camera) {
        result = await _mediaService.takePhoto();
      } else {
        result = await _mediaService.pickImageFromLibrary();
      }
      
      if (result.isSuccess && result.data != null) {
        setState(() {
          _selectedImagePath = result.data;
          // Generate new avatar URL (in production, you'd upload to cloud storage)
          _newAvatarUrl = 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(_nameController.text.trim())}&size=200&background=6366f1&color=ffffff&updated=${DateTime.now().millisecondsSinceEpoch}';
        });
        HapticFeedback.lightImpact();
      } else if (result.isCancelled) {
        // User cancelled, do nothing
      } else {
        _showError(result.error ?? 'Failed to select image. Please try again.');
      }
    } catch (e) {
      _showError('Error selecting image: ${e.toString()}');
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();
    
    try {
      // Prepare update data
      final updateData = <String, String?>{};
      
      final newDisplayName = _nameController.text.trim();
      final newUsername = _usernameController.text.trim();
      final newBio = _bioController.text.trim();
      
      if (newDisplayName != widget.userProfile?['displayName']) {
        updateData['displayName'] = newDisplayName;
      }
      
      if (newUsername != widget.userProfile?['username']) {
        updateData['username'] = newUsername.isNotEmpty ? newUsername : null;
      }
      
      if (newBio != (widget.userProfile?['bio'] ?? '')) {
        updateData['bio'] = newBio.isNotEmpty ? newBio : null;
      }
      
      if (_newAvatarUrl != null) {
        updateData['avatarUrl'] = _newAvatarUrl;
      }
      
      // Only make API call if there are changes
      if (updateData.isNotEmpty) {
        final result = await _apiService.updateProfile(
          displayName: updateData['displayName'],
          username: updateData['username'],
          bio: updateData['bio'],
          avatarUrl: updateData['avatarUrl'],
        );
        
        if (result.success) {
          // Update the profile data
          final updatedProfile = Map<String, dynamic>.from(widget.userProfile ?? {});
          updatedProfile.addAll(result.data ?? {});
          
          // Call the callback to update parent widget
          widget.onProfileUpdated(updatedProfile);
          
          // Show success and close
          HapticFeedback.lightImpact();
          Navigator.of(context).pop();
          
          // Show success message
          _showSuccessMessage('Profile updated successfully!');
        } else {
          _showError(result.error ?? 'Failed to update profile');
        }
      } else {
        // No changes made
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showError('Error updating profile: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessMessage(String message) {
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
            onPressed: () => Navigator.of(context).pop(),
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

  void _showError(String message) {
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
            onPressed: () => Navigator.of(context).pop(),
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
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.systemGray.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Edit Profile',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    child: _isLoading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.systemBlue),
                            ),
                          )
                        : Text(
                            'Save',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: AppColors.systemBlue,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Profile Photo Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: _selectProfilePhoto,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.systemBlue.withOpacity(0.3),
                              width: 3,
                            ),
                          ),
                          child: ClipOval(
                            child: _selectedImagePath != null
                                ? Image.file(
                                    File(_selectedImagePath!),
                                    fit: BoxFit.cover,
                                  )
                                : widget.userProfile?['avatarUrl'] != null
                                    ? CachedNetworkImage(
                                        imageUrl: widget.userProfile!['avatarUrl'],
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(
                                          color: AppColors.systemBlue.withOpacity(0.1),
                                          child: const Center(
                                            child: SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) => Container(
                                          color: AppColors.systemBlue.withOpacity(0.15),
                                          child: Center(
                                            child: Text(
                                              widget.userProfile?['displayName']?.isNotEmpty == true 
                                                  ? widget.userProfile!['displayName'][0].toUpperCase() 
                                                  : '?',
                                              style: GoogleFonts.inter(
                                                fontSize: 32,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.systemBlue,
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    : Container(
                                        color: AppColors.systemBlue.withOpacity(0.15),
                                        child: Center(
                                          child: Text(
                                            widget.userProfile?['displayName']?.isNotEmpty == true 
                                                ? widget.userProfile!['displayName'][0].toUpperCase() 
                                                : '?',
                                            style: GoogleFonts.inter(
                                              fontSize: 32,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.systemBlue,
                                            ),
                                          ),
                                        ),
                                      ),
                          ),
                        ),
                      ),
                      
                      // Camera icon
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _selectProfilePhoto,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.systemBlue,
                              border: Border.all(
                                color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                                width: 2,
                              ),
                            ),
                            child: _isUploadingImage
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(
                                    CupertinoIcons.camera,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tap to change photo',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.systemGray,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Form Fields
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Display Name Field
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Display Name',
                          labelStyle: GoogleFonts.inter(
                            color: isDark ? Colors.white70 : AppColors.darkBackground.withOpacity(0.7),
                          ),
                          hintText: 'Enter your display name',
                          hintStyle: GoogleFonts.inter(
                            color: isDark ? Colors.white54 : AppColors.darkBackground.withOpacity(0.5),
                          ),
                          prefixIcon: Icon(
                            CupertinoIcons.person,
                            color: isDark ? Colors.white70 : AppColors.darkBackground.withOpacity(0.7),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.systemBlue,
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
                            return 'Display name is required';
                          }
                          if (value.trim().length < 2) {
                            return 'Display name must be at least 2 characters';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Username Field
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
                            CupertinoIcons.at,
                            color: isDark ? Colors.white70 : AppColors.darkBackground.withOpacity(0.7),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.systemBlue,
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
                      
                      const SizedBox(height: 20),
                      
                      // Bio Field
                      TextFormField(
                        controller: _bioController,
                        maxLines: 3,
                        maxLength: 160,
                        decoration: InputDecoration(
                          labelText: 'Bio (Optional)',
                          labelStyle: GoogleFonts.inter(
                            color: isDark ? Colors.white70 : AppColors.darkBackground.withOpacity(0.7),
                          ),
                          hintText: 'Tell us about yourself...',
                          hintStyle: GoogleFonts.inter(
                            color: isDark ? Colors.white54 : AppColors.darkBackground.withOpacity(0.5),
                          ),
                          prefixIcon: Icon(
                            CupertinoIcons.doc_text,
                            color: isDark ? Colors.white70 : AppColors.darkBackground.withOpacity(0.7),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.systemBlue,
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
                          if (value != null && value.length > 160) {
                            return 'Bio cannot exceed 160 characters';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
