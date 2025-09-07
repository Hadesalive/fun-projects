import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/media_service.dart';
import '../../../core/constants/app_colors.dart';

/// Media controller for handling camera, microphone, and file operations in chat
class MediaController extends StateNotifier<MediaState> {
  final MediaService _mediaService;

  MediaController(this._mediaService) : super(MediaState.initial());

  // MARK: - Camera Functions

  /// Show camera options (photo/video)
  Future<void> showCameraOptions(BuildContext context) async {
    HapticFeedback.lightImpact();
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(
          'Camera',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.systemGray,
          ),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              takePhoto(context);
            },
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.camera,
                  color: AppColors.systemBlue,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Take Photo',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    color: AppColors.systemBlue,
                  ),
                ),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              takeVideo(context);
            },
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.video_camera,
                  color: AppColors.systemBlue,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Record Video',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    color: AppColors.systemBlue,
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
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.systemBlue,
            ),
          ),
        ),
      ),
    );
  }

  /// Take a photo
  Future<void> takePhoto(BuildContext context) async {
    state = state.copyWith(isLoading: true);
    
    final result = await _mediaService.takePhoto();
    
    if (result.isSuccess && result.data != null) {
      state = state.copyWith(
        isLoading: false,
        lastMediaPath: result.data,
        mediaType: MediaType.image,
      );
      _showSuccessMessage(context, 'Photo captured successfully');
    } else if (result.isCancelled) {
      state = state.copyWith(isLoading: false);
    } else {
      state = state.copyWith(isLoading: false);
      _showErrorDialog(context, result.error ?? 'Failed to take photo');
    }
  }

  /// Take a video
  Future<void> takeVideo(BuildContext context) async {
    state = state.copyWith(isLoading: true);
    
    final result = await _mediaService.takeVideo();
    
    if (result.isSuccess && result.data != null) {
      state = state.copyWith(
        isLoading: false,
        lastMediaPath: result.data,
        mediaType: MediaType.video,
      );
      _showSuccessMessage(context, 'Video recorded successfully');
    } else if (result.isCancelled) {
      state = state.copyWith(isLoading: false);
    } else {
      state = state.copyWith(isLoading: false);
      _showErrorDialog(context, result.error ?? 'Failed to record video');
    }
  }

  // MARK: - Photo Library Functions

  /// Show attachment options
  Future<void> showAttachmentOptions(BuildContext context) async {
    HapticFeedback.lightImpact();
    
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(
          'Share Content',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.systemGray,
          ),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              pickImageFromLibrary(context);
            },
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.photo,
                  color: AppColors.systemBlue,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Photo Library',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    color: AppColors.systemBlue,
                  ),
                ),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              pickVideoFromLibrary(context);
            },
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.videocam,
                  color: AppColors.systemBlue,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Video Library',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    color: AppColors.systemBlue,
                  ),
                ),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              pickFiles(context);
            },
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.doc,
                  color: AppColors.systemBlue,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Files',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    color: AppColors.systemBlue,
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
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.systemBlue,
            ),
          ),
        ),
      ),
    );
  }

  /// Pick image from library
  Future<void> pickImageFromLibrary(BuildContext context) async {
    state = state.copyWith(isLoading: true);
    
    final result = await _mediaService.pickImageFromLibrary();
    
    if (result.isSuccess && result.data != null) {
      state = state.copyWith(
        isLoading: false,
        lastMediaPath: result.data,
        mediaType: MediaType.image,
      );
      _showSuccessMessage(context, 'Image selected successfully');
    } else if (result.isCancelled) {
      state = state.copyWith(isLoading: false);
    } else {
      state = state.copyWith(isLoading: false);
      _showErrorDialog(context, result.error ?? 'Failed to select image');
    }
  }

  /// Pick video from library
  Future<void> pickVideoFromLibrary(BuildContext context) async {
    state = state.copyWith(isLoading: true);
    
    final result = await _mediaService.pickVideoFromLibrary();
    
    if (result.isSuccess && result.data != null) {
      state = state.copyWith(
        isLoading: false,
        lastMediaPath: result.data,
        mediaType: MediaType.video,
      );
      _showSuccessMessage(context, 'Video selected successfully');
    } else if (result.isCancelled) {
      state = state.copyWith(isLoading: false);
    } else {
      state = state.copyWith(isLoading: false);
      _showErrorDialog(context, result.error ?? 'Failed to select video');
    }
  }

  /// Pick files
  Future<void> pickFiles(BuildContext context) async {
    state = state.copyWith(isLoading: true);
    
    final result = await _mediaService.pickFiles(allowMultiple: false);
    
    if (result.isSuccess && result.data != null && result.data!.isNotEmpty) {
      state = state.copyWith(
        isLoading: false,
        lastMediaPath: result.data!.first,
        mediaType: MediaType.file,
      );
      _showSuccessMessage(context, 'File selected successfully');
    } else if (result.isCancelled) {
      state = state.copyWith(isLoading: false);
    } else {
      state = state.copyWith(isLoading: false);
      _showErrorDialog(context, result.error ?? 'Failed to select file');
    }
  }

  // MARK: - Audio Recording Functions

  /// Start audio recording
  Future<void> startAudioRecording(BuildContext context) async {
    final result = await _mediaService.startAudioRecording();
    
    if (result.isSuccess) {
      state = state.copyWith(
        isRecording: true,
        recordingStartTime: DateTime.now(),
      );
      HapticFeedback.heavyImpact();
    } else {
      _showErrorDialog(context, result.error ?? 'Failed to start recording');
    }
  }

  /// Stop audio recording
  Future<void> stopAudioRecording(BuildContext context) async {
    if (!state.isRecording) return;
    
    final result = await _mediaService.stopAudioRecording();
    
    if (result.isSuccess && result.data != null) {
      state = state.copyWith(
        isRecording: false,
        recordingStartTime: null,
        lastMediaPath: result.data,
        mediaType: MediaType.audio,
      );
      HapticFeedback.lightImpact();
      _showSuccessMessage(context, 'Voice message recorded');
    } else {
      state = state.copyWith(
        isRecording: false,
        recordingStartTime: null,
      );
      _showErrorDialog(context, result.error ?? 'Failed to save recording');
    }
  }

  /// Cancel audio recording
  Future<void> cancelAudioRecording() async {
    await _mediaService.cancelRecording();
    state = state.copyWith(
      isRecording: false,
      recordingStartTime: null,
    );
    HapticFeedback.lightImpact();
  }

  // MARK: - Helper Methods

  /// Clear last media
  void clearLastMedia() {
    state = state.copyWith(
      lastMediaPath: null,
      mediaType: null,
    );
  }

  /// Show success message
  void _showSuccessMessage(BuildContext context, String message) {
    HapticFeedback.lightImpact();
    
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

  /// Show error dialog
  void _showErrorDialog(BuildContext context, String error) {
    HapticFeedback.heavyImpact();
    
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
          error,
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
          if (error.contains('Settings'))
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context);
                _mediaService.openAppSettings();
              },
              child: Text(
                'Settings',
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
}

// MARK: - State Management

class MediaState {
  final bool isLoading;
  final bool isRecording;
  final DateTime? recordingStartTime;
  final String? lastMediaPath;
  final MediaType? mediaType;

  const MediaState({
    required this.isLoading,
    required this.isRecording,
    this.recordingStartTime,
    this.lastMediaPath,
    this.mediaType,
  });

  factory MediaState.initial() => const MediaState(
    isLoading: false,
    isRecording: false,
  );

  MediaState copyWith({
    bool? isLoading,
    bool? isRecording,
    DateTime? recordingStartTime,
    String? lastMediaPath,
    MediaType? mediaType,
  }) {
    return MediaState(
      isLoading: isLoading ?? this.isLoading,
      isRecording: isRecording ?? this.isRecording,
      recordingStartTime: recordingStartTime ?? this.recordingStartTime,
      lastMediaPath: lastMediaPath ?? this.lastMediaPath,
      mediaType: mediaType ?? this.mediaType,
    );
  }

  Duration? get recordingDuration {
    if (recordingStartTime == null) return null;
    return DateTime.now().difference(recordingStartTime!);
  }
}

enum MediaType {
  image,
  video,
  audio,
  file,
}

// MARK: - Providers

final mediaServiceProvider = Provider<MediaService>((ref) => MediaService());

final mediaControllerProvider = StateNotifierProvider<MediaController, MediaState>(
  (ref) => MediaController(ref.read(mediaServiceProvider)),
);
