import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupDescriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  
  List<String> _selectedMembers = [];
  List<String> _filteredContacts = [];
  
  final List<String> _allContacts = [
    'Emma Wilson',
    'Alex Chen', 
    'Sarah Johnson',
    'Mike Davis',
    'Lisa Brown',
    'Tom Wilson',
    'Jessica Lee',
    'David Park',
    'Anna Smith',
    'Ryan Garcia'
  ];
  
  final List<String> _allUsernames = [
    'emma_w',
    'alex_c',
    'sarah_j', 
    'mike_d',
    'lisa_b',
    'tom_w',
    'jessica_l',
    'david_p',
    'anna_s',
    'ryan_g'
  ];

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

  void _filterContacts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredContacts = _allContacts;
      } else {
        _filteredContacts = [];
        for (int i = 0; i < _allContacts.length; i++) {
          if (_allContacts[i].toLowerCase().contains(query.toLowerCase()) ||
              _allUsernames[i].toLowerCase().contains(query.toLowerCase())) {
            _filteredContacts.add(_allContacts[i]);
          }
        }
      }
    });
  }

  void _toggleMember(String contact) {
    setState(() {
      if (_selectedMembers.contains(contact)) {
        _selectedMembers.remove(contact);
      } else {
        _selectedMembers.add(contact);
      }
    });
    HapticFeedback.lightImpact();
  }

  void _createGroup() {
    if (_groupNameController.text.trim().isEmpty) {
      _showError('Please enter a group name');
      return;
    }
    
    if (_selectedMembers.isEmpty) {
      _showError('Please select at least one member');
      return;
    }

    HapticFeedback.lightImpact();
    
    // Show success alert and navigate back
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
            onPressed: _createGroup,
            child: Text(
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
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSecondaryBackground : AppColors.lightSecondaryBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: _filteredContacts.asMap().entries.map((entry) {
                final index = entry.key;
                final contact = entry.value;
                final contactIndex = _allContacts.indexOf(contact);
                final username = _allUsernames[contactIndex];
                final isSelected = _selectedMembers.contains(contact);
                final isLast = index == _filteredContacts.length - 1;
                
                return Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundImage: CachedNetworkImageProvider(
                          'https://i.pravatar.cc/200?img=${contactIndex + 1}',
                        ),
                      ),
                      title: Text(
                        contact,
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                        ),
                      ),
                      subtitle: Text(
                        '@$username',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: AppColors.systemGray,
                        ),
                      ),
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
                      onTap: () => _toggleMember(contact),
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
