import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupDescriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _selectedMembers = [];
  List<Map<String, dynamic>> _filteredContacts = [];
  List<Map<String, dynamic>> _allContacts = [];
  
  bool _isLoadingUsers = false;
  bool _isCreatingGroup = false;

  @override
  void initState() {
    super.initState();
    _filteredContacts = _allContacts;
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _groupDescriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _filterContacts(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _filteredContacts = [];
        _isLoadingUsers = false;
      });
      return;
    }

    if (query.trim().length < 2) {
      return; // Wait for at least 2 characters
    }

    setState(() => _isLoadingUsers = true);

    try {
      final result = await _apiService.searchUsers(query.trim());
      
      if (result.success) {
        setState(() {
          _allContacts = List<Map<String, dynamic>>.from(result.data ?? []);
          _filteredContacts = _allContacts;
          _isLoadingUsers = false;
        });
      } else {
        setState(() {
          _filteredContacts = [];
          _isLoadingUsers = false;
        });
        if (mounted) {
          _showError('Failed to search users: ${result.error}');
        }
      }
    } catch (e) {
      setState(() {
        _filteredContacts = [];
        _isLoadingUsers = false;
      });
      if (mounted) {
        _showError('Error searching users: $e');
      }
    }
  }

  void _toggleMember(Map<String, dynamic> user) {
    setState(() {
      final userId = user['id'];
      final existingIndex = _selectedMembers.indexWhere((member) => member['id'] == userId);
      
      if (existingIndex != -1) {
        _selectedMembers.removeAt(existingIndex);
      } else {
        _selectedMembers.add(user);
      }
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _createGroup() async {
    if (_groupNameController.text.trim().isEmpty) {
      _showError('Please enter a group name');
      return;
    }
    
    if (_selectedMembers.isEmpty) {
      _showError('Please select at least one member');
      return;
    }

    if (_isCreatingGroup) return;

    setState(() => _isCreatingGroup = true);
    HapticFeedback.lightImpact();

    try {
      final memberIds = _selectedMembers.map((member) => member['id'] as String).toList();
      
      final result = await _apiService.createGroup(
        name: _groupNameController.text.trim(),
        description: _groupDescriptionController.text.trim().isEmpty 
            ? null 
            : _groupDescriptionController.text.trim(),
        memberIds: memberIds,
      );

      if (result.success) {
        setState(() => _isCreatingGroup = false);
        
        if (mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: Text(
                'Group Created',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: Text(
                'Your group "${_groupNameController.text}" has been created successfully.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    context.pop(); // Navigate back
                  },
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
      } else {
        setState(() => _isCreatingGroup = false);
        if (mounted) {
          _showError('Failed to create group: ${result.error}');
        }
      }
    } catch (e) {
      setState(() => _isCreatingGroup = false);
      if (mounted) {
        _showError('Error creating group: $e');
      }
    }
  }

  void _showError(String message) {
    HapticFeedback.heavyImpact();
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
          'New Group',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isCreatingGroup ? null : _createGroup,
            child: _isCreatingGroup
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.systemBlue),
                    ),
                  )
                : Text(
                    'Create',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.systemBlue,
                    ),
                  ),
          ),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          
          // Group Avatar Section
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: isDark ? AppColors.darkSecondaryBackground : AppColors.lightSecondaryBackground,
                  child: Icon(
                    CupertinoIcons.group_solid,
                    size: 50,
                    color: AppColors.systemGray,
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
          ),
          
          const SizedBox(height: 30),
          
          // Group Info Section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSecondaryBackground : AppColors.lightSecondaryBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Group Name
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Text(
                        'Group Name',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CupertinoTextField(
                          controller: _groupNameController,
                          placeholder: 'Enter group name',
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                          ),
                          placeholderStyle: GoogleFonts.inter(
                            fontSize: 17,
                            color: AppColors.systemGray,
                          ),
                          decoration: null,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Divider
                Container(
                  height: 0.5,
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  margin: const EdgeInsets.only(left: 16),
                ),
                
                // Group Description
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Description',
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CupertinoTextField(
                          controller: _groupDescriptionController,
                          placeholder: 'Optional',
                          maxLines: 3,
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                          ),
                          placeholderStyle: GoogleFonts.inter(
                            fontSize: 17,
                            color: AppColors.systemGray,
                          ),
                          decoration: null,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Add Members Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'ADD MEMBERS',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.systemGray,
                letterSpacing: -0.08,
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // Search Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSecondaryBackground : AppColors.lightSecondaryBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.search,
                    color: AppColors.systemGray,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CupertinoTextField(
                      controller: _searchController,
                      onChanged: _filterContacts,
                      placeholder: 'Search',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                      ),
                      placeholderStyle: GoogleFonts.inter(
                        fontSize: 17,
                        color: AppColors.systemGray,
                      ),
                      decoration: null,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Contacts List
          if (_isLoadingUsers)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.systemBlue),
                ),
              ),
            )
          else if (_filteredContacts.isEmpty && _searchController.text.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No users found',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: AppColors.systemGray,
                  ),
                ),
              ),
            )
          else if (_filteredContacts.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSecondaryBackground : AppColors.lightSecondaryBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: _filteredContacts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final user = entry.value;
                  final userId = user['id'];
                  final displayName = user['displayName'] ?? user['username'] ?? 'Unknown User';
                  final username = user['username'] ?? '';
                  final avatarUrl = user['avatarUrl'] as String?;
                  final isSelected = _selectedMembers.any((member) => member['id'] == userId);
                  final isLast = index == _filteredContacts.length - 1;
                  
                  return Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.systemBlue.withOpacity(0.1),
                          child: avatarUrl != null && avatarUrl.isNotEmpty
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: avatarUrl,
                                    fit: BoxFit.cover,
                                    width: 40,
                                    height: 40,
                                    errorWidget: (context, url, error) => Text(
                                      displayName[0].toUpperCase(),
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.systemBlue,
                                      ),
                                    ),
                                  ),
                                )
                              : Text(
                                  displayName[0].toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.systemBlue,
                                  ),
                                ),
                        ),
                        title: Text(
                          displayName,
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                          ),
                        ),
                        subtitle: username.isNotEmpty ? Text(
                          '@$username',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: AppColors.systemGray,
                          ),
                        ) : null,
                        trailing: isSelected
                            ? Icon(
                                CupertinoIcons.checkmark_circle_fill,
                                color: AppColors.systemBlue,
                                size: 22,
                              )
                            : Icon(
                                CupertinoIcons.circle,
                                color: AppColors.systemGray,
                                size: 22,
                              ),
                        onTap: () => _toggleMember(user),
                      ),
                      if (!isLast)
                        Container(
                          height: 0.5,
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          margin: const EdgeInsets.only(left: 72),
                        ),
                    ],
                  );
                }).toList(),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'Search for users to add to your group',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: AppColors.systemGray,
                  ),
                ),
              ),
            ),
          
          // Selected Members Count
          if (_selectedMembers.isNotEmpty) ...[
            const SizedBox(height: 20),
            Center(
              child: Text(
                '${_selectedMembers.length} member${_selectedMembers.length == 1 ? '' : 's'} selected',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColors.systemGray,
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
