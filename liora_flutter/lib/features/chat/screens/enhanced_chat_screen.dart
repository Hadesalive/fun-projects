import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/message.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/socket_service.dart';
import '../../../shared/widgets/cupertino_toast.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input_bar.dart';
import 'dart:async';

class EnhancedChatScreen extends StatefulWidget {
  final String peerName;
  final String peerAvatarUrl;
  final String? conversationId; // For real API calls
  
  const EnhancedChatScreen({
    super.key,
    required this.peerName,
    required this.peerAvatarUrl,
    this.conversationId,
  });

  @override
  State<EnhancedChatScreen> createState() => _EnhancedChatScreenState();
}

class _EnhancedChatScreenState extends State<EnhancedChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();
  
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isSendingMessage = false;
  String? _error;
  String? _currentUserId;
  bool _isTyping = false;
  String? _typingUserId;
  
  // Stream subscriptions
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;
  StreamSubscription<Map<String, dynamic>>? _typingSubscription;
  StreamSubscription<Map<String, dynamic>>? _errorSubscription;

  @override
  void initState() {
    super.initState();
    print('🔍 Chat Screen Debug:');
    print('  - Peer Name: ${widget.peerName}');
    print('  - Peer Avatar: ${widget.peerAvatarUrl}');
    print('  - Conversation ID: ${widget.conversationId}');
    
    if (widget.conversationId != null) {
      _loadMessages();
      _loadCurrentUser();
      _setupSocketConnection();
      _syncUnreadCount(); // Sync unread count when chat opens
    } else {
      // For now, if no conversation ID, show placeholder
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Mark messages as read when user views the chat
    if (widget.conversationId != null && _messages.isNotEmpty && _currentUserId != null) {
      _markMessagesAsRead();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    _messageFocusNode.dispose();
    
    // Clean up socket connections
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _errorSubscription?.cancel();
    
    // Leave conversation and disconnect if needed
    if (widget.conversationId != null) {
      _socketService.leaveConversation(widget.conversationId!);
    }
    
    super.dispose();
  }

  Future<void> _setupSocketConnection() async {
    // Connect to socket if not already connected
    await _socketService.connect();
    
    // Join the conversation room
    if (widget.conversationId != null) {
      await _socketService.joinConversation(widget.conversationId!);
    }
    
    // Set up message listeners
    _messageSubscription = _socketService.messageStream.listen((event) {
      _handleSocketMessage(event);
    });
    
    // Set up typing listeners
    _typingSubscription = _socketService.typingStream.listen((event) {
      _handleTypingEvent(event);
    });
    
    // Set up error listeners
    _errorSubscription = _socketService.errorStream.listen((event) {
      _handleSocketError(event);
    });
  }

  void _handleSocketMessage(Map<String, dynamic> event) {
    final type = event['type'] as String;
    final data = event['data'] as Map<String, dynamic>;
    // Debug: surface incoming events in chat view
    // Helps verify the handler is firing for this screen
    // and what payload we are receiving in realtime
    // (kept concise to avoid spam)
    print('🔔 Chat socket event: $type for conv ${data['conversationId'] ?? data['conversation']}');
    
    switch (type) {
      case 'new':
        _handleNewMessage(data);
        break;
      case 'edited':
        _handleEditedMessage(data);
        break;
      case 'deleted':
        _handleDeletedMessage(data);
        break;
      case 'read':
        _handleReadMessage(data);
        break;
      case 'reaction':
        _handleReactionMessage(data);
        break;
    }
  }

  void _handleNewMessage(Map<String, dynamic> data) {
    try {
      // Normalize incoming payload
      final normalized = Map<String, dynamic>.from(data);
      // Some emits use 'conversation' instead of 'conversationId'
      if (normalized['conversationId'] == null && normalized['conversation'] != null) {
        normalized['conversationId'] = normalized['conversation'];
      }
      // Ensure content map has 'text' key for text messages
      if (normalized['type'] == 'text') {
        final content = normalized['content'];
        if (content is String) {
          normalized['content'] = { 'text': content };
        }
      }
      // Ensure createdAt exists as ISO string
      if (normalized['createdAt'] == null) {
        normalized['createdAt'] = DateTime.now().toIso8601String();
      }

      // Drop messages not for the currently open conversation
      if (widget.conversationId != null &&
          normalized['conversationId'] != widget.conversationId) {
        print('🚫 Ignored message for different conversation ${normalized['conversationId']}');
        return;
      }

      print('✅ Processing realtime message for conv ${normalized['conversationId']}');

      Message message;
      try {
        message = Message.fromJson(normalized);
      } catch (_) {
        // Fallback minimal mapping to avoid losing realtime update
        final contentMap = (normalized['content'] as Map<String, dynamic>? ?? {});
        final text = contentMap['text'] as String? ?? '';
        message = Message(
          id: (normalized['id'] as String?) ?? (normalized['_id'] as String? ?? ''),
          conversationId: normalized['conversationId'] as String? ?? widget.conversationId ?? '',
          sender: MessageSender(
            id: (normalized['sender'] is Map)
                ? (normalized['sender']['id'] as String? ?? normalized['sender']['_id'] as String? ?? '')
                : (normalized['sender'] as String? ?? ''),
            username: (normalized['sender'] is Map) ? (normalized['sender']['username'] as String? ?? '') : '',
            displayName: (normalized['sender'] is Map) ? (normalized['sender']['displayName'] as String? ?? '') : '',
          ),
          type: MessageType.text,
          content: MessageContent(text: text),
          status: MessageStatus.sent,
          createdAt: DateTime.tryParse(normalized['createdAt'] as String? ?? '') ?? DateTime.now(),
          isMe: false,
        );
      }
      
      final beforeLen = _messages.length;
      setState(() {
        // Check if this is a message we sent (by clientId or sender)
        final isFromCurrentUser = message.sender.id == _currentUserId;
        
        print('🔍 Real-time message debug:');
        print('  - Message sender ID: ${message.sender.id}');
        print('  - Current user ID: $_currentUserId');
        print('  - Is from current user: $isFromCurrentUser');
        print('  - Original isMe: ${message.isMe}');
        
        // Create a new message with correct isMe property
        final correctedMessage = Message(
          id: message.id,
          conversationId: message.conversationId,
          sender: message.sender,
          type: message.type,
          content: message.content,
          replyToId: message.replyToId,
          reactions: message.reactions,
          status: message.status,
          createdAt: message.createdAt,
          editedAt: message.editedAt,
          isMe: isFromCurrentUser, // Force correct isMe value
          isDeleted: message.isDeleted,
        );
        
        if (isFromCurrentUser) {
          // Replace temp message with real message
          final tempIndex = _messages.indexWhere((msg) => 
            msg.id == normalized['clientId'] || 
            (msg.sender.id == _currentUserId && msg.content.text == message.content.text)
          );
          
          if (tempIndex != -1) {
            _messages[tempIndex] = correctedMessage;
          } else {
            _messages.add(correctedMessage);
          }
        } else {
          // Add new message from other user
          _messages.add(correctedMessage);
        }
      });
      final afterLen = _messages.length;
      if (afterLen == beforeLen) {
        // As a safety net, fetch latest from API if nothing was appended/reconciled
        // This avoids cases where schema drift prevents realtime render
        _loadMessages();
      }
      
      _scrollToBottom();
      
      // Mark messages as read when new message is received
      _markMessagesAsRead();
    } catch (e) {
      print('Error handling new message: $e');
    }
  }

  void _handleEditedMessage(Map<String, dynamic> data) {
    final messageId = data['messageId'] as String;
    final content = data['content'] as Map<String, dynamic>;
    
    setState(() {
      final index = _messages.indexWhere((msg) => msg.id == messageId);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(
          content: MessageContent.fromJson(content, 'text'),
          editedAt: DateTime.parse(data['editedAt']),
        );
      }
    });
  }

  void _handleDeletedMessage(Map<String, dynamic> data) {
    final messageId = data['messageId'] as String;
    
    setState(() {
      _messages.removeWhere((msg) => msg.id == messageId);
    });
  }

  void _handleReadMessage(Map<String, dynamic> data) {
    final messageId = data['messageId'] as String;
    final userId = data['userId'] as String;
    
    // Update read status for the message
    setState(() {
      final index = _messages.indexWhere((msg) => msg.id == messageId);
      if (index != -1) {
        // For now, just update the status to read
        _messages[index] = _messages[index].copyWith(
          status: MessageStatus.read,
        );
      }
    });
  }

  void _handleReactionMessage(Map<String, dynamic> data) {
    final messageId = data['messageId'] as String;
    final reactions = data['reactions'] as List<dynamic>;
    
    setState(() {
      final index = _messages.indexWhere((msg) => msg.id == messageId);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(
          reactions: reactions.map((r) => MessageReaction.fromJson(r)).toList(),
        );
      }
    });
  }

  void _handleTypingEvent(Map<String, dynamic> data) {
    final userId = data['userId'] as String;
    final isTyping = data['isTyping'] as bool;
    
    setState(() {
      _isTyping = isTyping;
      _typingUserId = isTyping ? userId : null;
    });
    
    // Clear typing indicator after 3 seconds
    if (isTyping) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isTyping = false;
            _typingUserId = null;
          });
        }
      });
    }
  }

  void _handleSocketError(Map<String, dynamic> event) {
    final type = event['type'] as String;
    final message = event['message'] as String;
    
    print('Socket error: $type - $message');
    
    // Show error to user
    if (mounted) {
      CupertinoToast.show(
        context,
        'Connection error: $message',
        type: CupertinoToastType.error,
      );
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final result = await _apiService.getCurrentUser();
      if (result.success && result.data != null) {
        final user = result.data as Map<String, dynamic>;
        setState(() {
          _currentUserId = user['id'];
        });
        
        // Mark messages as read after user ID is loaded
        if (_messages.isNotEmpty) {
          _markMessagesAsRead();
        }
      }
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  Future<void> _loadMessages() async {
    if (widget.conversationId == null) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _apiService.getMessages(widget.conversationId!);
      
      if (result.success && result.data != null) {
        final messagesList = result.data as List<dynamic>;
        final messages = messagesList.map((messageData) => Message.fromJson(messageData)).toList();
        
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        
        _scrollToBottom();
        
        // Mark messages as read after loading
        if (_currentUserId != null) {
          _markMessagesAsRead();
        }
      } else {
        setState(() {
          _error = result.error ?? 'Failed to load messages';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load messages: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isSendingMessage || widget.conversationId == null) return;

    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final tempMessage = Message(
      id: tempId,
      conversationId: widget.conversationId!,
      sender: MessageSender(
        id: _currentUserId ?? '',
        username: 'You',
        displayName: 'You',
      ),
      type: MessageType.text,
      content: MessageContent(text: text.trim()),
      status: MessageStatus.sending,
      createdAt: DateTime.now(),
      isMe: true,
    );

    setState(() {
      _messages.add(tempMessage);
      _isSendingMessage = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      // Send via Socket.IO for real-time delivery
      await _socketService.sendMessage(
        conversationId: widget.conversationId!,
        type: 'text',
        content: {'text': text.trim()},
        clientId: tempId,
      );
      
      // Also send via API as backup
      final result = await _apiService.sendMessage(widget.conversationId!, text.trim());
      
      if (result.success) {
        setState(() {
          _isSendingMessage = false;
        });
      } else {
        // Remove temp message on failure
        setState(() {
          _messages.removeWhere((msg) => msg.id == tempId);
          _isSendingMessage = false;
        });
        _showError(result.error ?? 'Failed to send message');
      }
    } catch (e) {
      // Remove temp message on error
      setState(() {
        _messages.removeWhere((msg) => msg.id == tempId);
        _isSendingMessage = false;
      });
      _showError('Failed to send message: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Timer? _typingTimer;
  
  void _handleTypingChange(String text) {
    if (widget.conversationId == null) return;
    
    // Cancel previous timer
    _typingTimer?.cancel();
    
    if (text.trim().isNotEmpty) {
      // Send typing indicator
      _socketService.setTyping(
        conversationId: widget.conversationId!,
        isTyping: true,
      );
      
      // Set timer to stop typing indicator after 2 seconds of inactivity
      _typingTimer = Timer(const Duration(seconds: 2), () {
        _socketService.setTyping(
          conversationId: widget.conversationId!,
          isTyping: false,
        );
      });
    } else {
      // Stop typing indicator immediately if text is empty
      _socketService.setTyping(
        conversationId: widget.conversationId!,
        isTyping: false,
      );
    }
  }

  void _markMessagesAsRead() {
    print('🔍 _markMessagesAsRead called:');
    print('  - Messages count: ${_messages.length}');
    print('  - Conversation ID: ${widget.conversationId}');
    print('  - Current User ID: $_currentUserId');
    
    if (_messages.isNotEmpty && widget.conversationId != null && _currentUserId != null) {
      // Find the last message that's not from the current user
      Message? lastUnreadMessage;
      for (int i = _messages.length - 1; i >= 0; i--) {
        if (!_messages[i].isMe) {
          lastUnreadMessage = _messages[i];
          break;
        }
      }
      
      if (lastUnreadMessage != null) {
        print('👁️ Marking message as read: ${lastUnreadMessage.id}');
        _socketService.markMessageAsRead(
          conversationId: widget.conversationId!,
          messageId: lastUnreadMessage.id,
        );
      } else {
        print('⚠️ No unread messages found to mark as read');
      }
    } else {
      print('⚠️ Cannot mark messages as read - missing requirements');
    }
  }

  Future<void> _syncUnreadCount() async {
    if (widget.conversationId == null) return;
    
    try {
      print('🔄 Syncing unread count for conversation: ${widget.conversationId}');
      final result = await _apiService.syncUnreadCount(widget.conversationId!);
      
      if (result.success && result.data != null) {
        final unreadCount = result.data['unreadCount'] as int? ?? 0;
        print('📊 Current unread count from backend: $unreadCount');
        
        // If there are unread messages, mark them as read
        if (unreadCount > 0) {
          _markMessagesAsRead();
        }
      }
    } catch (e) {
      print('❌ Failed to sync unread count: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      CupertinoToast.show(context, message, type: CupertinoToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: _buildAppBar(isDark),
      body: Column(
        children: [
          Expanded(
            child: _buildMessagesList(isDark),
          ),
          if (widget.conversationId != null)
            ChatInputBar(
              controller: _messageController,
              focusNode: _messageFocusNode,
              onSend: () {
                final text = _messageController.text.trim();
                if (text.isNotEmpty) {
                  _sendMessage(text);
                }
              },
              onChanged: (text) {
                _handleTypingChange(text);
              },
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: (isDark ? AppColors.darkBackground : AppColors.lightBackground).withOpacity(0.9),
      elevation: 0,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: Icon(
          CupertinoIcons.back,
          color: AppColors.systemBlue,
        ),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: widget.peerAvatarUrl.isNotEmpty
                ? NetworkImage(widget.peerAvatarUrl)
                : null,
            backgroundColor: AppColors.systemBlue.withOpacity(0.1),
            child: widget.peerAvatarUrl.isEmpty
                ? Text(
                    widget.peerName.isNotEmpty ? widget.peerName[0].toUpperCase() : '?',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.systemBlue,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.peerName,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Online',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.systemGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(bool isDark) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 48,
              color: AppColors.systemRed,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMessages,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.chat_bubble_2,
              size: 64,
              color: AppColors.systemGray,
            ),
            const SizedBox(height: 16),
            Text(
              widget.conversationId != null 
                  ? 'No messages yet\nSend the first message!'
                  : 'Direct messaging coming soon!',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppColors.systemGray,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: MessageBubble(
                  message: message,
                  showAvatar: !message.isMe,
                  avatarUrl: !message.isMe ? widget.peerAvatarUrl : null,
                ),
              );
            },
          ),
        ),
        if (_isTyping && _typingUserId != null)
          _buildTypingIndicator(isDark),
      ],
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: widget.peerAvatarUrl.isNotEmpty && widget.peerAvatarUrl.startsWith('http')
                ? CachedNetworkImageProvider(widget.peerAvatarUrl)
                : null,
            child: widget.peerAvatarUrl.isEmpty || !widget.peerAvatarUrl.startsWith('http')
                ? Text(
                    widget.peerName.isNotEmpty ? widget.peerName[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSecondaryBackground : AppColors.lightSecondaryBackground,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.peerName} is typing',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}