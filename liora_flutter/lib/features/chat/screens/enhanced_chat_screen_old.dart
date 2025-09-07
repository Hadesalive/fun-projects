import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/navigation/app_router.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/chat_input_bar.dart';
import '../../../core/models/message.dart';
import '../../../core/services/api_service.dart';

class EnhancedChatScreen extends StatefulWidget {
  final String peerName;
  final String peerAvatarUrl;
  final String? conversationId; // Add conversation ID for real API calls
  
  const EnhancedChatScreen({
    super.key,
    required this.peerName,
    required this.peerAvatarUrl,
    this.conversationId,
  });

  @override
  State<EnhancedChatScreen> createState() => _EnhancedChatScreenState();
}

class _EnhancedChatScreenState extends State<EnhancedChatScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  
  late AnimationController _typingAnimationController;
  bool _isTyping = false;
  bool _peerIsTyping = false;
  bool _showScrollToBottom = false;
  bool _isMuted = false;
  bool _isBlocked = false;
  
  final List<MockMessage> _messages = [
    MockMessage(
      id: '1',
      text: 'Hey! How are you doing today?',
      isMe: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
      status: MessageStatus.read,
    ),
    MockMessage(
      id: '2',
      text: "I'm doing great! Just finished a really interesting project at work. How about you?",
      isMe: true,
      timestamp: DateTime.now().subtract(const Duration(minutes: 43)),
      status: MessageStatus.read,
    ),
    MockMessage(
      id: '3',
      text: 'That sounds amazing! What kind of project was it?',
      isMe: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 40)),
      status: MessageStatus.read,
    ),
    MockMessage(
      id: '4',
      text: 'It was a mobile app for a local business. Really enjoyed working on the UI design and animations.',
      isMe: true,
      timestamp: DateTime.now().subtract(const Duration(minutes: 38)),
      status: MessageStatus.read,
    ),
    MockMessage(
      id: '5',
      text: 'Would love to see it sometime! Are you free for coffee this weekend?',
      isMe: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 35)),
      status: MessageStatus.read,
    ),
    MockMessage(
      id: '6',
      text: 'Absolutely! Saturday afternoon works perfectly for me. How about that new place downtown?',
      isMe: true,
      timestamp: DateTime.now().subtract(const Duration(minutes: 33)),
      status: MessageStatus.delivered,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _scrollController.addListener(_onScroll);
    _messageController.addListener(_onTextChanged);
    
    // Simulate peer typing after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _peerIsTyping = true);
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() => _peerIsTyping = false);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _typingAnimationController.dispose();
    _scrollController.dispose();
    _messageController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    final showScrollToBottom = _scrollController.offset > 200;
    if (_showScrollToBottom != showScrollToBottom) {
      setState(() => _showScrollToBottom = showScrollToBottom);
    }
  }

  void _onTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (_isTyping != hasText) {
      setState(() => _isTyping = hasText);
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

  // Convert MockMessage to new Message model
  NewMessage.Message _convertToNewMessage(MockMessage mockMessage) {
    return NewMessage.Message(
      id: mockMessage.id,
      conversationId: 'temp',
      sender: NewMessage.MessageSender(
        id: mockMessage.isMe ? 'me' : 'peer',
        username: mockMessage.isMe ? 'You' : widget.peerName,
        displayName: mockMessage.isMe ? 'You' : widget.peerName,
        avatarUrl: mockMessage.isMe ? null : widget.peerAvatarUrl,
      ),
      type: NewMessage.MessageType.text,
      content: NewMessage.MessageContent(text: mockMessage.text),
      status: _convertMessageStatus(mockMessage.status),
      createdAt: mockMessage.timestamp,
      isMe: mockMessage.isMe,
    );
  }

  NewMessage.MessageStatus _convertMessageStatus(MessageStatus oldStatus) {
    switch (oldStatus) {
      case MessageStatus.sending:
        return NewMessage.MessageStatus.sending;
      case MessageStatus.sent:
        return NewMessage.MessageStatus.sent;
      case MessageStatus.delivered:
        return NewMessage.MessageStatus.delivered;
      case MessageStatus.read:
        return NewMessage.MessageStatus.read;
      case MessageStatus.failed:
        return NewMessage.MessageStatus.failed;
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    HapticFeedback.lightImpact();
    
    final message = MockMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isMe: true,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );
    
    setState(() {
      _messages.add(message);
      _messageController.clear();
    });
    
    // Simulate message status updates
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          final index = _messages.indexWhere((m) => m.id == message.id);
          if (index != -1) {
            _messages[index] = message.copyWith(status: MessageStatus.sent);
          }
        });
      }
    });
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          final index = _messages.indexWhere((m) => m.id == message.id);
          if (index != -1) {
            _messages[index] = message.copyWith(status: MessageStatus.delivered);
          }
        });
      }
    });
    
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          final index = _messages.indexWhere((m) => m.id == message.id);
          if (index != -1) {
            _messages[index] = message.copyWith(status: MessageStatus.read);
          }
        });
      }
    });
    
    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(isDark),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isDark ? AppColors.darkBackground : AppColors.lightBackground,
              isDark ? AppColors.darkSurface.withOpacity(0.3) : AppColors.lightSurface.withOpacity(0.3),
            ],
          ),
        ),
        child: Column(
          children: [
            // Messages List
            Expanded(
              child: Stack(
                children: [
                  ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.only(
                      top: kToolbarHeight + MediaQuery.of(context).padding.top + 16,
                      left: 16,
                      right: 16,
                      bottom: 16,
                    ),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _messages.length + (_peerIsTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _peerIsTyping) {
                        return TypingIndicator(
                          avatarUrl: widget.peerAvatarUrl,
                        ).animate().fadeIn();
                      }
                      
                      final message = _messages[index];
                      final previousMessage = index > 0 ? _messages[index - 1] : null;
                      final showAvatar = !message.isMe && 
                          (previousMessage == null || 
                           previousMessage.isMe ||
                           message.timestamp.difference(previousMessage.timestamp).inMinutes > 5);
                      
                      return MessageBubble(
                        message: _convertToNewMessage(message),
                        showAvatar: showAvatar,
                        avatarUrl: showAvatar ? widget.peerAvatarUrl : null,
                          ).animate().slideY(begin: 0.3, end: 0,
                        delay: Duration(milliseconds: index * 50),
                      );
                    },
                  ),
                  
                  // Scroll to bottom button
                  if (_showScrollToBottom)
                    Positioned(
                      right: 16,
                      bottom: 80,
                      child: FloatingActionButton.small(
                        onPressed: _scrollToBottom,
                        backgroundColor: AppColors.systemBlue,
                        elevation: 4,
                        child: const Icon(
                          LucideIcons.arrowDown,
                          color: Colors.white,
                          size: 20,
                        ),
                      ).animate().scale().fadeIn(),
                    ),
                ],
              ),
            ),
            
            // Input Bar
            ChatInputBar(
              controller: _messageController,
              focusNode: _messageFocusNode,
              onSend: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: (isDark ? AppColors.darkBackground : AppColors.lightBackground).withOpacity(0.9),
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(LucideIcons.chevronLeft, size: 28),
      ),
      title: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: CachedNetworkImageProvider(widget.peerAvatarUrl),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.systemGreen,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  _peerIsTyping ? 'typing...' : 'online',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: _peerIsTyping ? AppColors.systemBlue : AppColors.systemGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _makeVideoCall,
          icon: const Icon(CupertinoIcons.video_camera, color: AppColors.systemBlue, size: 26),
        ),
        IconButton(
          onPressed: _makeAudioCall,
          icon: const Icon(CupertinoIcons.phone, color: AppColors.systemBlue, size: 26),
        ),
        IconButton(
          onPressed: _showOptionsModal,
          icon: const Icon(CupertinoIcons.ellipsis_circle, color: AppColors.systemBlue, size: 26),
        ),
      ],
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  (isDark ? AppColors.darkBackground : AppColors.lightBackground).withOpacity(0.9),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAttachmentOptions() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _AttachmentOptionsSheet(),
    );
  }

  void _openCamera() {
    HapticFeedback.lightImpact();
    // TODO: Implement camera functionality
  }

  void _recordVoice() {
    HapticFeedback.lightImpact();
    // TODO: Implement voice recording
  }

  void _makeVideoCall() {
    HapticFeedback.lightImpact();
    // TODO: Implement video call
  }

  void _makeAudioCall() {
    HapticFeedback.lightImpact();
    // TODO: Implement audio call
  }

  void _showOptionsModal() {
    HapticFeedback.lightImpact();
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showContactInfo();
            },
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.person_circle,
                  color: AppColors.systemBlue,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Contact Info',
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
              _muteConversation();
            },
            child: Row(
              children: [
                Icon(
                  _isMuted ? CupertinoIcons.bell : CupertinoIcons.bell_slash,
                  color: AppColors.systemBlue,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  _isMuted ? 'Unmute Notifications' : 'Mute Notifications',
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
              _searchInConversation();
            },
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.search,
                  color: AppColors.systemBlue,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Search in Conversation',
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
              _blockUser();
            },
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.xmark_circle,
                  color: AppColors.systemRed,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Block Contact',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    color: AppColors.systemRed,
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

  void _showContactInfo() {
    HapticFeedback.lightImpact();
    final location = Uri(
      path: AppRouter.contactInfo,
      queryParameters: {
        'name': widget.peerName,
        'avatar': widget.peerAvatarUrl,
        'muted': _isMuted.toString(),
        'blocked': _isBlocked.toString(),
      },
    ).toString();
    context.push(location);
  }

  void _muteConversation() {
    HapticFeedback.lightImpact();
    setState(() => _isMuted = !_isMuted);
    
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          _isMuted ? 'Notifications Muted' : 'Notifications Enabled',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          _isMuted 
              ? 'You will no longer receive notifications for messages from ${widget.peerName}.'
              : 'You will now receive notifications for messages from ${widget.peerName}.',
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

  void _searchInConversation() {
    HapticFeedback.lightImpact();
    _showSearchModal();
  }

  void _showSearchModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _SearchInConversationSheet(contactName: widget.peerName),
    );
  }

  void _blockUser() {
    HapticFeedback.lightImpact();
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Block ${widget.peerName}?',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'You will no longer receive messages from this contact.',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontSize: 17,
                color: AppColors.systemBlue,
              ),
            ),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isBlocked = true);
              _showBlockedConfirmation();
            },
            child: Text(
              'Block',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBlockedConfirmation() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Contact Blocked',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          '${widget.peerName} has been blocked. You will no longer receive messages from this contact.',
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
}

class _AttachmentOptionsSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 5,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: AppColors.systemGray4,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _AttachmentOption(
                icon: LucideIcons.camera,
                label: 'Camera',
                color: AppColors.systemBlue,
                onTap: () => Navigator.pop(context),
              ),
              _AttachmentOption(
                icon: LucideIcons.image,
                label: 'Gallery',
                color: AppColors.systemGreen,
                onTap: () => Navigator.pop(context),
              ),
              _AttachmentOption(
                icon: LucideIcons.fileText,
                label: 'Document',
                color: AppColors.systemOrange,
                onTap: () => Navigator.pop(context),
              ),
              _AttachmentOption(
                icon: LucideIcons.mapPin,
                label: 'Location',
                color: AppColors.systemRed,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttachmentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachmentOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Mock Message Model
class MockMessage {
  final String id;
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final MessageStatus status;

  MockMessage({
    required this.id,
    required this.text,
    required this.isMe,
    required this.timestamp,
    required this.status,
  });

  MockMessage copyWith({
    String? id,
    String? text,
    bool? isMe,
    DateTime? timestamp,
    MessageStatus? status,
  }) {
    return MockMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isMe: isMe ?? this.isMe,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

class _SearchInConversationSheet extends StatefulWidget {
  final String contactName;
  
  const _SearchInConversationSheet({required this.contactName});

  @override
  State<_SearchInConversationSheet> createState() => _SearchInConversationSheetState();
}

class _SearchInConversationSheetState extends State<_SearchInConversationSheet> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<String> _searchResults = [];
  bool _isSearching = false;

  final List<String> _mockMessages = [
    'Hey! How are you doing today?',
    'I\'m doing great! Just finished a really interesting project at work.',
    'That sounds amazing! What kind of project was it?',
    'It was a mobile app for a local business. Really enjoyed working on the UI design.',
    'Would love to see it sometime! Are you free for coffee this weekend?',
    'Absolutely! Saturday afternoon works perfectly for me.',
    'Great! How about that new place downtown?',
    'Perfect! See you there at 2 PM?',
    'Sounds like a plan! Looking forward to it.',
    'Me too! Have a great rest of your week!',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        _searchResults = [];
      } else {
        _searchResults = _mockMessages
            .where((message) => message.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.75 + keyboardHeight,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[600] : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Search in Conversation',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    CupertinoIcons.xmark,
                    color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                  ),
                ),
              ],
            ),
          ),
          
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSecondaryBackground : AppColors.lightSecondaryBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _searchFocusNode.hasFocus
                      ? AppColors.systemBlue
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  width: _searchFocusNode.hasFocus ? 2 : 0.5,
                ),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Icon(
                      CupertinoIcons.search,
                      color: AppColors.systemGray,
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: CupertinoTextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      placeholder: 'Search messages with ${widget.contactName}',
                      placeholderStyle: GoogleFonts.inter(
                        color: AppColors.systemGray,
                        fontSize: 17,
                      ),
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                      ),
                      decoration: null,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _searchFocusNode.requestFocus();
                      },
                      icon: Icon(
                        CupertinoIcons.xmark_circle_fill,
                        color: AppColors.systemGray,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Search Results
          Expanded(
            child: _isSearching
                ? _searchResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.search,
                              size: 64,
                              color: AppColors.systemGray,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No messages found',
                              style: GoogleFonts.inter(
                                fontSize: 17,
                                color: AppColors.systemGray,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try a different search term',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                color: AppColors.systemGray,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final message = _searchResults[index];
                          final query = _searchController.text.trim().toLowerCase();
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSecondaryBackground : AppColors.lightSecondaryBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                width: 0.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                                    ),
                                    children: _highlightSearchTerm(message, query, isDark),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${DateTime.now().subtract(Duration(hours: index + 1)).hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.systemGray,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                : Center(
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
                          'Search Messages',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Find messages in your conversation\nwith ${widget.contactName}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: AppColors.systemGray,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  List<TextSpan> _highlightSearchTerm(String text, String query, bool isDark) {
    if (query.isEmpty) {
      return [TextSpan(text: text)];
    }

    final List<TextSpan> spans = [];
    final lowerText = text.toLowerCase();
    int start = 0;

    while (true) {
      final index = lowerText.indexOf(query, start);
      if (index == -1) {
        if (start < text.length) {
          spans.add(TextSpan(text: text.substring(start)));
        }
        break;
      }

      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }

      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: GoogleFonts.inter(
          backgroundColor: AppColors.systemBlue.withOpacity(0.3),
          fontWeight: FontWeight.w600,
        ),
      ));

      start = index + query.length;
    }

    return spans;
  }
}
