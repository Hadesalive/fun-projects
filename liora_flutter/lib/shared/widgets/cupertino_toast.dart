import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

enum CupertinoToastType {
  success,
  error,
  warning,
  info,
}

class CupertinoToast {
  static void show(
    BuildContext context,
    String message, {
    CupertinoToastType type = CupertinoToastType.success,
    Duration duration = const Duration(seconds: 2),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => _CupertinoToastWidget(
        message: message,
        type: type,
        onDismiss: () => overlayEntry.remove(),
      ),
    );

    overlay.insert(overlayEntry);

    // Remove the toast after specified duration
    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}

class _CupertinoToastWidget extends StatefulWidget {
  final String message;
  final CupertinoToastType type;
  final VoidCallback onDismiss;

  const _CupertinoToastWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_CupertinoToastWidget> createState() => _CupertinoToastWidgetState();
}

class _CupertinoToastWidgetState extends State<_CupertinoToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getBackgroundColor() {
    switch (widget.type) {
      case CupertinoToastType.success:
        return CupertinoColors.systemGreen;
      case CupertinoToastType.error:
        return CupertinoColors.systemRed;
      case CupertinoToastType.warning:
        return CupertinoColors.systemOrange;
      case CupertinoToastType.info:
        return CupertinoColors.systemBlue;
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case CupertinoToastType.success:
        return CupertinoIcons.check_mark;
      case CupertinoToastType.error:
        return CupertinoIcons.exclamationmark_triangle;
      case CupertinoToastType.warning:
        return CupertinoIcons.exclamationmark;
      case CupertinoToastType.info:
        return CupertinoIcons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: MediaQuery.of(context).viewInsets.bottom + 50,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CupertinoPopupSurface(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _getBackgroundColor(),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    _getIcon(),
                    color: CupertinoColors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: widget.onDismiss,
                    child: const Icon(
                      CupertinoIcons.xmark,
                      color: CupertinoColors.white,
                      size: 16,
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
