import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/socket_service.dart';
import '../../../shared/widgets/cupertino_toast.dart';
import 'dart:async';

class EnhancedMessagesScreen extends StatefulWidget {
  const EnhancedMessagesScreen({super.key});

  @override
  State<EnhancedMessagesScreen> createState() => _EnhancedMessagesScreenState();
}

class _EnhancedMessagesScreenState extends State<EnhancedMessagesScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _contactSearchController = TextEditingController();
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();
  late AnimationController _refreshController;
  
  bool _isSearching = false;
  bool _isLoading = true;
  bool _isSyncing = false;
  String? _error;
  String? _currentUserId;
  List<Map<String, dynamic>> _conversations = [];
  List<String> _filteredContacts = [];
  List<String> _filteredUsernames = [];
  
  // Stream subscriptions
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;
  StreamSubscription<Map<String, dynamic>>? _errorSubscription;
  Timer? _connectionCheckTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _loadConversations();
    _loadCurrentUser();
    _setupSocketConnection();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh conversations when app comes back to foreground
      _loadConversations();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _searchController.dispose();
    _contactSearchController.dispose();
    _refreshController.dispose();
    
    // Clean up socket connections
    _messageSubscription?.cancel();
    _errorSubscription?.cancel();
    _connectionCheckTimer?.cancel();
    
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final result = await _apiService.getCurrentUser();
      if (result.success && result.data != null) {
        final user = result.data as Map<String, dynamic>;
        setState(() {
          _currentUserId = user['id'] as String?;
        });
        print('✅ Current user ID loaded: $_currentUserId');
      }
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _apiService.getUserConversations();
      
      if (result.success && result.data != null) {
        final conversationsList = result.data as List<dynamic>;
        
        setState(() {
          _conversations = conversationsList.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
        
        // Sync unread counts for all conversations to ensure accuracy
        _syncUnreadCounts();
      } else {
        setState(() {
          _error = result.error ?? 'Failed to load conversations';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load conversations: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _syncUnreadCounts() async {
    if (_conversations.isEmpty || _isSyncing) return;
    
    setState(() {
      _isSyncing = true;
    });
    
    print('🔄 Syncing unread counts for ${_conversations.length} conversations...');
    
    bool hasUpdates = false;
    final List<Map<String, dynamic>> updatedConversations = [];
    
    for (final conversation in _conversations) {
      final conversationId = conversation['_id'] as String? ?? conversation['id'] as String?;
      if (conversationId != null) {
        try {
          final result = await _apiService.syncUnreadCount(conversationId);
          if (result.success && result.data != null) {
            final unreadCount = result.data['unreadCount'] as int? ?? 0;
            final currentUnreadCount = conversation['unreadCount'] as int? ?? 0;
            
            // Create updated conversation object
            final updatedConversation = Map<String, dynamic>.from(conversation);
            updatedConversation['unreadCount'] = unreadCount;
            updatedConversations.add(updatedConversation);
            
            if (unreadCount != currentUnreadCount) {
              hasUpdates = true;
              print('📊 Updated unread count for conversation $conversationId: $currentUnreadCount -> $unreadCount');
            }
          } else {
            updatedConversations.add(conversation);
          }
        } catch (e) {
          print('❌ Failed to sync unread count for conversation $conversationId: $e');
          updatedConversations.add(conversation);
        }
      } else {
        updatedConversations.add(conversation);
      }
    }
    
    // Update the entire conversations list if there were any changes
    if (hasUpdates) {
      setState(() {
        _conversations = updatedConversations;
      });
      print('✅ Updated conversations list with synced unread counts');
    }
    
    setState(() {
      _isSyncing = false;
    });
  }

  Future<void> _setupSocketConnection() async {
    print('🔌 Setting up Socket.IO connection in messages screen...');
    
    // Connect to socket if not already connected
    await _socketService.connect();
    
    // Wait a bit for connection to establish
    await Future.delayed(const Duration(milliseconds: 2000));
    
    print('📡 Socket connection status: ${_socketService.isConnected}');
    
    if (!_socketService.isConnected) {
      print('❌ Socket not connected, retrying...');
      await _socketService.connect();
      await Future.delayed(const Duration(milliseconds: 2000));
      print('📡 Socket connection status after retry: ${_socketService.isConnected}');
    }
    
    // Set up message listeners for real-time updates
    _messageSubscription = _socketService.messageStream.listen((event) {
      print('📨 Message received in messages screen: $event');
      _handleSocketMessage(event);
    });
    
    // Set up error listeners
    _errorSubscription = _socketService.errorStream.listen((event) {
      print('❌ Socket error in messages screen: $event');
      _handleSocketError(event);
    });
    
    // Set up connection status listener
    _socketService.connectionStream.listen((isConnected) {
      print('🔌 Socket connection status changed: $isConnected');
      if (isConnected) {
        print('✅ Socket connected, refreshing conversations...');
        _loadConversations();
      }
    });
    
    print('✅ Socket.IO listeners set up in messages screen');
    
    // Start periodic connection check
    _connectionCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_socketService.isConnected) {
        print('🔄 Socket disconnected, attempting to reconnect...');
        _socketService.connect();
      }
    });
  }

  void _handleSocketMessage(Map<String, dynamic> event) {
    final type = event['type'] as String;
    final data = event['data'] as Map<String, dynamic>;
    
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
    }
  }

  void _handleNewMessage(Map<String, dynamic> data) {
    try {
      print('🔄 Processing new message in messages screen...');
      print('📨 Raw data received: $data');
      
      // Normalize payload
      final normalized = Map<String, dynamic>.from(data);
      if (normalized['conversation'] == null && normalized['conversationId'] != null) {
        normalized['conversation'] = normalized['conversationId'];
      }
      if (normalized['type'] == 'text') {
        final content = normalized['content'];
        if (content is String) {
          normalized['content'] = { 'text': content };
        }
      }
      if (normalized['createdAt'] == null) {
        normalized['createdAt'] = DateTime.now().toIso8601String();
      }

      final conversationId = normalized['conversation'] as String;
      final messageContent = normalized['content'] as Map<String, dynamic>;
      final messageText = messageContent['text'] as String? ?? '';
      final sender = data['sender'] as Map<String, dynamic>;
      final senderName = sender['displayName'] as String? ?? sender['username'] as String? ?? 'Unknown';
      final createdAt = DateTime.parse(normalized['createdAt'] as String);
      
      print('📝 Message details:');
      print('  - Conversation ID: $conversationId');
      print('  - Message: $messageText');
      print('  - Sender: $senderName');
      print('  - Current conversations count: ${_conversations.length}');
      
      // Update the conversation in the list
      setState(() {
        final conversationIndex = _conversations.indexWhere(
          (conv) => (conv['_id'] as String? ?? conv['id'] as String?) == conversationId
        );
        
        print('🔍 Conversation index found: $conversationIndex');
        
        if (conversationIndex != -1) {
          // Update existing conversation
          final currentUnreadCount = _conversations[conversationIndex]['unreadCount'] as int? ?? 0;
          print('📊 Current unread count: $currentUnreadCount');
          
          _conversations[conversationIndex] = {
            ..._conversations[conversationIndex],
            'lastMessage': {
              'text': messageText,
              'sender': senderName,
              'type': 'text',
              'content': {'text': messageText},
            },
            'lastActivity': createdAt.toIso8601String(),
            'unreadCount': currentUnreadCount + 1,
          };
          
          // Move conversation to top
          final updatedConversation = _conversations.removeAt(conversationIndex);
          _conversations.insert(0, updatedConversation);
          
          print('✅ Conversation updated and moved to top');
          print('📊 New unread count: ${_conversations[0]['unreadCount']}');
        } else {
          print('⚠️ Conversation not found, reloading conversations...');
          // This shouldn't happen, but if it does, reload conversations
          _loadConversations();
        }
      });
    } catch (e) {
      print('❌ Error handling new message in messages screen: $e');
    }
  }

  void _handleEditedMessage(Map<String, dynamic> data) {
    // For now, just reload conversations to get updated content
    _loadConversations();
  }

  void _handleDeletedMessage(Map<String, dynamic> data) {
    // For now, just reload conversations
    _loadConversations();
  }

  void _handleReadMessage(Map<String, dynamic> data) {
    try {
      print('👁️ Processing read message in messages screen...');
      final conversationId = data['conversationId'] as String?;
      final unreadCounts = data['unreadCounts'] as List<dynamic>?;
      
      if (conversationId == null || unreadCounts == null) return;
      
      print('📊 Updating unread counts for conversation: $conversationId');
      print('📊 Unread counts data: $unreadCounts');
      
      // Find the current user's unread count
      int? newUnreadCount;
      for (final countData in unreadCounts) {
        final userId = countData['userId'] as String?;
        final unreadCount = countData['unreadCount'] as int? ?? 0;
        
        if (userId == _currentUserId) {
          newUnreadCount = unreadCount;
          break;
        }
      }
      
      if (newUnreadCount != null) {
        setState(() {
          final conversationIndex = _conversations.indexWhere(
            (conv) => (conv['_id'] as String? ?? conv['id'] as String?) == conversationId
          );
          
          if (conversationIndex != -1) {
            // Create a new conversation object to ensure UI updates
            final updatedConversation = Map<String, dynamic>.from(_conversations[conversationIndex]);
            updatedConversation['unreadCount'] = newUnreadCount;
            _conversations[conversationIndex] = updatedConversation;
            print('✅ Updated unread count for current user: $newUnreadCount');
          } else {
            print('⚠️ Conversation not found for read update: $conversationId');
          }
        });
      }
    } catch (e) {
      print('❌ Error handling read message in messages screen: $e');
    }
  }

  void _handleSocketError(Map<String, dynamic> event) {
    final type = event['type'] as String;
    final message = event['message'] as String;
    
    print('Socket error in messages screen: $type - $message');
    
    // Show error to user
    if (mounted) {
      CupertinoToast.show(
        context,
        'Connection error: $message',
        type: CupertinoToastType.error,
      );
    }
  }

  Future<void> _testSocketConnection() async {
    print('🧪 Testing Socket.IO connection...');
    print('📡 Current connection status: ${_socketService.isConnected}');
    
    if (!_socketService.isConnected) {
      print('🔄 Attempting to reconnect...');
      await _socketService.connect();
      await Future.delayed(const Duration(milliseconds: 2000));
      print('📡 New connection status: ${_socketService.isConnected}');
    }
    
    if (mounted) {
      CupertinoToast.show(
        context,
        _socketService.isConnected ? 'Socket connected ✅' : 'Socket disconnected ❌',
        type: _socketService.isConnected ? CupertinoToastType.success : CupertinoToastType.error,
      );
    }
  }

  Future<void> _onRefresh() async {
    HapticFeedback.lightImpact();
    _refreshController.forward();
    await _loadConversations();
    _refreshController.reset();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        centerTitle: false,
        title: Text(
          'Messages',
          style: GoogleFonts.inter(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _testSocketConnection();
            },
            icon: Icon(
              CupertinoIcons.wifi,
              color: _socketService.isConnected ? AppColors.systemGreen : AppColors.systemRed,
              size: 22,
            ),
          ),
          IconButton(
            onPressed: () {
              _loadConversations();
            },
            icon: Icon(
              CupertinoIcons.refresh,
              color: AppColors.systemBlue,
              size: 22,
            ),
          ),
          IconButton(
            onPressed: () => context.push(AppRouter.discover),
            icon: Icon(
              CupertinoIcons.search,
              color: AppColors.systemBlue,
              size: 22,
            ),
          ),
          IconButton(
            onPressed: () => context.push(AppRouter.profile),
            icon: Icon(
              CupertinoIcons.gear_alt,
              color: AppColors.systemBlue,
              size: 22,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: _buildCleanSearchBar(),
          ),
          
          // Messages List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: _buildConversationsList(),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildCleanSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSecondaryBackground : AppColors.lightSecondaryBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.5,
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.inter(
          fontSize: 16,
          color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
        ),
        decoration: InputDecoration(
          hintText: 'Search',
          hintStyle: GoogleFonts.inter(
            fontSize: 16,
            color: AppColors.systemGray,
          ),
          prefixIcon: Icon(
            CupertinoIcons.search,
            color: AppColors.systemGray,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }

  void _filterContacts(String query) {
    setState(() {
      final allContacts = ['Emma Wilson', 'Alex Chen', 'Sarah Johnson', 'Mike Davis', 'Lisa Brown', 'Tom Wilson'];
      final allUsernames = ['emma_w', 'alex_c', 'sarah_j', 'mike_d', 'lisa_b', 'tom_w'];
      
      if (query.isEmpty) {
        _filteredContacts = allContacts.take(3).toList();
        _filteredUsernames = allUsernames.take(3).toList();
      } else {
        _filteredContacts = [];
        _filteredUsernames = [];
        
        for (int i = 0; i < allContacts.length; i++) {
          if (allContacts[i].toLowerCase().contains(query.toLowerCase()) ||
              allUsernames[i].toLowerCase().contains(query.toLowerCase())) {
            _filteredContacts.add(allContacts[i]);
            _filteredUsernames.add(allUsernames[i]);
          }
        }
      }
    });
  }

  List<String> _getFilteredContacts() {
    if (_filteredContacts.isEmpty && _contactSearchController.text.isEmpty) {
      return ['Emma Wilson', 'Alex Chen', 'Sarah Johnson'];
    }
    return _filteredContacts;
  }

  List<String> _getFilteredUsernames() {
    if (_filteredUsernames.isEmpty && _contactSearchController.text.isEmpty) {
      return ['emma_w', 'alex_c', 'sarah_j'];
    }
    return _filteredUsernames;
  }

  Widget _buildConversationsList() {
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
                color: Theme.of(context).brightness == Brightness.dark 
                    ? AppColors.darkSecondaryText 
                    : AppColors.lightSecondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadConversations,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_conversations.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final conversation = _conversations[index];
        return _RealConversationTile(
          conversation: conversation,
          onTap: () => _navigateToRealChat(context, conversation),
          onDelete: (conversationId) => _deleteConversation(context, conversationId),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated icon container
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.systemBlue.withOpacity(0.1),
                    AppColors.systemBlue.withOpacity(0.05),
                  ],
                ),
                border: Border.all(
                  color: AppColors.systemBlue.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                CupertinoIcons.chat_bubble_2,
                size: 48,
                color: AppColors.systemBlue.withOpacity(0.7),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Main heading
            Text(
              'Welcome to Liora!',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Subtitle
            Text(
              'No conversations yet',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // Description
            Text(
              'Start connecting with friends and family.\nYour conversations will appear here.',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppColors.systemGray,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 40),
            
            // Action buttons
            Column(
              children: [
                // Create Group button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      context.push(AppRouter.groups);
                    },
                    icon: Icon(
                      CupertinoIcons.group,
                      size: 20,
                      color: Colors.white,
                    ),
                    label: Text(
                      'Create a Group',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.systemBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // New Chat button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _showNewChatSheet(context);
                    },
                    icon: Icon(
                      CupertinoIcons.add,
                      size: 20,
                      color: AppColors.systemBlue,
                    ),
                    label: Text(
                      'Start New Chat',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.systemBlue,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.systemBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: AppColors.systemBlue.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Features list
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark 
                    ? AppColors.darkSecondaryBackground.withOpacity(0.5)
                    : AppColors.lightSecondaryBackground.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark 
                      ? AppColors.darkBorder.withOpacity(0.3)
                      : AppColors.lightBorder.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'What you can do:',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem(
                    icon: CupertinoIcons.group,
                    title: 'Create Groups',
                    description: 'Start group conversations with multiple people',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    icon: CupertinoIcons.chat_bubble,
                    title: 'Direct Messages',
                    description: 'Have private conversations with friends',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    icon: CupertinoIcons.bell,
                    title: 'Stay Connected',
                    description: 'Get notified when you receive new messages',
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.systemBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: AppColors.systemBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.systemGray,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.systemBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.lightImpact();
          _showNewChatSheet(context);
        },
        backgroundColor: AppColors.systemBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: const Icon(
          CupertinoIcons.add,
          size: 24,
        ),
        label: Text(
          'New Chat',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _navigateToRealChat(BuildContext context, Map<String, dynamic> conversation) {
    HapticFeedback.lightImpact();
    
    final conversationType = conversation['type'] as String? ?? 'direct';
    final conversationId = conversation['_id'] as String? ?? conversation['id'] as String?;
    
    // Reset unread count when opening conversation
    _resetUnreadCount(conversationId);
    
    if (conversationType == 'group') {
      // Navigate to group chat
      final groupName = conversation['name'] as String? ?? 'Group';
      final memberCount = (conversation['members'] as List<dynamic>?)?.length ?? 0;
      final avatarUrl = conversation['avatarUrl'] as String?;
      
      context.push(
        Uri(
          path: AppRouter.groupChat,
          queryParameters: {
            'groupId': conversationId ?? '',
            'groupName': groupName,
            'memberCount': memberCount.toString(),
            if (avatarUrl != null) 'avatarUrl': avatarUrl,
          },
        ).toString(),
      );
    } else {
      // Navigate to direct chat (enhanced chat screen)
      final peerName = _getPeerName(conversation);
      final peerAvatarUrl = _getPeerAvatarUrl(conversation);
      
      context.push(
        Uri(
          path: AppRouter.chat,
          queryParameters: {
            'conversationId': conversationId ?? '',
            'avatarUrl': peerAvatarUrl ?? '',
          },
        ).toString(),
        extra: peerName,
      );
    }
  }

  void _resetUnreadCount(String? conversationId) {
    if (conversationId == null) return;
    
    setState(() {
      final conversationIndex = _conversations.indexWhere(
        (conv) => (conv['_id'] as String? ?? conv['id'] as String?) == conversationId
      );
      
      if (conversationIndex != -1) {
        _conversations[conversationIndex] = {
          ..._conversations[conversationIndex],
          'unreadCount': 0,
        };
        print('✅ Reset unread count for conversation: $conversationId');
      }
    });
  }

  String _getPeerName(Map<String, dynamic> conversation) {
    // For direct conversations, get the other participant's name
    final members = conversation['members'] as List<dynamic>? ?? [];
    if (members.isNotEmpty) {
      final member = members.first as Map<String, dynamic>? ?? {};
      final user = member['user'] as Map<String, dynamic>? ?? {};
      return user['displayName'] as String? ?? user['username'] as String? ?? 'Unknown';
    }
    return 'Unknown';
  }

  String? _getPeerAvatarUrl(Map<String, dynamic> conversation) {
    // For direct conversations, get the other participant's avatar
    final members = conversation['members'] as List<dynamic>? ?? [];
    if (members.isNotEmpty) {
      final member = members.first as Map<String, dynamic>? ?? {};
      final user = member['user'] as Map<String, dynamic>? ?? {};
      return user['avatarUrl'] as String?;
    }
    return null;
  }

  void _navigateToChat(BuildContext context, MockConversation conversation) {
    HapticFeedback.lightImpact();
    final location = Uri(
      path: AppRouter.chat,
      queryParameters: {'avatarUrl': conversation.avatarUrl},
    ).toString();
    context.push(
      location,
      extra: conversation.name,
    );
  }

  void _showNewChatSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _NewChatSheet(),
    );
  }

  void _deleteConversation(BuildContext context, String? conversationId) {
    if (conversationId == null) return;

    // Remove conversation from the list immediately
    setState(() {
      _conversations.removeWhere((conversation) {
        final id = conversation['_id'] as String? ?? conversation['id'] as String?;
        return id == conversationId;
      });
    });

    // Here you would typically call an API to delete the conversation
    // For now, we'll just show a cupertino-style toast
    CupertinoToast.show(context, 'Conversation deleted successfully', type: CupertinoToastType.success);
  }
}

class _NewChatSheet extends StatefulWidget {
  @override
  State<_NewChatSheet> createState() => _NewChatSheetState();
}

class _NewChatSheetState extends State<_NewChatSheet> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ApiService _apiService = ApiService();
  
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String _searchQuery = '';
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadCurrentUser();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  Future<void> _loadCurrentUser() async {
    try {
      final result = await _apiService.getCurrentUser();
      if (result.success && result.data != null) {
        final user = result.data as Map<String, dynamic>;
        setState(() {
          _currentUserId = user['_id'] as String?;
        });
      }
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    setState(() {
      _searchQuery = query;
      _isSearching = query.isNotEmpty;
    });
    
    if (query.isNotEmpty) {
      _searchUsers(query);
    } else {
      setState(() {
        _searchResults = [];
      });
    }
  }

  Future<void> _searchUsers(String query) async {
    try {
      final result = await _apiService.searchUsers(query);
      
      if (result.success && result.data != null) {
        final users = result.data as List<dynamic>;
        final userList = users.cast<Map<String, dynamic>>();
        
        // Filter out current user from search results
        final filteredUsers = userList.where((user) {
          final userId = user['id'] as String?;
          final isNotCurrentUser = userId != _currentUserId;
          if (!isNotCurrentUser) {
            print('🚫 Filtered out current user: ${user['displayName']} (${user['username']})');
          }
          return isNotCurrentUser;
        }).toList();
        
        print('🔍 Search Results: ${userList.length} total, ${filteredUsers.length} after filtering');
        
        setState(() {
          _searchResults = filteredUsers;
        });
      }
    } catch (e) {
      print('Error searching users: $e');
    }
  }

  Future<void> _startChat(Map<String, dynamic> user) async {
    Navigator.pop(context);
    
    final userId = user['id'] as String?; // Changed from '_id' to 'id'
    if (userId == null) {
      _showErrorDialog('User ID not found');
      return;
    }

    print('🚀 Starting conversation with user: ${user['displayName']} (ID: $userId)');

    bool isCancelled = false;

    // Show loading indicator with cancel option
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Starting conversation...',
                style: GoogleFonts.inter(fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  isCancelled = true;
                  Navigator.of(context).pop();
                  print('🚫 User cancelled conversation creation');
                },
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.systemRed,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      print('📞 Calling createDirectConversation API...');
      
      // Add timeout to prevent infinite loading
      final result = await _apiService.createDirectConversation(userId)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Conversation creation timed out', const Duration(seconds: 10));
            },
          );
      
      print('📞 API call completed. Success: ${result.success}');
      print('📞 Error: ${result.error}');
      print('📞 Data: ${result.data}');
      
      // Check if user cancelled the operation
      if (isCancelled) {
        print('🚫 Operation was cancelled by user, skipping navigation');
        return;
      }
      
      if (result.success && result.data != null) {
        print('✅ Conversation creation successful');
        print('  - Message: ${result.message}');
        print('  - Data type: ${result.data.runtimeType}');
        final conversation = result.data as Map<String, dynamic>;
        final conversationId = conversation['_id'] as String;
        
        print('🔍 Navigation Debug:');
        print('  - Conversation ID: $conversationId');
        print('  - User: ${user['displayName']}');
        print('  - Avatar: ${user['avatarUrl']}');
        
        // Navigate to chat screen directly without dismissing dialog first
        final displayName = user['displayName'] as String? ?? 'Unknown User';
        final avatarUrl = user['avatarUrl'] as String? ?? '';
        
        final uri = Uri(
          path: '/chat',
          queryParameters: {
            'conversationId': conversationId,
            'avatarUrl': avatarUrl,
          },
        );
        
        print('  - Final URI: ${uri.toString()}');
        
        // Navigate directly - dismiss dialog and navigate
        if (mounted) {
          // Dismiss the loading dialog first
          Navigator.of(context).pop();
          
          // Small delay to ensure dialog is dismissed before navigation
          await Future.delayed(const Duration(milliseconds: 100));
          
          // Navigate to chat screen
          if (mounted) {
            context.push(uri.toString(), extra: displayName);
          }
        }
      } else {
        print('❌ Conversation creation failed: ${result.error}');
        
        // Dismiss loading dialog and show error
        if (mounted) {
          Navigator.of(context).pop();
          _showErrorDialog(result.error ?? 'Failed to start conversation');
        }
      }
    } catch (e) {
      print('❌ Exception in _startChat: $e');
      
      // Check if widget is still mounted before proceeding
      if (!mounted) {
        print('⚠️ Widget not mounted, cannot show error dialog');
        return;
      }
      
      // Dismiss loading dialog
      Navigator.of(context).pop();
      
      String errorMessage = 'Failed to start conversation';
      if (e is TimeoutException) {
        errorMessage = 'Request timed out. Please try again.';
      } else {
        errorMessage = 'Failed to start conversation: ${e.toString()}';
      }
      
      _showErrorDialog(errorMessage);
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.75 + keyboardHeight,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                  'New Message',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    CupertinoIcons.xmark_circle_fill,
                    color: AppColors.systemGray,
                    size: 28,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
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
                borderRadius: BorderRadius.circular(16),
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
                    padding: const EdgeInsets.only(left: 16),
                    child: Icon(
                      CupertinoIcons.search,
                      color: _searchFocusNode.hasFocus ? AppColors.systemBlue : AppColors.systemGray,
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Search by name or username...',
                        hintStyle: GoogleFonts.inter(
                          color: AppColors.systemGray,
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                      ),
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
          
          // Quick Actions
          if (!_isSearching) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _QuickActionButton(
                    icon: CupertinoIcons.group,
                    label: 'New Group',
                    color: AppColors.systemGreen,
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppRouter.groups);
                    },
                  ),
                  const SizedBox(width: 16),
                  _QuickActionButton(
                    icon: CupertinoIcons.qrcode,
                    label: 'QR Code',
                    color: AppColors.systemOrange,
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Show QR code scanner
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Suggested',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // Search Results / Suggested Contacts
          Expanded(
            child: _isSearching
                ? _buildSearchResults(isDark)
                : _buildSuggestedContacts(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(bool isDark) {
    if (_searchResults.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
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
              'No users found',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with a different name or username',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppColors.systemGray,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return _UserTile(
          user: user,
          onTap: () => _startChat(user),
        );
      },
    );
  }

  Widget _buildSuggestedContacts(bool isDark) {
    // For now, show placeholder suggested contacts
    final suggestedContacts = [
      {'displayName': 'John Doe', 'username': 'johndoe', 'avatarUrl': null},
      {'displayName': 'Jane Smith', 'username': 'janesmith', 'avatarUrl': null},
      {'displayName': 'Bob Wilson', 'username': 'bobwilson', 'avatarUrl': null},
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: suggestedContacts.length,
      itemBuilder: (context, index) {
        final user = suggestedContacts[index];
        return _UserTile(
          user: user,
          onTap: () => _startChat(user),
        );
      },
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onTap;

  const _UserTile({
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayName = user['displayName'] as String? ?? 'Unknown';
    final username = user['username'] as String? ?? '';
    final avatarUrl = user['avatarUrl'] as String?;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                backgroundColor: AppColors.systemBlue.withOpacity(0.1),
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? Text(
                        _getInitials(displayName),
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
                  children: [
                    Text(
                      displayName,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (username.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '@$username',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.systemGray,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chat_bubble,
                color: AppColors.systemBlue,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}

class _RealConversationTile extends StatelessWidget {
  final Map<String, dynamic> conversation;
  final VoidCallback onTap;
  final Function(String?) onDelete;

  const _RealConversationTile({
    required this.conversation,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final conversationType = conversation['type'] as String? ?? 'direct';
    final name = _getDisplayName();
    final avatarUrl = _getAvatarUrl();
    final lastMessage = _getLastMessage();
    final time = _getTimeString();
    final unreadCount = _getUnreadCount();
    final isOnline = _getOnlineStatus();
    final conversationId = conversation['_id'] as String? ?? conversation['id'] as String?;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Dismissible(
        key: Key('conversation_$conversationId'),
        direction: DismissDirection.endToStart,
        background: _buildDeleteBackground(isDark),
        confirmDismiss: (direction) {
          return _showDeleteConfirmation(context, name);
        },
        onDismissed: (direction) {
          onDelete(conversationId);
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Avatar
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                            ? NetworkImage(avatarUrl)
                            : null,
                        backgroundColor: AppColors.systemBlue.withOpacity(0.1),
                        child: avatarUrl == null || avatarUrl.isEmpty
                            ? Text(
                                _getInitials(name),
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.systemBlue,
                                ),
                              )
                            : null,
                      ),
                      if (isOnline && conversationType == 'direct')
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 14,
                            height: 14,
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

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              time,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: unreadCount > 0 ? AppColors.systemBlue : AppColors.systemGray,
                                fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                lastMessage,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: unreadCount > 0
                                      ? (isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText)
                                      : AppColors.systemGray,
                                  fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (unreadCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.systemBlue,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getDisplayName() {
    final conversationType = conversation['type'] as String? ?? 'direct';
    
    if (conversationType == 'group') {
      return conversation['name'] as String? ?? 'Group';
    } else {
      // For direct conversations, use the name provided by backend (already filtered)
      return conversation['name'] as String? ?? 'Unknown';
    }
  }

  String? _getAvatarUrl() {
    final conversationType = conversation['type'] as String? ?? 'direct';
    
    if (conversationType == 'group') {
      return conversation['avatarUrl'] as String?;
    } else {
      // For direct conversations, use the avatar provided by backend (already filtered)
      return conversation['avatarUrl'] as String?;
    }
  }

  String _getLastMessage() {
    final lastMessage = conversation['lastMessage'];
    if (lastMessage == null) return 'No messages yet';
    
    if (lastMessage is String) return lastMessage;
    
    if (lastMessage is Map<String, dynamic>) {
      // Check if it has a 'text' field directly (from our real-time updates)
      if (lastMessage['text'] != null) {
        return lastMessage['text'] as String;
      }
      
      // Check if it has a 'content' field with 'text' inside
      final content = lastMessage['content'] as Map<String, dynamic>? ?? {};
      final text = content['text'] as String?;
      if (text != null && text.isNotEmpty) return text;
      
      // Check for other message types
      final type = lastMessage['type'] as String? ?? 'text';
      switch (type) {
        case 'image':
          return '📷 Photo';
        case 'video':
          return '🎥 Video';
        case 'audio':
          return '🎵 Audio';
        case 'file':
          return '📎 File';
        default:
          return 'Message';
      }
    }
    
    return 'Message';
  }

  String _getTimeString() {
    final lastActivity = conversation['lastActivity'] as String?;
    if (lastActivity == null) return '';
    
    try {
      final dateTime = DateTime.parse(lastActivity);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d';
      } else {
        return '${(difference.inDays / 7).floor()}w';
      }
    } catch (e) {
      return '';
    }
  }

  int _getUnreadCount() {
    try {
      // Get unread count from conversation data
      final unreadCount = conversation['unreadCount'] as int? ?? 0;
      print('📊 Getting unread count for conversation: $unreadCount');
      return unreadCount;
    } catch (e) {
      print('❌ Error getting unread count: $e');
      return 0;
    }
  }

  bool _getOnlineStatus() {
    final conversationType = conversation['type'] as String? ?? 'direct';
    
    if (conversationType == 'group') {
      return false; // Groups don't have online status
    } else {
      // For direct conversations, get the other participant's online status
      final members = conversation['members'] as List<dynamic>? ?? [];
      if (members.isNotEmpty) {
        final member = members.first as Map<String, dynamic>? ?? {};
        final user = member['user'] as Map<String, dynamic>? ?? {};
        return user['isOnline'] as bool? ?? false;
      }
      return false;
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Widget _buildDeleteBackground(bool isDark) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      color: AppColors.systemRed,
      child: const Icon(
        CupertinoIcons.delete,
        color: Colors.white,
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context, String name) async {
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Delete Conversation'),
        content: Text('Are you sure you want to delete your conversation with $name? This action cannot be undone.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    return result ?? false;
  }

}

// Mock Data Classes
class MockConversation {
  final String id;
  final String name;
  final String avatarUrl;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final bool isOnline;

  MockConversation({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.lastMessage,
    required this.time,
    this.unreadCount = 0,
    this.isOnline = false,
  });
}

class _MessageTile extends StatelessWidget {
  final MockConversation conversation;
  final VoidCallback onTap;

  const _MessageTile({
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 0.5,
          ),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: CircleAvatar(
          radius: 26,
          backgroundImage: CachedNetworkImageProvider(conversation.avatarUrl),
          onBackgroundImageError: (exception, stackTrace) {
            // Handle image loading errors gracefully
          },
        ),
        title: Text(
          conversation.name,
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            conversation.lastMessage,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              conversation.time,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppColors.systemGray,
              ),
            ),
            if (conversation.unreadCount > 0) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.systemBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  conversation.unreadCount.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}