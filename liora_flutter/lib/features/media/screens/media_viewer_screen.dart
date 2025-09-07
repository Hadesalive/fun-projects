import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/app_colors.dart';

class MediaViewerScreen extends StatefulWidget {
  final String mediaUrl;
  final String mediaType;

  const MediaViewerScreen({
    super.key,
    required this.mediaUrl,
    required this.mediaType,
  });

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late VideoPlayerController? _videoController;
  bool _showControls = true;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    if (widget.mediaType == 'video') {
      _initializeVideo();
    }
    
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.mediaUrl));
    await _videoController!.initialize();
    setState(() {
      _isVideoInitialized = true;
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    
    if (_showControls) {
      _fadeController.forward();
      // Auto-hide controls after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showControls = false;
          });
          _fadeController.reverse();
        }
      });
    } else {
      _fadeController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Media Content
          _buildMediaContent(),
          
          // Controls Overlay
          if (_showControls) _buildControlsOverlay(),
        ],
      ),
    );
  }

  Widget _buildMediaContent() {
    if (widget.mediaType == 'video') {
      return _buildVideoPlayer();
    } else {
      return _buildImageViewer();
    }
  }

  Widget _buildVideoPlayer() {
    if (!_isVideoInitialized || _videoController == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.systemBlue,
        ),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: GestureDetector(
          onTap: _toggleControls,
          child: VideoPlayer(_videoController!),
        ),
      ),
    );
  }

  Widget _buildImageViewer() {
    return GestureDetector(
      onTap: _toggleControls,
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: CachedNetworkImage(
            imageUrl: widget.mediaUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(
                color: AppColors.systemBlue,
              ),
            ),
            errorWidget: (context, url, error) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.imageOff,
                    color: Colors.white,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load image',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
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

  Widget _buildControlsOverlay() {
    return FadeTransition(
      opacity: _fadeController,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
              Colors.transparent,
              Colors.black.withOpacity(0.7),
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Controls
              _buildTopControls(),
              
              const Spacer(),
              
              // Bottom Controls
              _buildBottomControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopControls() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.arrowLeft,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          
          const Spacer(),
          
          // Share Button
          GestureDetector(
            onTap: _shareMedia,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.share,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // More Options
          GestureDetector(
            onTap: _showMoreOptions,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.moreHorizontal,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Video Controls (if video)
          if (widget.mediaType == 'video' && _videoController != null) ...[
            GestureDetector(
              onTap: _toggleVideoPlayback,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _videoController!.value.isPlaying
                      ? LucideIcons.pause
                      : LucideIcons.play,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Video Progress
            Expanded(
              child: VideoProgressIndicator(
                _videoController!,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: AppColors.systemBlue,
                  backgroundColor: Colors.white.withOpacity(0.3),
                ),
              ),
            ),
          ] else ...[
            // Image Info
            Expanded(
              child: Text(
                'Tap to zoom • Pinch to scale',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          
          const SizedBox(width: 16),
          
          // Download Button
          GestureDetector(
            onTap: _downloadMedia,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.download,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleVideoPlayback() {
    HapticFeedback.lightImpact();
    if (_videoController!.value.isPlaying) {
      _videoController!.pause();
    } else {
      _videoController!.play();
    }
  }

  void _shareMedia() {
    HapticFeedback.lightImpact();
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality coming soon'),
        backgroundColor: AppColors.systemBlue,
      ),
    );
  }

  void _downloadMedia() {
    HapticFeedback.lightImpact();
    // TODO: Implement download functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Download functionality coming soon'),
        backgroundColor: AppColors.systemGreen,
      ),
    );
  }

  void _showMoreOptions() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Options
            ListTile(
              leading: const Icon(LucideIcons.download, color: Colors.white),
              title: Text(
                'Download',
                style: GoogleFonts.inter(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _downloadMedia();
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.share, color: Colors.white),
              title: Text(
                'Share',
                style: GoogleFonts.inter(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _shareMedia();
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.copy, color: Colors.white),
              title: Text(
                'Copy Link',
                style: GoogleFonts.inter(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _copyLink();
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.flag, color: Colors.white),
              title: Text(
                'Report',
                style: GoogleFonts.inter(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _reportMedia();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _copyLink() {
    HapticFeedback.lightImpact();
    // TODO: Copy link to clipboard
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copied to clipboard'),
        backgroundColor: AppColors.systemGreen,
      ),
    );
  }

  void _reportMedia() {
    HapticFeedback.lightImpact();
    // TODO: Implement report functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report submitted'),
        backgroundColor: AppColors.systemRed,
      ),
    );
  }
}
