import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/navigation/app_router.dart';
import '../../chat/widgets/message_bubble.dart';
import '../../chat/widgets/chat_input_bar.dart';
import '../../../core/models/message.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String? groupAvatarUrl;
  final int memberCount;

  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    this.groupAvatarUrl,
    required this.memberCount,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final ApiService _apiService = ApiService();

  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isSendingMessage = false;
  String? _error;
  List<Map<String, dynamic>> _members = [];
  String? _currentUserId;


  @override
  void initState() {
    super.initState();
    _loadMessages();
    _loadGroupMembers();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _apiService.getMessages(widget.groupId);
      
      if (result.success && result.data != null) {
        final messagesList = result.data as List<dynamic>;
        final messages = messagesList.map((messageData) => Message.fromJson(messageData)).toList();
        
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
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

  Future<void> _loadGroupMembers() async {
    try {
      // Load conversation details to get members
      final result = await _apiService.getConversationDetails(widget.groupId);
      
      if (result.success && result.data != null) {
        final conversation = result.data as Map<String, dynamic>;
        final members = conversation['members'] as List<dynamic>? ?? [];
        
        setState(() {
          _members = members.map((member) {
            final user = member['user'] as Map<String, dynamic>;
            return {
              'id': user['_id'] ?? user['id'],
              'name': user['displayName'] ?? user['username'] ?? 'Unknown',
              'username': user['username'] ?? '',
              'avatarUrl': user['avatarUrl'],
              'role': member['role'] ?? 'member',
              'isOnline': user['isOnline'] ?? false,
            };
          }).toList();
        });
      }
      
      // Load current user ID
      final userResult = await _apiService.getCurrentUser();
      if (userResult.success && userResult.data != null) {
        final user = userResult.data as Map<String, dynamic>;
        setState(() {
          _currentUserId = user['id'];
        });
      }
    } catch (e) {
      print('Error loading group members: $e');
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isSendingMessage) return;

    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final tempMessage = Message(
      id: tempId,
      conversationId: widget.groupId,
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
      final result = await _apiService.sendMessage(widget.groupId, text.trim());
      
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
        if (mounted) {
          _showError(result.error ?? 'Failed to send message');
        }
      }
    } catch (e) {
      // Remove temp message on error
      setState(() {
        _messages.removeWhere((msg) => msg.id == tempId);
        _isSendingMessage = false;
      });
      
      if (mounted) {
        _showError('Failed to send message: $e');
      }
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
          message,
          style: GoogleFonts.inter(
            fontSize: 13,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
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

  void _showGroupInfo() {
    HapticFeedback.lightImpact();
    
    context.push(
      Uri(
        path: AppRouter.groupInfo,
        queryParameters: {
          'groupId': widget.groupId,
          'groupName': widget.groupName,
          'memberCount': widget.memberCount.toString(),
          if (widget.groupAvatarUrl != null) 'avatarUrl': widget.groupAvatarUrl!,
        },
      ).toString(),
    );
  }

  String _getGroupInitials(String? groupName) {
    try {
      if (groupName == null || groupName.trim().isEmpty) {
        return 'G';
      }
      
      final words = groupName.trim().split(' ')
          .where((word) => word.trim().isNotEmpty)
          .toList();
      
      if (words.isEmpty) return 'G';
      
      if (words.length == 1) {
        final word = words[0].trim();
        return word.isNotEmpty ? word[0].toUpperCase() : 'G';
      }
      
      final firstWord = words[0].trim();
      final secondWord = words.length > 1 ? words[1].trim() : '';
      
      final firstInitial = firstWord.isNotEmpty ? firstWord[0] : 'G';
      final secondInitial = secondWord.isNotEmpty ? secondWord[0] : '';
      
      return '$firstInitial$secondInitial'.toUpperCase();
    } catch (e) {
      print('Error getting group initials: $e');
      return 'G'; // Safe fallback
    }
  }

  String _getMemberNames() {
    if (_members.isEmpty) {
      return '${widget.memberCount} members';
    }
    
    // Get member names, prioritizing current user as "You"
    final List<String> memberNames = _members.map((member) {
      if (member['id'] == _currentUserId) {
        return 'You';
      }
      return member['name'] as String;
    }).toList();
    
    if (memberNames.length <= 1) {
      return memberNames.isEmpty ? 'No members' : memberNames.first;
    }
    
    // For 2-3 members, show all names
    if (memberNames.length <= 3) {
      return memberNames.join(', ');
    }
    
    // Show first 2 names and count for others (WhatsApp style)
    final displayNames = memberNames.take(2).toList();
    final remainingCount = memberNames.length - 2;
    
    if (remainingCount > 0) {
      return '${displayNames.join(', ')} and $remainingCount other${remainingCount == 1 ? '' : 's'}';
    }
    
    return displayNames.join(', ');
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
              isDark ? AppColors.darkBackground.withOpacity(0.8) : AppColors.lightBackground.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          children: [
            // Messages List
            Expanded(
              child: _buildMessagesList(isDark),
            ),
            // Input Bar
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
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: (isDark ? AppColors.darkBackground : AppColors.lightBackground).withOpacity(0.9),
      elevation: 0,
      automaticallyImplyLeading: false, // Remove default back button
      title: InkWell(
        onTap: _showGroupInfo,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              // Back button as part of title
              IconButton(
                onPressed: () => context.pop(),
                icon: Icon(
                  CupertinoIcons.back,
                  color: AppColors.systemBlue,
                  size: 22,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              // Group Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.systemBlue.withOpacity(0.1),
                ),
                child: widget.groupAvatarUrl != null && widget.groupAvatarUrl!.isNotEmpty
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: widget.groupAvatarUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Center(
                            child: Text(
                              _getGroupInitials(widget.groupName),
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.systemBlue,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          _getGroupInitials(widget.groupName),
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.systemBlue,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              // Group Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.groupName,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Show member names instead of count
                    Text(
                      _getMemberNames(),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.systemGray,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            _showError('Group actions coming soon!');
          },
          icon: Icon(
            CupertinoIcons.ellipsis,
            color: AppColors.systemBlue,
            size: 20,
          ),
        ),
      ],
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
              size: 64,
              color: AppColors.systemGray,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Messages',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppColors.systemGray,
                ),
              ),
            ),
            const SizedBox(height: 24),
            CupertinoButton(
              onPressed: _loadMessages,
              color: AppColors.systemBlue,
              borderRadius: BorderRadius.circular(12),
              child: Text(
                'Retry',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
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
              'No messages yet',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start the conversation!',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppColors.systemGray,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.only(
        top: kToolbarHeight + MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      physics: const BouncingScrollPhysics(),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: MessageBubble(
            message: message,
            showAvatar: !message.isMe, // Show avatar for other users in group
            avatarUrl: !message.isMe ? message.sender.avatarUrl : null,
          ),
        );
      },
    );
  }
}
