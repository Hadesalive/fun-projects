import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class TypingIndicator extends StatefulWidget {
  final String avatarUrl;

  const TypingIndicator({
    super.key,
    required this.avatarUrl,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundImage: CachedNetworkImageProvider(widget.avatarUrl),
          ),
          
          const SizedBox(width: 8),
          
          // Typing bubble
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark 
                  ? AppColors.darkSecondaryBackground 
                  : AppColors.systemGray6,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TypingDot(
                  animationController: _animationController,
                  delay: 0,
                  isDark: isDark,
                ),
                const SizedBox(width: 4),
                _TypingDot(
                  animationController: _animationController,
                  delay: 200,
                  isDark: isDark,
                ),
                const SizedBox(width: 4),
                _TypingDot(
                  animationController: _animationController,
                  delay: 400,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingDot extends StatelessWidget {
  final AnimationController animationController;
  final int delay;
  final bool isDark;

  const _TypingDot({
    required this.animationController,
    required this.delay,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        final progress = (animationController.value * 1000 - delay) / 300;
        final opacity = _calculateOpacity(progress);
        final scale = _calculateScale(progress);
        
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: (isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText)
                  .withOpacity(opacity),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  double _calculateOpacity(double progress) {
    if (progress < 0 || progress > 1) return 0.3;
    
    // Create a smooth fade in/out effect
    if (progress < 0.5) {
      return 0.3 + (progress * 2 * 0.7); // From 0.3 to 1.0
    } else {
      return 1.0 - ((progress - 0.5) * 2 * 0.7); // From 1.0 to 0.3
    }
  }

  double _calculateScale(double progress) {
    if (progress < 0 || progress > 1) return 0.8;
    
    // Create a subtle scale effect
    if (progress < 0.5) {
      return 0.8 + (progress * 2 * 0.2); // From 0.8 to 1.0
    } else {
      return 1.0 - ((progress - 0.5) * 2 * 0.2); // From 1.0 to 0.8
    }
  }
}
