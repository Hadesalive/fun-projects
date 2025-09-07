import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/navigation/app_router.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final ApiService _apiService = ApiService();
  
  List<Map<String, dynamic>> _groups = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _apiService.getGroupConversations();
      
      if (result.success) {
        setState(() {
          _groups = List<Map<String, dynamic>>.from(result.data ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result.error;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load groups: $e';
        _isLoading = false;
      });
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

  String _formatMemberCount(int count) {
    if (count == 1) return '1 member';
    return '$count members';
  }

  int _safeMemberCount(dynamic members) {
    try {
      if (members == null) return 0;
      if (members is List) return members.length;
      if (members is int) return members;
      return 0;
    } catch (e) {
      print('Error getting member count: $e');
      return 0;
    }
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(
            CupertinoIcons.back,
            color: AppColors.systemBlue,
            size: 22,
          ),
        ),
        title: Text(
          'My Groups',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => context.push(AppRouter.createGroup),
            icon: Icon(
              CupertinoIcons.add,
              color: AppColors.systemBlue,
              size: 22,
            ),
          ),
        ],
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
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
              'Error Loading Groups',
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
              onPressed: _loadGroups,
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

    if (_groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.group,
              size: 64,
              color: AppColors.systemGray,
            ),
            const SizedBox(height: 16),
            Text(
              'No Groups Yet',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first group to get started',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppColors.systemGray,
              ),
            ),
            const SizedBox(height: 24),
            CupertinoButton(
              onPressed: () => context.push(AppRouter.createGroup),
              color: AppColors.systemBlue,
              borderRadius: BorderRadius.circular(12),
              child: Text(
                'Create Group',
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

    return RefreshIndicator(
      onRefresh: _loadGroups,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _groups.length,
        itemBuilder: (context, index) {
          final group = _groups[index];
          return _buildGroupTile(group, isDark);
        },
      ),
    );
  }

  Widget _buildGroupTile(Map<String, dynamic> group, bool isDark) {
    try {
      final groupName = group['name']?.toString() ?? 'Unnamed Group';
      final description = group['description']?.toString() ?? '';
      final avatarUrl = group['avatarUrl'] as String?;
      final memberCount = _safeMemberCount(group['members']);
      final lastMessage = group['lastMessage'] as Map<String, dynamic>?;
      final updatedAt = group['updatedAt'] as String?;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.lightImpact();
            final groupId = group['id'] ?? group['_id'] ?? '';
            context.push('${AppRouter.groupChat}?groupId=$groupId&groupName=${Uri.encodeComponent(groupName)}&memberCount=$memberCount${avatarUrl != null ? '&avatarUrl=${Uri.encodeComponent(avatarUrl)}' : ''}');
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Group Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.systemBlue.withOpacity(0.1),
                  ),
                  child: avatarUrl != null && avatarUrl.isNotEmpty
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: avatarUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppColors.systemBlue.withOpacity(0.1),
                              child: Center(
                                child: Text(
                                  _getGroupInitials(groupName),
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.systemBlue,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Center(
                              child: Text(
                                _getGroupInitials(groupName),
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.systemBlue,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            _getGroupInitials(groupName),
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppColors.systemBlue,
                            ),
                          ),
                        ),
                ),
                
                const SizedBox(width: 16),
                
                // Group Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        groupName,
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatMemberCount(memberCount),
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: AppColors.systemGray,
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
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
                
                // Chevron
                Icon(
                  CupertinoIcons.chevron_right,
                  color: AppColors.systemGray,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    } catch (e) {
      print('Error building group tile: $e');
      // Return a safe fallback tile
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.systemGray.withOpacity(0.3),
                  ),
                  child: Center(
                    child: Text(
                      'G',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.systemGray,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Error loading group',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                        ),
                      ),
                      Text(
                        'Tap to retry',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: AppColors.systemGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
