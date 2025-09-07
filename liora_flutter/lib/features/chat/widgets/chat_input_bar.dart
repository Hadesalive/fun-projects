import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/media_controller.dart';

class ChatInputBar extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final ValueChanged<String>? onChanged;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    this.onChanged,
  });

  @override
  ConsumerState<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends ConsumerState<ChatInputBar>
    with TickerProviderStateMixin {
  late AnimationController _sendButtonController;
  bool _hasText = false;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _sendButtonController.dispose();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (_hasText != hasText) {
      setState(() => _hasText = hasText);
      if (hasText) {
        _sendButtonController.forward();
      } else {
        _sendButtonController.reverse();
      }
    }
  }

  void _handleSendTap() {
    if (_hasText) {
      widget.onSend();
      HapticFeedback.lightImpact();
    }
  }

  void _handleMicPress() {
    final mediaController = ref.read(mediaControllerProvider.notifier);
    mediaController.startAudioRecording(context);
  }

  void _handleMicRelease() {
    final mediaController = ref.read(mediaControllerProvider.notifier);
    final mediaState = ref.read(mediaControllerProvider);
    
    if (mediaState.isRecording) {
      mediaController.stopAudioRecording(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutQuart,
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkBackground : AppColors.lightBackground)
            .withOpacity(0.95),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 0.5,
          ),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  12,
                  12,
                  12,
                  keyboardHeight > 0 ? 2 : (bottomPadding > 0 ? 2 : 2),
                ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Attachment button
                  Container(
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(
                      color: AppColors.systemBlue,
                      shape: BoxShape.circle,
                    ),
                    child: CupertinoButton(
                      onPressed: () {
                        final mediaController = ref.read(mediaControllerProvider.notifier);
                        mediaController.showAttachmentOptions(context);
                      },
                      padding: EdgeInsets.zero,
                      minSize: 0,
                      child: Icon(
                        CupertinoIcons.plus,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Text input field
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark 
                            ? AppColors.darkSecondaryBackground 
                            : AppColors.lightSecondaryBackground,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: widget.focusNode.hasFocus
                              ? AppColors.systemBlue
                              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Text field
                          Expanded(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxHeight: 100,
                              ),
                              child: CupertinoTextField(
                                controller: widget.controller,
                                focusNode: widget.focusNode,
                                maxLines: null,
                                minLines: 1,
                                textCapitalization: TextCapitalization.sentences,
                                placeholder: 'Text Message',
                                placeholderStyle: GoogleFonts.inter(
                                  color: AppColors.systemGray,
                                  fontSize: 17,
                                ),
                                style: GoogleFonts.inter(
                                  fontSize: 17,
                                  color: isDark 
                                      ? AppColors.darkPrimaryText 
                                      : AppColors.lightPrimaryText,
                                ),
                                decoration: null,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                onChanged: widget.onChanged,
                              ),
                            ),
                          ),
                          
                          // Camera button
                          Padding(
                            padding: const EdgeInsets.only(right: 4, bottom: 4),
                            child: _InputButton(
                              icon: CupertinoIcons.camera_fill,
                              onTap: () {
                                final mediaController = ref.read(mediaControllerProvider.notifier);
                                mediaController.showCameraOptions(context);
                              },
                              size: 20,
                              padding: const EdgeInsets.all(4),
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Send/Mic button
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: _hasText
                        ? _SendButton(
                            key: const ValueKey('send'),
                            onTap: _handleSendTap,
                            controller: _sendButtonController,
                          )
                        : _MicButton(
                            key: const ValueKey('mic'),
                            onPress: _handleMicPress,
                            onRelease: _handleMicRelease,
                            isRecording: ref.watch(mediaControllerProvider).isRecording,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InputButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final EdgeInsets padding;
  final bool isDark;

  const _InputButton({
    required this.icon,
    required this.onTap,
    this.size = 24,
    this.padding = const EdgeInsets.all(6),
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      onPressed: onTap,
      padding: padding,
      minSize: 0,
      child: Icon(
        icon,
        size: size,
        color: AppColors.systemBlue,
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final VoidCallback onTap;
  final AnimationController controller;

  const _SendButton({
    super.key,
    required this.onTap,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      onPressed: onTap,
      padding: EdgeInsets.zero,
      minSize: 0,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return Transform.scale(
            scale: 0.9 + (controller.value * 0.1),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.systemBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.arrow_up,
                color: Colors.white,
                size: 20,
              ),
            ),
          );
        },
      ),
    ).animate().scale(delay: 100.ms);
  }
}

class _MicButton extends StatelessWidget {
  final VoidCallback onPress;
  final VoidCallback onRelease;
  final bool isRecording;

  const _MicButton({
    super.key,
    required this.onPress,
    required this.onRelease,
    required this.isRecording,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onPress(),
      onTapUp: (_) => onRelease(),
      onTapCancel: onRelease,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isRecording ? AppColors.systemRed : AppColors.systemGray,
          shape: BoxShape.circle,
        ),
        child: Icon(
          CupertinoIcons.mic_fill,
          color: Colors.white,
          size: 18,
        ),
      ).animate(target: isRecording ? 1 : 0).scaleXY(end: 1.1),
    );
  }
}