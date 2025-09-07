import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../core/navigation/app_router.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _notifications = true;
  bool _readReceipts = true;
  bool _typingIndicators = true;
  bool _soundEffects = true;
  
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: _buildProfileHeader(isDark),
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
                    _buildSettingsTile(
                      'Notifications',
                      isDark,
                      icon: CupertinoIcons.bell_fill,
                      trailing: Switch(
                        value: _notifications,
                        onChanged: (value) {
                          setState(() => _notifications = value);
                          HapticFeedback.lightImpact();
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
                        onChanged: (value) {
                          setState(() => _readReceipts = value);
                          HapticFeedback.lightImpact();
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
                        onChanged: (value) {
                          setState(() => _typingIndicators = value);
                          HapticFeedback.lightImpact();
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
                        onChanged: (value) {
                          setState(() => _soundEffects = value);
                          HapticFeedback.lightImpact();
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(bool isDark) {
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: AppColors.systemBlue.withOpacity(0.15),
          child: const Text('🧊', style: TextStyle(fontSize: 28)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Name',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '@handle',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColors.systemGray,
                ),
              ),
            ],
          ),
        ),
      ],
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
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSecondaryBackground : AppColors.lightSecondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.5,
        ),
      ),
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
