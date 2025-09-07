import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool showAvatar;
  final String? avatarUrl;

  const MessageBubble({
    super.key,
    required this.message,
    this.showAvatar = false,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: message.isMe 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar for incoming messages
          if (!message.isMe) ...[
            if (showAvatar && avatarUrl != null)
              CircleAvatar(
                radius: 16,
                backgroundImage: CachedNetworkImageProvider(avatarUrl!),
              )
            else
              const SizedBox(width: 32),
            const SizedBox(width: 8),
          ],
          
          // Message bubble
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(context),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _getBubbleColor(isDark),
                  borderRadius: _getBorderRadius(),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: message.isMe 
                      ? CrossAxisAlignment.end 
                      : CrossAxisAlignment.start,
                  children: [
                    // Message text
                    Text(
                      message.content.text ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: _getTextColor(isDark),
                        height: 1.3,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Timestamp and status
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(message.createdAt),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: _getTimestampColor(isDark),
                          ),
                        ),
                        if (message.isMe) ...[
                          const SizedBox(width: 4),
                          _MessageStatusIcon(status: message.status),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Spacing for outgoing messages
          if (message.isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Color _getBubbleColor(bool isDark) {
    if (message.isMe) {
      return AppColors.systemBlue;
    } else {
      return isDark 
          ? AppColors.darkSecondaryBackground 
          : AppColors.systemGray6;
    }
  }

  Color _getTextColor(bool isDark) {
    if (message.isMe) {
      return Colors.white;
    } else {
      return isDark 
          ? AppColors.darkPrimaryText 
          : AppColors.lightPrimaryText;
    }
  }

  Color _getTimestampColor(bool isDark) {
    if (message.isMe) {
      return Colors.white.withOpacity(0.8);
    } else {
      return isDark 
          ? AppColors.darkSecondaryText 
          : AppColors.lightSecondaryText;
    }
  }

  BorderRadius _getBorderRadius() {
    const radius = Radius.circular(18);
    const smallRadius = Radius.circular(4);
    
    if (message.isMe) {
      return const BorderRadius.only(
        topLeft: radius,
        topRight: radius,
        bottomLeft: radius,
        bottomRight: smallRadius,
      );
    } else {
      return const BorderRadius.only(
        topLeft: radius,
        topRight: radius,
        bottomLeft: smallRadius,
        bottomRight: radius,
      );
    }
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _MessageOptionsSheet(message: message),
    );
  }
}

class _MessageStatusIcon extends StatelessWidget {
  final MessageStatus status;

  const _MessageStatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    Widget icon;
    Color color;

    switch (status) {
      case MessageStatus.sending:
        icon = SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.white.withOpacity(0.8),
            ),
          ),
        );
        color = Colors.transparent;
        break;
      case MessageStatus.sent:
        icon = const Icon(LucideIcons.check, size: 14);
        color = Colors.white.withOpacity(0.8);
        break;
      case MessageStatus.delivered:
        icon = const Icon(LucideIcons.checkCheck, size: 14);
        color = Colors.white.withOpacity(0.8);
        break;
      case MessageStatus.read:
        icon = const Icon(LucideIcons.checkCheck, size: 14);
        color = AppColors.systemBlue;
        break;
      case MessageStatus.failed:
        icon = const Icon(LucideIcons.alertCircle, size: 14);
        color = AppColors.systemRed;
        break;
    }

    return IconTheme(
      data: IconThemeData(color: color),
      child: icon,
    );
  }
}

class _MessageOptionsSheet extends StatelessWidget {
  final Message message;

  const _MessageOptionsSheet({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 5,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: AppColors.systemGray4,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          const SizedBox(height: 20),
          
          // Message preview
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkTertiary : AppColors.systemGray6,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.content.text ?? '',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Options
          _OptionTile(
            icon: LucideIcons.reply,
            title: 'Reply',
            onTap: () => Navigator.pop(context),
          ),
          _OptionTile(
            icon: LucideIcons.copy,
            title: 'Copy',
            onTap: () => Navigator.pop(context),
          ),
          _OptionTile(
            icon: LucideIcons.share,
            title: 'Forward',
            onTap: () => Navigator.pop(context),
          ),
          if (message.isMe)
            _OptionTile(
              icon: LucideIcons.trash2,
              title: 'Delete',
              onTap: () => Navigator.pop(context),
              isDestructive: true,
            ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? AppColors.systemRed : null,
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          color: isDestructive ? AppColors.systemRed : null,
        ),
      ),
      onTap: onTap,
    );
  }
}
