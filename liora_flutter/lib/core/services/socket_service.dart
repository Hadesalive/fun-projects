import 'dart:async';
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;
  String? _currentUserId;
  
  // Configuration
  static const String _baseUrl = 'http://localhost:3000'; // Make this configurable
  static const int _reconnectionDelay = 1000;
  static const int _reconnectionAttempts = 5;
  
  // Event streams
  final StreamController<Map<String, dynamic>> _messageController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _typingController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _userStatusController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _errorController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _connectionController = 
      StreamController<bool>.broadcast();

  // Getters for streams
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;
  Stream<Map<String, dynamic>> get userStatusStream => _userStatusController.stream;
  Stream<Map<String, dynamic>> get errorStream => _errorController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  bool get isConnected => _isConnected;
  String? get currentUserId => _currentUserId;

  Future<void> connect() async {
    if (_isConnected) {
      print('✅ Socket.IO already connected');
      return;
    }

    try {
      // Get auth token from storage
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('backend_token');
      
      if (token == null) {
        print('❌ No auth token found for Socket.IO connection');
        _errorController.add({
          'type': 'connection_error',
          'message': 'No auth token found'
        });
        return;
      }

      print('🔌 Connecting to Socket.IO with token: ${token.substring(0, 20)}...');
      
      _socket = IO.io(_baseUrl, IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .setReconnectionDelay(_reconnectionDelay)
          .setReconnectionAttempts(_reconnectionAttempts)
          .build());

      _setupEventListeners();
      
    } catch (e) {
      print('❌ Socket.IO connection error: $e');
      _errorController.add({
        'type': 'connection_error',
        'message': e.toString()
      });
    }
  }

  void _setupEventListeners() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      print('✅ Socket.IO connected');
      _isConnected = true;
      _connectionController.add(true);
      _errorController.add({'type': 'connection_status', 'message': 'connected'});
    });

    _socket!.onDisconnect((_) {
      print('❌ Socket.IO disconnected');
      _isConnected = false;
      _connectionController.add(false);
    });

    _socket!.onConnectError((error) {
      print('❌ Socket.IO connection error: $error');
      _isConnected = false;
      _connectionController.add(false);
      _errorController.add({
        'type': 'connection_error',
        'message': error.toString()
      });
    });

    // Message events
    _socket!.on('message_new', (data) {
      print('📨 New message received via Socket.IO: $data');
      _messageController.add({
        'type': 'new',
        'data': data
      });
    });

    _socket!.on('message_edited', (data) {
      print('✏️ Message edited: $data');
      _messageController.add({
        'type': 'edited',
        'data': data
      });
    });

    _socket!.on('message_deleted', (data) {
      print('🗑️ Message deleted: $data');
      _messageController.add({
        'type': 'deleted',
        'data': data
      });
    });

    _socket!.on('message_read', (data) {
      print('👁️ Message read: $data');
      _messageController.add({
        'type': 'read',
        'data': data
      });
    });

    _socket!.on('message_reaction', (data) {
      print('😀 Message reaction: $data');
      _messageController.add({
        'type': 'reaction',
        'data': data
      });
    });

    // Typing indicator
    _socket!.on('typing', (data) {
      print('⌨️ Typing indicator: $data');
      _typingController.add(data);
    });

    // User status events
    _socket!.on('user_offline', (data) {
      print('👤 User offline: $data');
      _userStatusController.add({
        'type': 'offline',
        'data': data
      });
    });

    _socket!.on('user_online', (data) {
      print('👤 User online: $data');
      _userStatusController.add({
        'type': 'online',
        'data': data
      });
    });

    // Error handling
    _socket!.on('error_generic', (data) {
      print('❌ Socket error: $data');
      _errorController.add({
        'type': 'generic',
        'data': data
      });
    });
  }

  Future<void> joinConversation(String conversationId) async {
    if (!_isConnected || _socket == null) {
      print('❌ Socket not connected, cannot join conversation');
      return;
    }

    print('📱 Joining conversation: $conversationId');
    _socket!.emit('join_conversation', {'conversationId': conversationId});
  }

  Future<void> leaveConversation(String conversationId) async {
    if (!_isConnected || _socket == null) return;

    print('📱 Leaving conversation: $conversationId');
    _socket!.emit('leave_conversation', {'conversationId': conversationId});
  }

  Future<void> sendMessage({
    required String conversationId,
    required String type,
    required Map<String, dynamic> content,
    String? replyTo,
    String? clientId,
  }) async {
    if (!_isConnected || _socket == null) {
      print('❌ Socket not connected, cannot send message');
      return;
    }

    print('📤 Sending message to conversation: $conversationId');
    _socket!.emit('message_send', {
      'conversationId': conversationId,
      'type': type,
      'content': content,
      'replyTo': replyTo,
      'clientId': clientId,
    });
  }

  Future<void> editMessage({
    required String messageId,
    required Map<String, dynamic> content,
  }) async {
    if (!_isConnected || _socket == null) return;

    print('✏️ Editing message: $messageId');
    _socket!.emit('message_edit', {
      'messageId': messageId,
      'content': content,
    });
  }

  Future<void> deleteMessage(String messageId) async {
    if (!_isConnected || _socket == null) return;

    print('🗑️ Deleting message: $messageId');
    _socket!.emit('message_delete', {'messageId': messageId});
  }

  Future<void> markMessageAsRead({
    required String conversationId,
    required String messageId,
  }) async {
    if (!_isConnected || _socket == null) return;

    print('👁️ Marking message as read: $messageId');
    _socket!.emit('message_read', {
      'conversationId': conversationId,
      'messageId': messageId,
    });
  }

  Future<void> addReaction({
    required String messageId,
    required String emoji,
  }) async {
    if (!_isConnected || _socket == null) return;

    print('😀 Adding reaction: $emoji to message $messageId');
    _socket!.emit('message_react', {
      'messageId': messageId,
      'emoji': emoji,
    });
  }

  Future<void> setTyping({
    required String conversationId,
    required bool isTyping,
  }) async {
    if (!_isConnected || _socket == null) return;

    _socket!.emit('typing', {
      'conversationId': conversationId,
      'isTyping': isTyping,
    });
  }

  Future<void> disconnect() async {
    if (_socket != null) {
      print('🔌 Disconnecting Socket.IO...');
      _socket!.disconnect();
      _socket = null;
      _isConnected = false;
    }
  }

  void dispose() {
    _messageController.close();
    _typingController.close();
    _userStatusController.close();
    _errorController.close();
    _connectionController.close();
    disconnect();
  }
}
