import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Comprehensive media service following Apple and Android best practices
/// Handles camera, microphone, and file access with proper privacy permissions
class MediaService {
  static final MediaService _instance = MediaService._internal();
  factory MediaService() => _instance;
  MediaService._internal();

  final ImagePicker _imagePicker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final Uuid _uuid = const Uuid();

  // MARK: - Permission Management

  /// Check if camera permission is granted
  Future<bool> hasCameraPermission() async {
    final status = await ph.Permission.camera.status;
    return status.isGranted;
  }

  /// Check if microphone permission is granted
  Future<bool> hasMicrophonePermission() async {
    final status = await ph.Permission.microphone.status;
    return status.isGranted;
  }

  /// Check if photo library permission is granted
  Future<bool> hasPhotoLibraryPermission() async {
    final status = await ph.Permission.photos.status;
    return status.isGranted;
  }

  /// Check if storage permission is granted (Android)
  Future<bool> hasStoragePermission() async {
    if (Platform.isIOS) return true; // iOS handles this automatically
    
    if (Platform.isAndroid) {
      final androidInfo = await _getAndroidVersion();
      if (androidInfo >= 33) {
        // Android 13+ uses granular permissions
        final images = await ph.Permission.photos.status;
        final videos = await ph.Permission.videos.status;
        return images.isGranted && videos.isGranted;
      } else {
        // Android 12 and below
        final status = await ph.Permission.storage.status;
        return status.isGranted;
      }
    }
    
    return false;
  }

  /// Request camera permission with proper messaging
  Future<PermissionResult> requestCameraPermission() async {
    final status = await ph.Permission.camera.request();
    
    switch (status) {
      case ph.PermissionStatus.granted:
        return PermissionResult.granted;
      case ph.PermissionStatus.denied:
        return PermissionResult.denied;
      case ph.PermissionStatus.permanentlyDenied:
        return PermissionResult.permanentlyDenied;
      case ph.PermissionStatus.restricted:
        return PermissionResult.restricted;
      default:
        return PermissionResult.denied;
    }
  }

  /// Request microphone permission with proper messaging
  Future<PermissionResult> requestMicrophonePermission() async {
    final status = await ph.Permission.microphone.request();
    
    switch (status) {
      case ph.PermissionStatus.granted:
        return PermissionResult.granted;
      case ph.PermissionStatus.denied:
        return PermissionResult.denied;
      case ph.PermissionStatus.permanentlyDenied:
        return PermissionResult.permanentlyDenied;
      case ph.PermissionStatus.restricted:
        return PermissionResult.restricted;
      default:
        return PermissionResult.denied;
    }
  }

  /// Request photo library permission
  Future<PermissionResult> requestPhotoLibraryPermission() async {
    final status = await ph.Permission.photos.request();
    
    switch (status) {
      case ph.PermissionStatus.granted:
        return PermissionResult.granted;
      case ph.PermissionStatus.denied:
        return PermissionResult.denied;
      case ph.PermissionStatus.permanentlyDenied:
        return PermissionResult.permanentlyDenied;
      case ph.PermissionStatus.restricted:
        return PermissionResult.restricted;
      default:
        return PermissionResult.denied;
    }
  }

  /// Request storage permission (Android)
  Future<PermissionResult> requestStoragePermission() async {
    if (Platform.isIOS) return PermissionResult.granted;
    
    if (Platform.isAndroid) {
      final androidInfo = await _getAndroidVersion();
      if (androidInfo >= 33) {
        // Android 13+ uses granular permissions
        final images = await ph.Permission.photos.request();
        final videos = await ph.Permission.videos.request();
        
        if (images.isGranted && videos.isGranted) {
          return PermissionResult.granted;
        } else if (images.isPermanentlyDenied || videos.isPermanentlyDenied) {
          return PermissionResult.permanentlyDenied;
        } else {
          return PermissionResult.denied;
        }
      } else {
        // Android 12 and below
        final status = await ph.Permission.storage.request();
        switch (status) {
          case ph.PermissionStatus.granted:
            return PermissionResult.granted;
          case ph.PermissionStatus.denied:
            return PermissionResult.denied;
          case ph.PermissionStatus.permanentlyDenied:
            return PermissionResult.permanentlyDenied;
          case ph.PermissionStatus.restricted:
            return PermissionResult.restricted;
          default:
            return PermissionResult.denied;
        }
      }
    }
    
    return PermissionResult.denied;
  }

  // MARK: - Camera Functions

  /// Take a photo from camera with permission handling
  Future<MediaResult<String>> takePhoto() async {
    try {
      // Check and request camera permission
      final cameraPermission = await requestCameraPermission();
      if (cameraPermission != PermissionResult.granted) {
        return MediaResult.error(_getPermissionErrorMessage(cameraPermission, 'camera'));
      }

      // Take photo
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image == null) {
        return MediaResult.cancelled();
      }

      // Save to app directory
      final savedPath = await _saveMediaFile(image.path, 'images');
      return MediaResult.success(savedPath);

    } catch (e) {
      return MediaResult.error('Failed to take photo: ${e.toString()}');
    }
  }

  /// Take a video from camera with permission handling
  Future<MediaResult<String>> takeVideo() async {
    try {
      // Check and request camera permission
      final cameraPermission = await requestCameraPermission();
      if (cameraPermission != PermissionResult.granted) {
        return MediaResult.error(_getPermissionErrorMessage(cameraPermission, 'camera'));
      }

      // Take video
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5), // 5 minute limit
        preferredCameraDevice: CameraDevice.rear,
      );

      if (video == null) {
        return MediaResult.cancelled();
      }

      // Save to app directory
      final savedPath = await _saveMediaFile(video.path, 'videos');
      return MediaResult.success(savedPath);

    } catch (e) {
      return MediaResult.error('Failed to record video: ${e.toString()}');
    }
  }

  // MARK: - Photo Library Functions

  /// Pick image from photo library
  Future<MediaResult<String>> pickImageFromLibrary() async {
    try {
      // Check and request photo library permission
      final libraryPermission = await requestPhotoLibraryPermission();
      if (libraryPermission != PermissionResult.granted) {
        return MediaResult.error(_getPermissionErrorMessage(libraryPermission, 'photo library'));
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) {
        return MediaResult.cancelled();
      }

      // Save to app directory
      final savedPath = await _saveMediaFile(image.path, 'images');
      return MediaResult.success(savedPath);

    } catch (e) {
      return MediaResult.error('Failed to pick image: ${e.toString()}');
    }
  }

  /// Pick video from photo library
  Future<MediaResult<String>> pickVideoFromLibrary() async {
    try {
      // Check and request photo library permission
      final libraryPermission = await requestPhotoLibraryPermission();
      if (libraryPermission != PermissionResult.granted) {
        return MediaResult.error(_getPermissionErrorMessage(libraryPermission, 'photo library'));
      }

      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10), // 10 minute limit for library
      );

      if (video == null) {
        return MediaResult.cancelled();
      }

      // Save to app directory
      final savedPath = await _saveMediaFile(video.path, 'videos');
      return MediaResult.success(savedPath);

    } catch (e) {
      return MediaResult.error('Failed to pick video: ${e.toString()}');
    }
  }

  /// Pick multiple images from photo library
  Future<MediaResult<List<String>>> pickMultipleImages() async {
    try {
      // Check and request photo library permission
      final libraryPermission = await requestPhotoLibraryPermission();
      if (libraryPermission != PermissionResult.granted) {
        return MediaResult.error(_getPermissionErrorMessage(libraryPermission, 'photo library'));
      }

      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (images.isEmpty) {
        return MediaResult.cancelled();
      }

      // Save all images
      final List<String> savedPaths = [];
      for (final image in images) {
        final savedPath = await _saveMediaFile(image.path, 'images');
        savedPaths.add(savedPath);
      }

      return MediaResult.success(savedPaths);

    } catch (e) {
      return MediaResult.error('Failed to pick images: ${e.toString()}');
    }
  }

  // MARK: - Audio Recording Functions

  /// Start audio recording with permission handling
  Future<MediaResult<void>> startAudioRecording() async {
    try {
      // Check and request microphone permission
      final micPermission = await requestMicrophonePermission();
      if (micPermission != PermissionResult.granted) {
        return MediaResult.error(_getPermissionErrorMessage(micPermission, 'microphone'));
      }

      // Generate unique filename
      final directory = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${directory.path}/audio');
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }

      final fileName = '${_uuid.v4()}.m4a';
      final filePath = '${audioDir.path}/$fileName';

      // Start recording
      await _audioRecorder.start(
        RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: filePath,
      );

      return MediaResult.success(null);

    } catch (e) {
      return MediaResult.error('Failed to start recording: ${e.toString()}');
    }
  }

  /// Stop audio recording and return file path
  Future<MediaResult<String>> stopAudioRecording() async {
    try {
      final path = await _audioRecorder.stop();
      
      if (path == null) {
        return MediaResult.error('Recording was not started or failed to save');
      }

      return MediaResult.success(path);

    } catch (e) {
      return MediaResult.error('Failed to stop recording: ${e.toString()}');
    }
  }

  /// Check if currently recording
  Future<bool> isRecording() async {
    return await _audioRecorder.isRecording();
  }

  /// Cancel current recording
  Future<void> cancelRecording() async {
    if (await _audioRecorder.isRecording()) {
      await _audioRecorder.cancel();
    }
  }

  // MARK: - File Management

  /// Pick files from device storage
  Future<MediaResult<List<String>>> pickFiles({
    List<String>? allowedExtensions,
    FileType type = FileType.any,
    bool allowMultiple = false,
  }) async {
    try {
      // Check storage permission for Android
      if (Platform.isAndroid) {
        final storagePermission = await requestStoragePermission();
        if (storagePermission != PermissionResult.granted) {
          return MediaResult.error(_getPermissionErrorMessage(storagePermission, 'storage'));
        }
      }

      final result = await FilePicker.platform.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
        allowMultiple: allowMultiple,
        withData: false,
        withReadStream: false,
      );

      if (result == null || result.files.isEmpty) {
        return MediaResult.cancelled();
      }

      final List<String> filePaths = result.files
          .where((file) => file.path != null)
          .map((file) => file.path!)
          .toList();

      // Save files to app directory
      final List<String> savedPaths = [];
      for (final filePath in filePaths) {
        final savedPath = await _saveMediaFile(filePath, 'files');
        savedPaths.add(savedPath);
      }

      return MediaResult.success(savedPaths);

    } catch (e) {
      return MediaResult.error('Failed to pick files: ${e.toString()}');
    }
  }

  /// Delete media file
  Future<bool> deleteMediaFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get media file size
  Future<int> getMediaFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // MARK: - Helper Methods

  /// Save media file to app directory
  Future<String> _saveMediaFile(String sourcePath, String subfolder) async {
    final directory = await getApplicationDocumentsDirectory();
    final mediaDir = Directory('${directory.path}/$subfolder');
    
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }

    final sourceFile = File(sourcePath);
    final fileName = '${_uuid.v4()}.${sourcePath.split('.').last}';
    final destinationPath = '${mediaDir.path}/$fileName';
    
    await sourceFile.copy(destinationPath);
    
    // Clean up temporary file if it's different from destination
    if (sourcePath != destinationPath) {
      try {
        await sourceFile.delete();
      } catch (e) {
        // Ignore deletion errors for temporary files
      }
    }
    
    return destinationPath;
  }

  /// Get Android API version
  Future<int> _getAndroidVersion() async {
    if (!Platform.isAndroid) return 0;
    
    try {
      final version = await const MethodChannel('flutter.io/deviceinfo')
          .invokeMethod('getAndroidVersion');
      return version as int? ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get permission error message
  String _getPermissionErrorMessage(PermissionResult result, String permissionType) {
    switch (result) {
      case PermissionResult.denied:
        return 'Access to $permissionType was denied. Please grant permission to continue.';
      case PermissionResult.permanentlyDenied:
        return 'Access to $permissionType was permanently denied. Please enable it in Settings.';
      case PermissionResult.restricted:
        return 'Access to $permissionType is restricted on this device.';
      default:
        return 'Permission error occurred for $permissionType.';
    }
  }

  /// Open app settings for permission management
  Future<bool> openAppSettings() async {
    return await ph.openAppSettings();
  }
}

// MARK: - Data Models

enum PermissionResult {
  granted,
  denied,
  permanentlyDenied,
  restricted,
}

class MediaResult<T> {
  final T? data;
  final String? error;
  final bool isSuccess;
  final bool isCancelled;

  const MediaResult._({
    this.data,
    this.error,
    required this.isSuccess,
    required this.isCancelled,
  });

  factory MediaResult.success(T data) => MediaResult._(
    data: data,
    isSuccess: true,
    isCancelled: false,
  );

  factory MediaResult.error(String error) => MediaResult._(
    error: error,
    isSuccess: false,
    isCancelled: false,
  );

  factory MediaResult.cancelled() => MediaResult._(
    isSuccess: false,
    isCancelled: true,
  );
}