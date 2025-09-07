import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final Dio _dio = Dio();
  String? _token;
  UserModel? _currentUser;

  // Initialize the service
  void initialize() {
    _dio.options.baseUrl = 'http://localhost:3000/api';
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    
    // Add request interceptor to include auth token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // Token expired, clear local data
          _clearAuthData();
        }
        handler.next(error);
      },
    ));
  }

  // Send OTP to phone number
  Future<AuthResult> sendOTP(String phoneNumber) async {
    try {
      final response = await _dio.post('/auth/send-otp', data: {
        'phoneNumber': phoneNumber,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        return AuthResult.success(
          message: data['message'],
          phoneNumber: data['phoneNumber'],
          isExistingUser: data['isExistingUser'] ?? false,
        );
      } else {
        return AuthResult.error('Failed to send OTP');
      }
    } on DioException catch (e) {
      if (e.response?.data != null) {
        final errorData = e.response!.data;
        return AuthResult.error(errorData['error'] ?? 'Failed to send OTP');
      }
      return AuthResult.error('Network error. Please check your connection.');
    } catch (e) {
      return AuthResult.error('An unexpected error occurred');
    }
  }

  // Verify OTP
  Future<AuthResult> verifyOTP(String phoneNumber, String otp) async {
    try {
      final response = await _dio.post('/auth/verify-otp', data: {
        'phoneNumber': phoneNumber,
        'otp': otp,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        _token = data['token'];
        _currentUser = UserModel.fromJson(data['user']);
        
        // Save token to local storage
        await _saveAuthData();
        
        return AuthResult.success(
          message: data['message'],
          user: _currentUser!,
          token: _token!,
        );
      } else {
        return AuthResult.error('Failed to verify OTP');
      }
    } on DioException catch (e) {
      if (e.response?.data != null) {
        final errorData = e.response!.data;
        return AuthResult.error(
          errorData['error'] ?? 'Failed to verify OTP',
          code: errorData['code'],
          remainingAttempts: errorData['remainingAttempts'],
        );
      }
      return AuthResult.error('Network error. Please check your connection.');
    } catch (e) {
      return AuthResult.error('An unexpected error occurred');
    }
  }

  // Update user profile
  Future<AuthResult> updateProfile({
    String? displayName,
    String? username,
    String? avatarUrl,
  }) async {
    try {
      final response = await _dio.post('/auth/update-profile', data: {
        if (displayName != null) 'displayName': displayName,
        if (username != null) 'username': username,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        _currentUser = UserModel.fromJson(data['user']);
        
        // Update local storage
        await _saveAuthData();
        
        return AuthResult.success(
          message: data['message'],
          user: _currentUser!,
        );
      } else {
        return AuthResult.error('Failed to update profile');
      }
    } on DioException catch (e) {
      if (e.response?.data != null) {
        final errorData = e.response!.data;
        return AuthResult.error(errorData['error'] ?? 'Failed to update profile');
      }
      return AuthResult.error('Network error. Please check your connection.');
    } catch (e) {
      return AuthResult.error('An unexpected error occurred');
    }
  }

  // Get current user
  Future<AuthResult> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/me');

      if (response.statusCode == 200) {
        final data = response.data;
        _currentUser = UserModel.fromJson(data['user']);
        return AuthResult.success(user: _currentUser!);
      } else {
        return AuthResult.error('Failed to get user data');
      }
    } on DioException catch (e) {
      if (e.response?.data != null) {
        final errorData = e.response!.data;
        return AuthResult.error(errorData['error'] ?? 'Failed to get user data');
      }
      return AuthResult.error('Network error. Please check your connection.');
    } catch (e) {
      return AuthResult.error('An unexpected error occurred');
    }
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    if (_token != null && _currentUser != null) {
      return true;
    }
    
    // Try to load from local storage
    await _loadAuthData();
    return _token != null && _currentUser != null;
  }

  // Logout
  Future<void> logout() async {
    await _clearAuthData();
  }

  // Get current user
  UserModel? get currentUser => _currentUser;

  // Get auth token
  String? get token => _token;

  // Save auth data to local storage
  Future<void> _saveAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) {
      await prefs.setString(AppConstants.userTokenKey, _token!);
    }
    if (_currentUser != null) {
      await prefs.setString(AppConstants.userDataKey, jsonEncode(_currentUser!.toJson()));
    }
  }

  // Load auth data from local storage
  Future<void> _loadAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(AppConstants.userTokenKey);
    
    final userDataString = prefs.getString(AppConstants.userDataKey);
    if (userDataString != null) {
      try {
        final userData = jsonDecode(userDataString);
        _currentUser = UserModel.fromJson(userData);
      } catch (e) {
        // Invalid user data, clear it
        await _clearAuthData();
      }
    }
  }

  // Clear auth data
  Future<void> _clearAuthData() async {
    _token = null;
    _currentUser = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.userTokenKey);
    await prefs.remove(AppConstants.userDataKey);
  }
}

// Auth result class
class AuthResult {
  final bool success;
  final String? message;
  final String? error;
  final String? code;
  final int? remainingAttempts;
  final UserModel? user;
  final String? token;

  const AuthResult._({
    required this.success,
    this.message,
    this.error,
    this.code,
    this.remainingAttempts,
    this.user,
    this.token,
  });

  factory AuthResult.success({
    String? message,
    UserModel? user,
    String? token,
    String? phoneNumber,
    bool? isExistingUser,
  }) => AuthResult._(
    success: true,
    message: message,
    user: user,
    token: token,
  );

  factory AuthResult.error(
    String error, {
    String? code,
    int? remainingAttempts,
  }) => AuthResult._(
    success: false,
    error: error,
    code: code,
    remainingAttempts: remainingAttempts,
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
}
