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

class EnhancedMessagesScreen extends StatefulWidget {
  const EnhancedMessagesScreen({super.key});

  @override
  State<EnhancedMessagesScreen> createState() => _EnhancedMessagesScreenState();
}

class _EnhancedMessagesScreenState extends State<EnhancedMessagesScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _contactSearchController = TextEditingController();
  late AnimationController _refreshController;
  bool _isSearching = false;
  List<String> _filteredContacts = [];
  List<String> _filteredUsernames = [];

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _contactSearchController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    HapticFeedback.lightImpact();
    _refreshController.forward();
    await Future.delayed(const Duration(seconds: 2));
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
              child: ListView.builder(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                itemCount: _getMockConversations().length,
                itemBuilder: (context, index) {
                  final conversations = _getMockConversations();
                  return _MessageTile(
                    conversation: conversations[index],
                    onTap: () => _navigateToChat(context, conversations[index]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewChatSheet(context),
        backgroundColor: AppColors.systemBlue,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(
          CupertinoIcons.plus,
          size: 28,
        ),
      ),
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

  List<MockConversation> _getMockConversations() {
    return [
      MockConversation(
        id: '1',
        name: 'Emma Wilson',
        avatarUrl: 'https://i.pravatar.cc/200?img=1',
        lastMessage: 'Hey! How are you doing today?',
        time: '2m',
        unreadCount: 3,
        isOnline: true,
      ),
      MockConversation(
        id: '2',
        name: 'Alex Chen',
        avatarUrl: 'https://i.pravatar.cc/200?img=2',
        lastMessage: 'Thanks for the help yesterday!',
        time: '15m',
        unreadCount: 1,
        isOnline: true,
      ),
      MockConversation(
        id: '3',
        name: 'Sarah Johnson',
        avatarUrl: 'https://i.pravatar.cc/200?img=3',
        lastMessage: 'You: See you at 6pm!',
        time: '1h',
        isOnline: false,
      ),
      MockConversation(
        id: '4',
        name: 'Design Team',
        avatarUrl: 'https://i.pravatar.cc/200?img=4',
        lastMessage: 'Mike: The new mockups look great',
        time: '2h',
        unreadCount: 5,
        isOnline: false,
      ),
    ];
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
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
                color: Colors.grey[300],
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
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(CupertinoIcons.xmark),
                  ),
                ],
              ),
            ),
            
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
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
                  controller: _contactSearchController,
                  onChanged: _filterContacts,
                  decoration: InputDecoration(
                    hintText: 'Search contacts',
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
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Contacts list
            Expanded(
              child: ListView.builder(
                itemCount: _getFilteredContacts().length,
                itemBuilder: (context, index) {
                  final contacts = _getFilteredContacts();
                  final usernames = _getFilteredUsernames();
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: CachedNetworkImageProvider('https://i.pravatar.cc/200?img=${index + 1}'),
                    ),
                    title: Text(contacts[index]),
                    subtitle: Text('@${usernames[index]}'),
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to chat with this contact
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
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