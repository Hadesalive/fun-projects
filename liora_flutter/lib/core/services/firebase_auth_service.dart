import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';

class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ApiService _apiService = ApiService();
  User? _currentUser;
  String? _verificationId;

  // Initialize the service
  Future<void> initialize() async {
    // Initialize API service
    _apiService.initialize();
    
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      _currentUser = user;
    });
  }

  // Send OTP to phone number
  Future<AuthResult> sendOTP(String phoneNumber) async {
    try {
      // Clean phone number (remove spaces, dashes, etc.)
      final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      // Ensure phone number starts with +
      final formattedPhone = cleanPhone.startsWith('+') ? cleanPhone : '+$cleanPhone';

      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification completed (Android only)
          final result = await _auth.signInWithCredential(credential);
          if (result.user != null) {
            _currentUser = result.user;
            await _saveUserData();
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          print('Verification failed: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );

      return AuthResult.success(
        message: 'OTP sent successfully',
        phoneNumber: formattedPhone,
        isExistingUser: _currentUser != null,
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_getErrorMessage(e));
    } catch (e) {
      return AuthResult.error('An unexpected error occurred');
    }
  }

  // Verify OTP
  Future<AuthResult> verifyOTP(String otp) async {
    try {
      if (_verificationId == null) {
        return AuthResult.error('Please request OTP first');
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      final result = await _auth.signInWithCredential(credential);
      
      if (result.user != null) {
        _currentUser = result.user;
        
        // Authenticate with backend using phone number (development mode)
        final backendResult = await _apiService.authenticateWithPhone(
          result.user!.phoneNumber!,
          displayName: result.user!.displayName,
        );
        
        if (backendResult.success) {
          print('🎉 Backend authentication successful');
          await _saveUserData();
          
          // Create user model with backend data
          final backendUser = backendResult.data['user'];
          final userModel = UserModel(
            id: backendUser['id'],
            phoneNumber: backendUser['phoneNumber'],
            username: backendUser['username'],
            displayName: backendUser['displayName'],
            avatarUrl: backendUser['avatarUrl'],
            isPhoneVerified: backendUser['isPhoneVerified'],
            isOnline: backendUser['isOnline'] ?? true,
            lastSeen: backendUser['lastSeen'] != null 
                ? DateTime.parse(backendUser['lastSeen'])
                : DateTime.now(),
          );
          
          return AuthResult.success(
            message: 'Authentication successful',
            user: userModel,
            backendToken: _apiService.backendToken,
          );
        } else {
          print('❌ Backend authentication failed: ${backendResult.error}');
          // Still save Firebase user data even if backend fails
          await _saveUserData();
          
          return AuthResult.success(
            message: 'Firebase authentication successful (backend connection failed)',
            user: _createUserModel(result.user!),
          );
        }
      } else {
        return AuthResult.error('Verification failed');
      }
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_getErrorMessage(e));
    } catch (e) {
      return AuthResult.error('An unexpected error occurred: ${e.toString()}');
    }
  }

  // Update user profile
  Future<AuthResult> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      if (_currentUser == null) {
        return AuthResult.error('User not authenticated');
      }

      await _currentUser!.updateDisplayName(displayName);
      if (photoURL != null) {
        await _currentUser!.updatePhotoURL(photoURL);
      }

      // Reload user to get updated data
      await _currentUser!.reload();
      _currentUser = _auth.currentUser;

      await _saveUserData();

      return AuthResult.success(
        message: 'Profile updated successfully',
        user: _createUserModel(_currentUser!),
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_getErrorMessage(e));
    } catch (e) {
      return AuthResult.error('An unexpected error occurred');
    }
  }

  // Get current user
  UserModel? get currentUser {
    if (_currentUser == null) return null;
    return _createUserModel(_currentUser!);
  }

  // Check if user is authenticated
  bool get isAuthenticated => _currentUser != null;

  // Get auth token
  Future<String?> get token async {
    if (_currentUser == null) return null;
    return await _currentUser!.getIdToken();
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    _verificationId = null;
    await _clearUserData();
  }

  // Create UserModel from Firebase User
  UserModel _createUserModel(User user) {
    return UserModel(
      id: user.uid,
      phoneNumber: user.phoneNumber ?? '',
      username: user.displayName ?? 'user_${user.uid.substring(0, 8)}',
      displayName: user.displayName,
      avatarUrl: user.photoURL,
      isPhoneVerified: user.phoneNumber != null,
      isOnline: true,
      lastSeen: DateTime.now(),
    );
  }

  // Save user data to local storage
  Future<void> _saveUserData() async {
    if (_currentUser == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final userData = _createUserModel(_currentUser!);
    
    await prefs.setString(AppConstants.userDataKey, userData.toJsonString());
  }

  // Clear user data
  Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.userDataKey);
  }

  // Get user-friendly error message
  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Invalid phone number format';
      case 'too-many-requests':
        return 'Too many requests. Please try again later';
      case 'invalid-verification-code':
        return 'Invalid verification code';
      case 'invalid-verification-id':
        return 'Verification session expired. Please request a new code';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'operation-not-allowed':
        return 'Phone authentication is not enabled';
      default:
        return e.message ?? 'Authentication failed';
    }
  }
}

// Auth result class
class AuthResult {
  final bool success;
  final String? message;
  final String? error;
  final UserModel? user;
  final String? phoneNumber;
  final bool? isExistingUser;
  final String? backendToken;

  const AuthResult._({
    required this.success,
    this.message,
    this.error,
    this.user,
    this.phoneNumber,
    this.isExistingUser,
    this.backendToken,
  });

  factory AuthResult.success({
    String? message,
    UserModel? user,
    String? phoneNumber,
    bool? isExistingUser,
    String? backendToken,
  }) => AuthResult._(
    success: true,
    message: message,
    user: user,
    phoneNumber: phoneNumber,
    isExistingUser: isExistingUser,
    backendToken: backendToken,
  );

  factory AuthResult.error(String error) => AuthResult._(
    success: false,
    error: error,
  );
}

// User model for auth
class UserModel {
  final String id;
  final String phoneNumber;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final bool isPhoneVerified;
  final bool isOnline;
  final DateTime? lastSeen;

  const UserModel({
    required this.id,
    required this.phoneNumber,
    required this.username,
    this.displayName,
    this.avatarUrl,
    required this.isPhoneVerified,
    this.isOnline = false,
    this.lastSeen,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      username: json['username'] ?? '',
      displayName: json['displayName'],
      avatarUrl: json['avatarUrl'],
      isPhoneVerified: json['isPhoneVerified'] ?? false,
      isOnline: json['isOnline'] ?? false,
      lastSeen: json['lastSeen'] != null 
          ? DateTime.parse(json['lastSeen']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'username': username,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'isPhoneVerified': isPhoneVerified,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }
}
