import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/message.dart';
import '../../../core/services/api_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input_bar.dart';

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
  
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isSendingMessage = false;
  String? _error;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    if (widget.conversationId != null) {
      _loadMessages();
      _loadCurrentUser();
    } else {
      // For now, if no conversation ID, show placeholder
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final result = await _apiService.getCurrentUser();
      if (result.success && result.data != null) {
        final user = result.data as Map<String, dynamic>;
        setState(() {
          _currentUserId = user['id'];
        });
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
      final result = await _apiService.sendMessage(widget.conversationId!, text.trim());
      
      if (result.success && result.data != null) {
        // Replace temp message with real message from server
        final realMessage = Message.fromJson(result.data);
        setState(() {
          final index = _messages.indexWhere((msg) => msg.id == tempId);
          if (index != -1) {
            _messages[index] = realMessage;
          }
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

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
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

    return ListView.builder(
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
    );
  }
}
