import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/navigation/app_router.dart';

class ContactInfoScreen extends StatefulWidget {
  final String contactName;
  final String contactAvatarUrl;
  final bool? initialMuteState;
  final bool? initialBlockState;
  
  const ContactInfoScreen({
    super.key,
    required this.contactName,
    required this.contactAvatarUrl,
    this.initialMuteState,
    this.initialBlockState,
  });

  @override
  State<ContactInfoScreen> createState() => _ContactInfoScreenState();
}

class _ContactInfoScreenState extends State<ContactInfoScreen> {
  late bool _isMuted;
  late bool _isBlocked;

  @override
  void initState() {
    super.initState();
    _isMuted = widget.initialMuteState ?? false;
    _isBlocked = widget.initialBlockState ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        leading: IconButton(
          onPressed: () {
            if (Navigator.canPop(context)) {
              context.pop();
            } else {
              context.go(AppRouter.messages);
            }
          },
          icon: Icon(
            CupertinoIcons.back,
            color: AppColors.systemBlue,
            size: 22,
          ),
        ),
        title: Text(
          'Contact',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          
          // Profile Header
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: CachedNetworkImageProvider(widget.contactAvatarUrl),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.contactName,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'online',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppColors.systemGreen,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Action Buttons
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSecondaryBackground : AppColors.lightSecondaryBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildActionTile(
                  'Message',
                  CupertinoIcons.chat_bubble,
                  AppColors.systemBlue,
                  () {
                    HapticFeedback.lightImpact();
                    context.pop();
                  },
                  isDark,
                ),
                _buildDivider(isDark),
                _buildActionTile(
                  'Audio Call',
                  CupertinoIcons.phone,
                  AppColors.systemBlue,
                  () {
                    HapticFeedback.lightImpact();
                    _makeAudioCall();
                  },
                  isDark,
                ),
                _buildDivider(isDark),
                _buildActionTile(
                  'Video Call',
                  CupertinoIcons.video_camera,
                  AppColors.systemBlue,
                  () {
                    HapticFeedback.lightImpact();
                    _makeVideoCall();
                  },
                  isDark,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Settings Section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSecondaryBackground : AppColors.lightSecondaryBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildToggleTile(
                  'Mute Notifications',
                  CupertinoIcons.bell_slash,
                  _isMuted,
                  (value) {
                    setState(() => _isMuted = value);
                    HapticFeedback.lightImpact();
                    _toggleMute(value);
                  },
                  isDark,
                ),
                _buildDivider(isDark),
                _buildActionTile(
                  'Search in Conversation',
                  CupertinoIcons.search,
                  AppColors.systemBlue,
                  () {
                    HapticFeedback.lightImpact();
                    _searchInConversation();
                  },
                  isDark,
                ),
                _buildDivider(isDark),
                _buildActionTile(
                  'Media & Files',
                  CupertinoIcons.photo,
                  AppColors.systemBlue,
                  () {
                    HapticFeedback.lightImpact();
                    _showMediaFiles();
                  },
                  isDark,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Danger Zone
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSecondaryBackground : AppColors.lightSecondaryBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildActionTile(
                  _isBlocked ? 'Unblock Contact' : 'Block Contact',
                  _isBlocked ? CupertinoIcons.checkmark_circle : CupertinoIcons.xmark_circle,
                  AppColors.systemRed,
                  () {
                    HapticFeedback.lightImpact();
                    if (_isBlocked) {
                      _showUnblockDialog();
                    } else {
                      _showBlockDialog();
                    }
                  },
                  isDark,
                ),
                _buildDivider(isDark),
                _buildActionTile(
                  'Report Contact',
                  CupertinoIcons.exclamationmark_triangle,
                  AppColors.systemRed,
                  () {
                    HapticFeedback.lightImpact();
                    _showReportDialog();
                  },
                  isDark,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildActionTile(String title, IconData icon, Color iconColor, VoidCallback onTap, bool isDark) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 17,
          color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
        ),
      ),
      trailing: Icon(
        CupertinoIcons.chevron_right,
        color: AppColors.systemGray,
        size: 20,
      ),
      onTap: onTap,
    );
  }

  Widget _buildToggleTile(String title, IconData icon, bool value, ValueChanged<bool> onChanged, bool isDark) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: AppColors.systemBlue, size: 22),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 17,
          color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.systemBlue,
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 0.5,
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
      margin: const EdgeInsets.only(left: 56),
    );
  }

  void _makeAudioCall() {
    // TODO: Implement audio call
    _showComingSoonAlert('Audio Call');
  }

  void _makeVideoCall() {
    // TODO: Implement video call
    _showComingSoonAlert('Video Call');
  }

  void _toggleMute(bool mute) {
    HapticFeedback.lightImpact();
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          mute ? 'Notifications Muted' : 'Notifications Enabled',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          mute 
              ? 'You will no longer receive notifications for messages from ${widget.contactName}.'
              : 'You will now receive notifications for messages from ${widget.contactName}.',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.inter(
                fontSize: 17,
                color: AppColors.systemBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _searchInConversation() {
    // Close contact info and show coming soon
    context.pop();
    _showComingSoonAlert('Search in Conversation');
  }

  void _showMediaFiles() {
    // TODO: Implement media viewer
    _showComingSoonAlert('Media & Files');
  }

  void _showBlockDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Block ${widget.contactName}?',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'You will no longer receive messages from this contact.',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontSize: 17,
                color: AppColors.systemBlue,
              ),
            ),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _blockContact();
            },
            child: Text(
              'Block',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Report ${widget.contactName}?',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This will report the contact for inappropriate behavior.',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontSize: 17,
                color: AppColors.systemBlue,
              ),
            ),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _reportContact();
            },
            child: Text(
              'Report',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUnblockDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Unblock ${widget.contactName}?',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'You will be able to receive messages from this contact again.',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontSize: 17,
                color: AppColors.systemBlue,
              ),
            ),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              _unblockContact();
            },
            child: Text(
              'Unblock',
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

  void _blockContact() {
    setState(() => _isBlocked = true);
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Contact Blocked',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          '${widget.contactName} has been blocked. You will no longer receive messages from this contact.',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.inter(
                fontSize: 17,
                color: AppColors.systemBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _unblockContact() {
    setState(() => _isBlocked = false);
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Contact Unblocked',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          '${widget.contactName} has been unblocked. You can now receive messages from this contact.',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.inter(
                fontSize: 17,
                color: AppColors.systemBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _reportContact() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.contactName} has been reported', style: GoogleFonts.inter()),
        backgroundColor: AppColors.systemBlue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showComingSoonAlert(String feature) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Coming Soon',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          '$feature feature will be available in a future update.',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.inter(
                fontSize: 17,
                color: AppColors.systemBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

