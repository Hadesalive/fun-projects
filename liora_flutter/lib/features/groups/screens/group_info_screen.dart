import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';

class GroupInfoScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String? groupAvatarUrl;
  final String? groupDescription;
  final int memberCount;

  const GroupInfoScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    this.groupAvatarUrl,
    this.groupDescription,
    required this.memberCount,
  });

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  bool _isMuted = false;
  bool _notificationsEnabled = true;
  
  Map<String, dynamic>? _conversationData;
  List<Map<String, dynamic>> _members = [];
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadGroupInfo();
  }

  Future<void> _loadGroupInfo() async {
    setState(() => _isLoading = true);
    
    try {
      // Load conversation details
      final result = await _apiService.getConversationDetails(widget.groupId);
      
      if (result.success && result.data != null) {
        final conversation = result.data as Map<String, dynamic>;
        setState(() {
          _conversationData = conversation;
          _members = _extractMembers(conversation);
          _isMuted = _getCurrentUserMember(conversation)?['isMuted'] ?? false;
        });
      } else {
        _showError(result.error ?? 'Failed to load group info');
      }
      
      // Load current user ID
      final userResult = await _apiService.getCurrentUser();
      if (userResult.success && userResult.data != null) {
        final user = userResult.data as Map<String, dynamic>;
        setState(() {
          _currentUserId = user['id'];
        });
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load group info: $e');
    }
  }

  List<Map<String, dynamic>> _extractMembers(Map<String, dynamic> conversation) {
    final members = conversation['members'] as List<dynamic>? ?? [];
    return members.map((member) {
      final user = member['user'] as Map<String, dynamic>;
      return {
        'id': user['_id'] ?? user['id'],
        'name': user['displayName'] ?? user['username'] ?? 'Unknown',
        'username': user['username'] ?? '',
        'avatarUrl': user['avatarUrl'],
        'isAdmin': member['role'] == 'admin',
        'isModerator': member['role'] == 'moderator',
        'isOnline': user['isOnline'] ?? false,
        'role': member['role'] ?? 'member',
        'joinedAt': member['joinedAt'],
        'isMuted': member['isMuted'] ?? false,
      };
    }).toList();
  }

  Map<String, dynamic>? _getCurrentUserMember(Map<String, dynamic> conversation) {
    if (_currentUserId == null) return null;
    
    final members = conversation['members'] as List<dynamic>? ?? [];
    for (final member in members) {
      final user = member['user'] as Map<String, dynamic>;
      if ((user['_id'] ?? user['id']) == _currentUserId) {
        return member as Map<String, dynamic>;
      }
    }
    return null;
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

  void _showSuccessMessage(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Success',
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

  void _showEditGroupModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditGroupModal(
        groupId: widget.groupId,
        currentName: _conversationData?['name'] ?? widget.groupName,
        currentDescription: _conversationData?['description'] ?? '',
        onUpdate: () {
          _loadGroupInfo(); // Reload group info after update
        },
      ),
    );
  }

  void _editGroupName() => _showEditGroupModal();
  void _editGroupDescription() => _showEditGroupModal();

  Future<void> _toggleMute(bool value) async {
    setState(() => _isMuted = value);
    HapticFeedback.lightImpact();
    
    try {
      // TODO: Implement API call to update member mute status
      // final result = await _apiService.updateMemberSettings(widget.groupId, _currentUserId!, {'isMuted': value});
      
      // Simulate API call for now
      await Future.delayed(const Duration(milliseconds: 300));
      
      _showSuccessMessage(_isMuted ? 'Group muted' : 'Group unmuted');
    } catch (e) {
      // Revert on error
      setState(() => _isMuted = !value);
      _showError('Failed to update notification settings');
    }
  }

  void _addMembers() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddMembersModal(
        groupId: widget.groupId,
        existingMemberIds: _members.map((member) => member['id'].toString()).toList(),
        onMembersAdded: () {
          _loadGroupInfo(); // Reload group info after adding members
        },
      ),
    );
  }

  void _leaveGroup() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Leave Group',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to leave "${_conversationData?['name'] ?? widget.groupName}"? You won\'t be able to see new messages.',
          style: GoogleFonts.inter(
            fontSize: 13,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontSize: 17,
                color: AppColors.systemBlue,
              ),
            ),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              Navigator.of(context).pop();
              
              if (_currentUserId != null) {
                final result = await _apiService.leaveGroup(widget.groupId, _currentUserId!);
                if (result.success) {
                  context.pop(); // Go back to chat
                  context.pop(); // Go back to groups list
                  _showSuccessMessage(result.message ?? 'Left group successfully');
                } else {
                  _showError(result.error ?? 'Failed to leave group');
                }
              } else {
                _showError('Unable to leave group: User not found');
              }
              HapticFeedback.lightImpact();
            },
            isDestructiveAction: true,
            child: Text(
              'Leave',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.systemRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final words = name.trim().split(' ').where((word) => word.isNotEmpty).toList();
    if (words.isEmpty) return 'U';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
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
          'Group Info',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Group Header
                  _buildGroupHeader(isDark),
                  
                  const SizedBox(height: 20),
                  
                  // Group Actions
                  _buildGroupActions(isDark),
                  
                  const SizedBox(height: 20),
                  
                  // Members Section
                  _buildMembersSection(isDark),
                  
                  const SizedBox(height: 20),
                  
                  // Settings Section
                  _buildSettingsSection(isDark),
                  
                  const SizedBox(height: 20),
                  
                  // Danger Zone
                  _buildDangerZone(isDark),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildGroupHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Group Avatar
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
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
                              _getInitials(widget.groupName),
                              style: GoogleFonts.inter(
                                fontSize: 36,
                                fontWeight: FontWeight.w600,
                                color: AppColors.systemBlue,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          _getInitials(widget.groupName),
                          style: GoogleFonts.inter(
                            fontSize: 36,
                            fontWeight: FontWeight.w600,
                            color: AppColors.systemBlue,
                          ),
                        ),
                      ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.systemBlue,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    CupertinoIcons.camera_fill,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Group Name
          InkWell(
            onTap: _editGroupName,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      _conversationData?['name'] ?? widget.groupName,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    CupertinoIcons.pencil,
                    size: 16,
                    color: AppColors.systemGray,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Group Description
          InkWell(
            onTap: _editGroupDescription,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      (_conversationData?['description']?.toString().isNotEmpty == true) 
                          ? _conversationData!['description']
                          : 'Add group description',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: (_conversationData?['description']?.toString().isNotEmpty == true) 
                            ? AppColors.systemGray
                            : AppColors.systemGray.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    CupertinoIcons.pencil,
                    size: 14,
                    color: AppColors.systemGray,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Created info
          Text(
            'Group • ${_members.length} members',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.systemGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupActions(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: CupertinoIcons.phone,
              label: 'Audio',
              onTap: () {
                HapticFeedback.lightImpact();
                _showError('Group audio call coming soon!');
              },
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: CupertinoIcons.video_camera,
              label: 'Video',
              onTap: () {
                HapticFeedback.lightImpact();
                _showError('Group video call coming soon!');
              },
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: CupertinoIcons.search,
              label: 'Search',
              onTap: () {
                HapticFeedback.lightImpact();
                _showError('Search messages coming soon!');
              },
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSecondaryBackground : AppColors.lightSecondaryBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: AppColors.systemBlue,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.systemBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersSection(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_members.length} MEMBERS',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.systemGray,
                    letterSpacing: -0.08,
                  ),
                ),
                InkWell(
                  onTap: _addMembers,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      CupertinoIcons.person_add,
                      size: 20,
                      color: AppColors.systemBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Members List
          ..._members.map((member) => _buildMemberTile(member, isDark)),
        ],
      ),
    );
  }

  Widget _buildMemberTile(Map<String, dynamic> member, bool isDark) {
    final isMe = member['id'] == _currentUserId;
    final isAdmin = member['isAdmin'] == true;
    final isModerator = member['isModerator'] == true;
    final isOnline = member['isOnline'] == true;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          if (!isMe) {
            _showError('Member profile coming soon!');
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.systemBlue.withOpacity(0.1),
                    ),
                    child: member['avatarUrl'] != null
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: member['avatarUrl'],
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Center(
                                child: Text(
                                  _getInitials(member['name']),
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.systemBlue,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              _getInitials(member['name']),
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.systemBlue,
                              ),
                            ),
                          ),
                  ),
                  if (isOnline && !isMe)
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
              
              const SizedBox(width: 16),
              
              // Member Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            isMe ? 'You' : member['name'],
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isAdmin) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.systemBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Admin',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.systemBlue,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${member['username']}',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppColors.systemGray,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Actions
              if (!isMe)
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 16,
                  color: AppColors.systemGray,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              'SETTINGS',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.systemGray,
                letterSpacing: -0.08,
              ),
            ),
          ),
          
          // Mute Notifications
          _buildSettingsTile(
            icon: _isMuted ? CupertinoIcons.bell_slash : CupertinoIcons.bell,
            title: 'Mute Notifications',
            trailing: Switch(
              value: _isMuted,
              onChanged: _toggleMute,
              activeColor: AppColors.systemBlue,
            ),
            isDark: isDark,
          ),
          
          // Media, Links, and Docs
          _buildSettingsTile(
            icon: CupertinoIcons.photo,
            title: 'Media, Links, and Docs',
            subtitle: '12 items',
            onTap: () {
              HapticFeedback.lightImpact();
              _showError('Media viewer coming soon!');
            },
            isDark: isDark,
          ),
          
          // Group Permissions
          _buildSettingsTile(
            icon: CupertinoIcons.lock_shield,
            title: 'Group Permissions',
            subtitle: 'Admin only',
            onTap: () {
              HapticFeedback.lightImpact();
              _showError('Group permissions coming soon!');
            },
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
          child: Row(
            children: [
              Icon(
                icon,
                size: 24,
                color: AppColors.systemBlue,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: AppColors.systemGray,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing
              else if (onTap != null)
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 16,
                  color: AppColors.systemGray,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDangerZone(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Leave Group
          _buildSettingsTile(
            icon: CupertinoIcons.square_arrow_left,
            title: 'Leave Group',
            onTap: _leaveGroup,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _EditGroupModal extends StatefulWidget {
  final String groupId;
  final String currentName;
  final String currentDescription;
  final VoidCallback onUpdate;

  const _EditGroupModal({
    required this.groupId,
    required this.currentName,
    required this.currentDescription,
    required this.onUpdate,
  });

  @override
  State<_EditGroupModal> createState() => _EditGroupModalState();
}

class _EditGroupModalState extends State<_EditGroupModal> {
  final ApiService _apiService = ApiService();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _descriptionFocusNode = FocusNode();
  
  bool _isLoading = false;
  bool _hasNameChanged = false;
  bool _hasDescriptionChanged = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _descriptionController = TextEditingController(text: widget.currentDescription);
    
    _nameController.addListener(_onNameChanged);
    _descriptionController.addListener(_onDescriptionChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _descriptionController.removeListener(_onDescriptionChanged);
    _nameController.dispose();
    _descriptionController.dispose();
    _nameFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    setState(() {
      _hasNameChanged = _nameController.text.trim() != widget.currentName.trim();
    });
  }

  void _onDescriptionChanged() {
    setState(() {
      _hasDescriptionChanged = _descriptionController.text.trim() != widget.currentDescription.trim();
    });
  }

  bool get _hasChanges => _hasNameChanged || _hasDescriptionChanged;

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

  void _showSuccessMessage(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Success',
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

  Future<void> _saveChanges() async {
    if (!_hasChanges || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      bool success = true;
      String successMessage = '';
      
      // Update name if changed
      if (_hasNameChanged) {
        final result = await _apiService.updateGroupName(widget.groupId, _nameController.text.trim());
        if (!result.success) {
          _showError(result.error ?? 'Failed to update group name');
          success = false;
        } else {
          successMessage = 'Group name updated';
        }
      }
      
      // Update description if changed and name update was successful
      if (success && _hasDescriptionChanged) {
        final result = await _apiService.updateGroupDescription(widget.groupId, _descriptionController.text.trim());
        if (!result.success) {
          _showError(result.error ?? 'Failed to update group description');
          success = false;
        } else {
          if (successMessage.isNotEmpty) {
            successMessage = 'Group info updated successfully';
          } else {
            successMessage = 'Group description updated';
          }
        }
      }
      
      if (success) {
        widget.onUpdate();
        Navigator.of(context).pop();
        _showSuccessMessage(successMessage);
        HapticFeedback.lightImpact();
      }
      
    } catch (e) {
      _showError('Failed to update group: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      duration: const Duration(milliseconds: 250),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 36,
                height: 5,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.systemGray.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          color: AppColors.systemGray,
                        ),
                      ),
                    ),
                    Text(
                      'Edit Group',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                      ),
                    ),
                    TextButton(
                      onPressed: _hasChanges && !_isLoading ? _saveChanges : null,
                      child: _isLoading
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.systemBlue),
                              ),
                            )
                          : Text(
                              'Save',
                              style: GoogleFonts.inter(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: _hasChanges ? AppColors.systemBlue : AppColors.systemGray,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // Form Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Group Name Section
                      Text(
                        'GROUP NAME',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.systemGray,
                          letterSpacing: -0.08,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSecondaryBackground : AppColors.lightSecondaryBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _nameFocusNode.hasFocus 
                                ? AppColors.systemBlue 
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: TextField(
                          controller: _nameController,
                          focusNode: _nameFocusNode,
                          maxLength: 50,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter group name',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 16,
                              color: AppColors.systemGray,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            counterText: '',
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Group Description Section
                      Text(
                        'GROUP DESCRIPTION',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.systemGray,
                          letterSpacing: -0.08,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSecondaryBackground : AppColors.lightSecondaryBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _descriptionFocusNode.hasFocus 
                                ? AppColors.systemBlue 
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: TextField(
                          controller: _descriptionController,
                          focusNode: _descriptionFocusNode,
                          maxLines: 4,
                          maxLength: 200,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Add group description (optional)',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 16,
                              color: AppColors.systemGray,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            counterText: '',
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddMembersModal extends StatefulWidget {
  final String groupId;
  final List<String> existingMemberIds;
  final VoidCallback onMembersAdded;

  const _AddMembersModal({
    required this.groupId,
    required this.existingMemberIds,
    required this.onMembersAdded,
  });

  @override
  State<_AddMembersModal> createState() => _AddMembersModalState();
}

class _AddMembersModalState extends State<_AddMembersModal> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _selectedUsers = [];
  bool _isSearching = false;
  bool _isAddingMembers = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query != _searchQuery) {
      setState(() => _searchQuery = query);
      if (query.isNotEmpty) {
        _searchUsers(query);
      } else {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _searchUsers(String query) async {
    setState(() => _isSearching = true);

    try {
      final result = await _apiService.searchUsers(query);
      
      if (result.success && result.data != null) {
        final users = result.data as List<dynamic>;
        
        // Filter out existing members
        final filteredUsers = users.where((user) {
          final userId = user['id']?.toString() ?? user['_id']?.toString() ?? '';
          return !widget.existingMemberIds.contains(userId);
        }).toList();
        
        setState(() {
          _searchResults = filteredUsers.cast<Map<String, dynamic>>();
          _isSearching = false;
        });
      } else {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  void _toggleUserSelection(Map<String, dynamic> user) {
    setState(() {
      final userId = user['id']?.toString() ?? user['_id']?.toString() ?? '';
      final existingIndex = _selectedUsers.indexWhere((selectedUser) => 
        (selectedUser['id']?.toString() ?? selectedUser['_id']?.toString() ?? '') == userId
      );
      
      if (existingIndex >= 0) {
        _selectedUsers.removeAt(existingIndex);
      } else {
        _selectedUsers.add(user);
      }
    });
    HapticFeedback.lightImpact();
  }

  bool _isUserSelected(Map<String, dynamic> user) {
    final userId = user['id']?.toString() ?? user['_id']?.toString() ?? '';
    return _selectedUsers.any((selectedUser) => 
      (selectedUser['id']?.toString() ?? selectedUser['_id']?.toString() ?? '') == userId
    );
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

  void _showSuccessMessage(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'Success',
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

  Future<void> _addSelectedMembers() async {
    if (_selectedUsers.isEmpty || _isAddingMembers) return;

    setState(() => _isAddingMembers = true);

    try {
      int successCount = 0;
      int totalCount = _selectedUsers.length;
      
      for (final user in _selectedUsers) {
        final userId = user['id']?.toString() ?? user['_id']?.toString() ?? '';
        final result = await _apiService.addMemberToGroup(widget.groupId, userId);
        
        if (result.success) {
          successCount++;
        }
      }
      
      if (successCount > 0) {
        widget.onMembersAdded();
        Navigator.of(context).pop();
        
        final message = successCount == totalCount 
            ? '${successCount == 1 ? 'Member' : 'Members'} added successfully'
            : '$successCount of $totalCount members added successfully';
        
        _showSuccessMessage(message);
        HapticFeedback.lightImpact();
      } else {
        _showError('Failed to add members to group');
      }
      
    } catch (e) {
      _showError('Failed to add members: $e');
    } finally {
      setState(() => _isAddingMembers = false);
    }
  }

  String _getInitials(String name) {
    final words = name.trim().split(' ').where((word) => word.isNotEmpty).toList();
    if (words.isEmpty) return 'U';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      duration: const Duration(milliseconds: 250),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Handle
              Container(
                width: 36,
                height: 5,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.systemGray.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          color: AppColors.systemGray,
                        ),
                      ),
                    ),
                    Text(
                      'Add Members',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                      ),
                    ),
                    TextButton(
                      onPressed: _selectedUsers.isNotEmpty && !_isAddingMembers ? _addSelectedMembers : null,
                      child: _isAddingMembers
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.systemBlue),
                              ),
                            )
                          : Text(
                              'Add (${_selectedUsers.length})',
                              style: GoogleFonts.inter(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: _selectedUsers.isNotEmpty ? AppColors.systemBlue : AppColors.systemGray,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSecondaryBackground : AppColors.lightSecondaryBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _searchFocusNode.hasFocus 
                          ? AppColors.systemBlue 
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search users by name or username...',
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
              
              // Selected Users (if any)
              if (_selectedUsers.isNotEmpty) ...[
                Container(
                  height: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SELECTED (${_selectedUsers.length})',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.systemGray,
                          letterSpacing: -0.08,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedUsers.length,
                          itemBuilder: (context, index) {
                            final user = _selectedUsers[index];
                            return Container(
                              margin: const EdgeInsets.only(right: 12),
                              child: Column(
                                children: [
                                  Stack(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.systemBlue.withOpacity(0.1),
                                        ),
                                        child: user['avatarUrl'] != null
                                            ? ClipOval(
                                                child: CachedNetworkImage(
                                                  imageUrl: user['avatarUrl'],
                                                  fit: BoxFit.cover,
                                                  errorWidget: (context, url, error) => Center(
                                                    child: Text(
                                                      _getInitials(user['displayName'] ?? user['username'] ?? 'U'),
                                                      style: GoogleFonts.inter(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w600,
                                                        color: AppColors.systemBlue,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : Center(
                                                child: Text(
                                                  _getInitials(user['displayName'] ?? user['username'] ?? 'U'),
                                                  style: GoogleFonts.inter(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.systemBlue,
                                                  ),
                                                ),
                                              ),
                                      ),
                                      Positioned(
                                        top: -2,
                                        right: -2,
                                        child: GestureDetector(
                                          onTap: () => _toggleUserSelection(user),
                                          child: Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              color: AppColors.systemRed,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                                                width: 2,
                                              ),
                                            ),
                                            child: const Icon(
                                              CupertinoIcons.minus,
                                              color: Colors.white,
                                              size: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
              ],
              
              // Search Results
              Expanded(
                child: _buildSearchResults(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(bool isDark) {
    if (_searchQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.search,
              size: 64,
              color: AppColors.systemGray.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Search for users to add to the group',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppColors.systemGray,
              ),
            ),
          ],
        ),
      );
    }

    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.person_3,
              size: 64,
              color: AppColors.systemGray.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppColors.systemGray,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with a different name or username',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.systemGray.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        final isSelected = _isUserSelected(user);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => _toggleUserSelection(user),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppColors.systemBlue.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isSelected 
                    ? Border.all(color: AppColors.systemBlue.withOpacity(0.3))
                    : null,
              ),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.systemBlue.withOpacity(0.1),
                    ),
                    child: user['avatarUrl'] != null
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: user['avatarUrl'],
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Center(
                                child: Text(
                                  _getInitials(user['displayName'] ?? user['username'] ?? 'U'),
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.systemBlue,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              _getInitials(user['displayName'] ?? user['username'] ?? 'U'),
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.systemBlue,
                              ),
                            ),
                          ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // User Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['displayName'] ?? user['username'] ?? 'Unknown',
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (user['username'] != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '@${user['username']}',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: AppColors.systemGray,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Selection Indicator
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? AppColors.systemBlue : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? AppColors.systemBlue : AppColors.systemGray,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            CupertinoIcons.checkmark,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
