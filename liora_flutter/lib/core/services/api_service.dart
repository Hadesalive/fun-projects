import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  String? _backendToken;

  // Initialize the service
  void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: 'http://localhost:3000/api', // Your backend URL
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Add request interceptor to include auth token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_backendToken != null) {
          options.headers['Authorization'] = 'Bearer $_backendToken';
        }
        print('🌐 API Request: ${options.method} ${options.path}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        print('✅ API Response: ${response.statusCode} ${response.requestOptions.path}');
        handler.next(response);
      },
      onError: (error, handler) {
        print('❌ API Error: ${error.response?.statusCode} ${error.requestOptions.path}');
        print('Error data: ${error.response?.data}');
        handler.next(error);
      },
    ));

    _loadStoredToken();
  }

  // Load stored backend token
  Future<void> _loadStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    _backendToken = prefs.getString('backend_token');
    if (_backendToken != null) {
      print('🔑 Backend token loaded from storage');
    }
  }

  // Store backend token
  Future<void> _storeBackendToken(String token) async {
    _backendToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('backend_token', token);
    print('🔑 Backend token stored');
  }

  // Clear backend token
  Future<void> _clearBackendToken() async {
    _backendToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('backend_token');
    print('🔑 Backend token cleared');
  }

  // Authenticate with Firebase token (production)
  Future<ApiResult> authenticateWithFirebase(String firebaseToken, {String? displayName}) async {
    try {
      final response = await _dio.post('/firebase/login', data: {
        'firebaseToken': firebaseToken,
        'displayName': displayName,
      });

      if (response.data['success'] == true) {
        final backendToken = response.data['token'];
        await _storeBackendToken(backendToken);

        return ApiResult.success(
          message: response.data['message'],
          data: response.data,
        );
      } else {
        return ApiResult.error(response.data['error'] ?? 'Authentication failed');
      }
    } on DioException catch (e) {
      return ApiResult.error(_handleDioError(e));
    } catch (e) {
      return ApiResult.error('Authentication failed: ${e.toString()}');
    }
  }

  // Authenticate with phone number (development)
  Future<ApiResult> authenticateWithPhone(String phoneNumber, {String? displayName}) async {
    try {
      final response = await _dio.post('/firebase/dev-login', data: {
        'phoneNumber': phoneNumber,
        'displayName': displayName,
      });

      if (response.data['success'] == true) {
        final backendToken = response.data['token'];
        await _storeBackendToken(backendToken);

        return ApiResult.success(
          message: response.data['message'],
          data: response.data,
        );
      } else {
        return ApiResult.error(response.data['error'] ?? 'Authentication failed');
      }
    } on DioException catch (e) {
      return ApiResult.error(_handleDioError(e));
    } catch (e) {
      return ApiResult.error('Authentication failed: ${e.toString()}');
    }
  }

  // Get current user profile
  Future<ApiResult> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/me');

      if (response.data['success'] == true) {
        return ApiResult.success(
          data: response.data['user'],
        );
      } else {
        return ApiResult.error(response.data['error'] ?? 'Failed to get user');
      }
    } on DioException catch (e) {
      return ApiResult.error(_handleDioError(e));
    } catch (e) {
      return ApiResult.error('Failed to get user: ${e.toString()}');
    }
  }

  // Get conversations
  Future<ApiResult> getConversations({int limit = 20, int skip = 0}) async {
    try {
      final response = await _dio.get('/conversations', queryParameters: {
        'limit': limit,
        'skip': skip,
      });

      if (response.data['success'] == true) {
        return ApiResult.success(
          data: response.data['conversations'],
        );
      } else {
        return ApiResult.error(response.data['error'] ?? 'Failed to get conversations');
      }
    } on DioException catch (e) {
      return ApiResult.error(_handleDioError(e));
    } catch (e) {
      return ApiResult.error('Failed to get conversations: ${e.toString()}');
    }
  }



  // Update user profile
  Future<ApiResult> updateProfile({
    String? displayName,
    String? username,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (displayName != null) data['displayName'] = displayName;
      if (username != null) data['username'] = username;
      if (bio != null) data['bio'] = bio;
      if (avatarUrl != null) data['avatarUrl'] = avatarUrl;

      final response = await _dio.patch('/users/me', data: data);

      if (response.data['success'] == true) {
        return ApiResult.success(
          data: response.data['user'],
          message: response.data['message'] ?? 'Profile updated successfully',
        );
      } else {
        return ApiResult.error(response.data['error'] ?? 'Failed to update profile');
      }
    } on DioException catch (e) {
      return ApiResult.error(_handleDioError(e));
    } catch (e) {
      return ApiResult.error('Failed to update profile: ${e.toString()}');
    }
  }

  // Update profile via auth route (for initial setup)
  Future<ApiResult> updateProfileAuth({
    String? displayName,
    String? username,
    String? avatarUrl,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (displayName != null) data['displayName'] = displayName;
      if (username != null) data['username'] = username;
      if (avatarUrl != null) data['avatarUrl'] = avatarUrl;

      final response = await _dio.post('/auth/update-profile', data: data);

      if (response.data['success'] == true) {
        return ApiResult.success(
          data: response.data['user'],
          message: response.data['message'] ?? 'Profile updated successfully',
        );
      } else {
        return ApiResult.error(response.data['error'] ?? 'Failed to update profile');
      }
    } on DioException catch (e) {
      return ApiResult.error(_handleDioError(e));
    } catch (e) {
      return ApiResult.error('Failed to update profile: ${e.toString()}');
    }
  }

  // Search users
  Future<ApiResult> searchUsers(String query, {int limit = 20}) async {
    try {
      final response = await _dio.get('/users/search', queryParameters: {
        'q': query,
        'limit': limit,
      });

      if (response.data['success'] == true) {
        return ApiResult.success(
          data: response.data['users'],
        );
      } else {
        return ApiResult.error(response.data['error'] ?? 'Failed to search users');
      }
    } on DioException catch (e) {
      return ApiResult.error(_handleDioError(e));
    } catch (e) {
      return ApiResult.error('Failed to search users: ${e.toString()}');
    }
  }

  // Update user settings
  Future<ApiResult> updateSettings({
    Map<String, dynamic>? notifications,
    Map<String, dynamic>? privacy,
    String? theme,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (notifications != null) data['notifications'] = notifications;
      if (privacy != null) data['privacy'] = privacy;
      if (theme != null) data['theme'] = theme;

      final response = await _dio.patch('/users/me/settings', data: data);

      if (response.data['success'] == true) {
        return ApiResult.success(
          data: response.data['settings'],
          message: response.data['message'] ?? 'Settings updated successfully',
        );
      } else {
        return ApiResult.error(response.data['error'] ?? 'Failed to update settings');
      }
    } on DioException catch (e) {
      return ApiResult.error(_handleDioError(e));
    } catch (e) {
      return ApiResult.error('Failed to update settings: ${e.toString()}');
    }
  }

  // Create a conversation
  Future<ApiResult> createConversation({
    required String type,
    required List<String> memberIds,
    String? name,
  }) async {
    try {
      final response = await _dio.post('/conversations', data: {
        'type': type,
        'memberIds': memberIds,
        if (name != null) 'name': name,
      });

      if (response.data['success'] == true) {
        return ApiResult.success(
          data: response.data['conversation'],
          message: 'Conversation created successfully',
        );
      } else {
        return ApiResult.error(response.data['error'] ?? 'Failed to create conversation');
      }
    } on DioException catch (e) {
      return ApiResult.error(_handleDioError(e));
    } catch (e) {
      return ApiResult.error('Failed to create conversation: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _clearBackendToken();
  }

  // Check if authenticated
  bool get isAuthenticated => _backendToken != null;

  // Get backend token
  String? get backendToken => _backendToken;

  // Group-related API methods
  Future<ApiResult> createGroup({
    required String name,
    String? description,
    String? avatarUrl,
    required List<String> memberIds,
  }) async {
    try {
      final response = await _dio.post('/conversations', data: {
        'type': 'group',
        'name': name,
        'description': description,
        'avatarUrl': avatarUrl,
        'memberIds': memberIds,
      });

      if (response.data['success'] == true) {
        return ApiResult.success(
          data: response.data['conversation'],
          message: response.data['message'] ?? 'Group created successfully',
        );
      } else {
        return ApiResult.error(response.data['error'] ?? 'Failed to create group');
      }
    } on DioException catch (e) {
      return ApiResult.error(_handleDioError(e));
    } catch (e) {
      return ApiResult.error('Failed to create group: ${e.toString()}');
    }
  }

  Future<ApiResult> getUserConversations({
    int limit = 20,
    int skip = 0,
    bool includeArchived = false,
  }) async {
    try {
      final response = await _dio.get('/conversations', queryParameters: {
        'limit': limit,
        'skip': skip,
        'includeArchived': includeArchived,
      });

      if (response.data['success'] == true) {
        return ApiResult.success(
          data: response.data['conversations'],
          message: 'Conversations loaded successfully',
        );
      } else {
        return ApiResult.error(response.data['error'] ?? 'Failed to load conversations');
      }
    } on DioException catch (e) {
      return ApiResult.error(_handleDioError(e));
    } catch (e) {
      return ApiResult.error('Failed to load conversations: ${e.toString()}');
    }
  }

  Future<ApiResult> getGroupConversations() async {
    try {
      final result = await getUserConversations();
      if (result.success && result.data != null) {
        final conversations = result.data as List<dynamic>;
        final groups = conversations.where((conv) => conv['type'] == 'group').toList();
        return ApiResult.success(
          data: groups,
          message: 'Groups loaded successfully',
        );
      } else {
        return result;
      }
    } catch (e) {
      return ApiResult.error('Failed to load groups: ${e.toString()}');
    }
  }

  // Update group name
  Future<ApiResult> updateGroupName(String groupId, String name) async {
    try {
      final response = await _dio.patch('/conversations/$groupId', data: {
        'name': name,
      });

      if (response.data['success'] == true) {
        return ApiResult.success(
          data: response.data['conversation'],
          message: response.data['message'] ?? 'Group name updated successfully',
        );
      } else {
        return ApiResult.error(response.data['error'] ?? 'Failed to update group name');
      }
    } on DioException catch (e) {
      return ApiResult.error(_handleDioError(e));
    } catch (e) {
      return ApiResult.error('Failed to update group name: ${e.toString()}');
    }
  }

  // Update group description
  Future<ApiResult> updateGroupDescription(String groupId, String description) async {
    try {
      final response = await _dio.patch('/conversations/$groupId', data: {
        'description': description,
      });

      if (response.data['success'] == true) {
        return ApiResult.success(
          data: response.data['conversation'],
          message: response.data['message'] ?? 'Group description updated successfully',
        );
      } else {
        return ApiResult.error(response.data['error'] ?? 'Failed to update group description');
      }
    } on DioException catch (e) {
      return ApiResult.error(_handleDioError(e));
    } catch (e) {
      return ApiResult.error('Failed to update group description: ${e.toString()}');
    }
  }

  // Leave group
  Future<ApiResult> leaveGroup(String groupId, String userId) async {
    try {
      final response = await _dio.delete('/conversations/$groupId/members/$userId');

      if (response.data['success'] == true) {
        return ApiResult.success(
          data: response.data['conversation'],
          message: response.data['message'] ?? 'Left group successfully',
        );
      } else {
        return ApiResult.error(response.data['error'] ?? 'Failed to leave group');
      }
    } on DioException catch (e) {
      return ApiResult.error(_handleDioError(e));
    } catch (e) {
      return ApiResult.error('Failed to leave group: ${e.toString()}');
    }
  }

  // Get conversation details
  Future<ApiResult> getConversationDetails(String conversationId) async {
    try {
      final response = await _dio.get('/conversations/$conversationId');

      if (response.data['success'] == true) {
        return ApiResult.success(
          data: response.data['conversation'],
          message: 'Conversation details loaded successfully',
        );
      } else {
        return ApiResult.error(response.data['error'] ?? 'Failed to load conversation details');
      }
    } on DioException catch (e) {
      return ApiResult.error(_handleDioError(e));
    } catch (e) {
      return ApiResult.error('Failed to load conversation details: ${e.toString()}');
    }
  }

  // Add member to group
  Future<ApiResult> addMemberToGroup(String groupId, String userId, {String role = 'member'}) async {
    try {
      final response = await _dio.post('/conversations/$groupId/members', data: {
        'userId': userId,
        'role': role,
      });

      if (response.data['success'] == true) {
        return ApiResult.success(
          data: response.data['conversation'],
          message: response.data['message'] ?? 'Member added successfully',
        );
      } else {
        return ApiResult.error(response.data['error'] ?? 'Failed to add member');
      }
    } on DioException catch (e) {
      return ApiResult.error(_handleDioError(e));
    } catch (e) {
      return ApiResult.error('Failed to add member: ${e.toString()}');
    }
  }

  // Update member role
  Future<ApiResult> updateMemberRole(String groupId, String userId, String role) async {
    try {
      final response = await _dio.patch('/conversations/$groupId/members/$userId/role', data: {
        'role': role,
      });

      if (response.data['success'] == true) {
        return ApiResult.success(
          data: response.data['conversation'],
          message: response.data['message'] ?? 'Member role updated successfully',
        );
      } else {
        return ApiResult.error(response.data['error'] ?? 'Failed to update member role');
      }
    } on DioException catch (e) {
      return ApiResult.error(_handleDioError(e));
    } catch (e) {
      return ApiResult.error('Failed to update member role: ${e.toString()}');
    }
  }

  // MESSAGE FUNCTIONALITY

  // Get messages for a conversation
  Future<ApiResult> getMessages(String conversationId, {int limit = 50, int skip = 0, String? before}) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit.toString(),
        'skip': skip.toString(),
      };
      
      if (before != null) {
        queryParams['before'] = before;
      }

      final response = await _dio.get('/messages/$conversationId', queryParameters: queryParams);

      if (response.data['success'] == true) {
        return ApiResult.success(
          data: response.data['messages'],
          message: 'Messages loaded successfully',
        );
      } else {
        return ApiResult.error(response.data['error'] ?? 'Failed to load messages');
      }
    } on DioException catch (e) {
      return ApiResult.error(_handleDioError(e));
    } catch (e) {
      return ApiResult.error('Failed to load messages: ${e.toString()}');
    }
  }

  // Send a text message
  Future<ApiResult> sendMessage(String conversationId, String text, {String? replyToId}) async {
    try {
      final data = {
        'type': 'text',
        'content': text,
      };
      
      if (replyToId != null) {
        data['replyTo'] = replyToId;
      }

      final response = await _dio.post('/messages/$conversationId', data: data);

      if (response.data['success'] == true) {
        return ApiResult.success(
          data: response.data['data'],
          message: response.data['message'] ?? 'Message sent successfully',
        );
      } else {
        return ApiResult.error(response.data['error'] ?? 'Failed to send message');
      }
    } on DioException catch (e) {
      return ApiResult.error(_handleDioError(e));
    } catch (e) {
      return ApiResult.error('Failed to send message: ${e.toString()}');
    }
  }

  // Mark messages as read
  Future<ApiResult> markMessageAsRead(String conversationId, String messageId) async {
    try {
      final response = await _dio.patch('/messages/$conversationId/read', data: {
        'messageId': messageId,
      });

      if (response.data['success'] == true) {
        return ApiResult.success(
          data: null,
          message: response.data['message'] ?? 'Message marked as read',
        );
      } else {
        return ApiResult.error(response.data['error'] ?? 'Failed to mark message as read');
      }
    } on DioException catch (e) {
      return ApiResult.error(_handleDioError(e));
    } catch (e) {
      return ApiResult.error('Failed to mark message as read: ${e.toString()}');
    }
  }

  // Add reaction to message
  Future<ApiResult> addReaction(String conversationId, String messageId, String emoji) async {
    try {
      final response = await _dio.post('/messages/$conversationId/messages/$messageId/reactions', data: {
        'emoji': emoji,
      });

      if (response.data['success'] == true) {
        return ApiResult.success(
          data: null,
          message: response.data['message'] ?? 'Reaction added successfully',
        );
      } else {
        return ApiResult.error(response.data['error'] ?? 'Failed to add reaction');
      }
    } on DioException catch (e) {
      return ApiResult.error(_handleDioError(e));
    } catch (e) {
      return ApiResult.error('Failed to add reaction: ${e.toString()}');
    }
  }

  // Remove reaction from message
  Future<ApiResult> removeReaction(String conversationId, String messageId, String emoji) async {
    try {
      final response = await _dio.delete('/messages/$conversationId/messages/$messageId/reactions', data: {
        'emoji': emoji,
      });

      if (response.data['success'] == true) {
        return ApiResult.success(
          data: null,
          message: response.data['message'] ?? 'Reaction removed successfully',
        );
      } else {
        return ApiResult.error(response.data['error'] ?? 'Failed to remove reaction');
      }
    } on DioException catch (e) {
      return ApiResult.error(_handleDioError(e));
    } catch (e) {
      return ApiResult.error('Failed to remove reaction: ${e.toString()}');
    }
  }

  // Delete message
  Future<ApiResult> deleteMessage(String conversationId, String messageId) async {
    try {
      final response = await _dio.delete('/messages/$conversationId/messages/$messageId');

      if (response.data['success'] == true) {
        return ApiResult.success(
          data: null,
          message: response.data['message'] ?? 'Message deleted successfully',
        );
      } else {
        return ApiResult.error(response.data['error'] ?? 'Failed to delete message');
      }
    } on DioException catch (e) {
      return ApiResult.error(_handleDioError(e));
    } catch (e) {
      return ApiResult.error('Failed to delete message: ${e.toString()}');
    }
  }

  // Handle Dio errors
  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.connectionError:
        return 'Connection error. Please check your internet connection.';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['error'] ?? 'Server error';
        return 'Server error ($statusCode): $message';
      default:
        return 'Network error: ${e.message}';
    }
  }

  // Create direct conversation
  Future<ApiResult> createDirectConversation(String otherUserId) async {
    try {
      final data = {
        'type': 'direct',
        'memberIds': [otherUserId],
      };

      final response = await _dio.post('/conversations', data: data);
      
      if (response.data['success'] == true) {
        return ApiResult.success(
          data: response.data['conversation'],
          message: response.data['message'] ?? 'Conversation created successfully',
        );
      } else {
        return ApiResult.error(response.data['error'] ?? 'Failed to create conversation');
      }
    } on DioException catch (e) {
      print('🔍 Checking for existing conversation case...');
      print('  - Status Code: ${e.response?.statusCode}');
      print('  - Error Message: ${e.response?.data?['error']}');
      print('  - Has Conversation: ${e.response?.data?['conversation'] != null}');

      // Handle case where conversation already exists
      if (e.response?.statusCode == 400 &&
          e.response?.data != null &&
          e.response!.data['error'] == 'Direct conversation already exists' &&
          e.response!.data['conversation'] != null) {
        print('🔄 Found existing conversation, extracting data...');
        return ApiResult.success(
          data: e.response!.data['conversation'],
          message: 'Conversation already exists',
        );
      }
      
      print('❌ DioException: ${e.response?.statusCode} - ${e.response?.data}');
      return ApiResult.error(_handleDioError(e));
    } catch (e) {
      return ApiResult.error('Failed to create conversation: ${e.toString()}');
    }
  }

  // Sync unread count for a conversation
  Future<ApiResult> syncUnreadCount(String conversationId) async {
    try {
      print('🔄 Syncing unread count for conversation: $conversationId');
      
      final response = await _dio.post(
        '/conversations/$conversationId/sync-unread',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        print('✅ Unread count synced successfully');
        return ApiResult.success(
          data: {
            'unreadCount': response.data['unreadCount'],
            'lastReadMessageId': response.data['lastReadMessageId'],
          },
          message: 'Unread count synced',
        );
      } else {
        return ApiResult.error(response.data['error'] ?? 'Failed to sync unread count');
      }
    } on DioException catch (e) {
      print('❌ Sync unread count error: ${e.response?.statusCode} - ${e.response?.data}');
      return ApiResult.error(_handleDioError(e));
    } catch (e) {
      return ApiResult.error('Failed to sync unread count: ${e.toString()}');
    }
  }
}

// API result class
class ApiResult {
  final bool success;
  final String? message;
  final String? error;
  final dynamic data;

  const ApiResult._({
    required this.success,
    this.message,
    this.error,
    this.data,
  });

  factory ApiResult.success({
    String? message,
    dynamic data,
  }) => ApiResult._(
    success: true,
    message: message,
    data: data,
  );

  factory ApiResult.error(String error) => ApiResult._(
    success: false,
    error: error,
  );
}
