import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Nearby', 'Popular', 'New'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final top = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 3 : 2;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: top + 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Discover',
                          style: GoogleFonts.inter(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                          ),
                        ),
                        Text(
                          '24 profiles nearby',
                          style: GoogleFonts.inter(
                            color: isDark ? Colors.white70 : AppColors.darkBackground.withOpacity(0.7),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    _RoundButton(
                      icon: CupertinoIcons.slider_horizontal_3,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        // TODO: Show filter options
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSecondaryBackground : AppColors.lightSecondaryBackground,
                    borderRadius: BorderRadius.circular(22),
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
                      hintText: 'Search profiles...',
                      hintStyle: GoogleFonts.inter(
                        color: isDark ? Colors.white54 : AppColors.darkBackground.withOpacity(0.5),
                        fontSize: 16,
                      ),
                      prefixIcon: Icon(
                        CupertinoIcons.search,
                        color: isDark ? Colors.white54 : AppColors.darkBackground.withOpacity(0.5),
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Filter Pills
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedFilter = filter;
                            });
                            HapticFeedback.lightImpact();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.systemBlue
                                  : (isDark ? AppColors.darkSecondaryBackground : AppColors.lightSecondaryBackground),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.systemBlue
                                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              filter,
                              style: GoogleFonts.inter(
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText),
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: GridView.count(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, (bottom > 0 ? bottom : 24)),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: const [
                    _GridCard(
                      name: 'Viktoria',
                      age: '24',
                      img: 'https://hoirqrkdgbmvpwutwuwj-all.supabase.co/storage/v1/object/public/assets/assets/9b22c33a-b017-42bd-bab5-89be63576edd_800w.jpg',
                      distance: '1.2 mi',
                      online: true,
                    ),
                    _GridCard(
                      name: 'Angel',
                      age: '22',
                      img: 'https://hoirqrkdgbmvpwutwuwj-all.supabase.co/storage/v1/object/public/assets/assets/fbfb93aa-ae97-4da5-ac6a-57ecd1c2c0ee_800w.jpg',
                      distance: '0.8 mi',
                    ),
                    _GridCard(
                      name: 'Eliza',
                      age: '26',
                      img: 'https://hoirqrkdgbmvpwutwuwj-all.supabase.co/storage/v1/object/public/assets/assets/f7f6feef-fd3e-4901-bce6-7271aa74dc87_800w.jpg',
                      distance: '2.3 mi',
                      isNew: true,
                    ),
                    _GridCard(
                      name: 'Carmen',
                      age: '23',
                      img: 'https://hoirqrkdgbmvpwutwuwj-all.supabase.co/storage/v1/object/public/assets/assets/878428de-34e9-452a-aec5-48aa12782394_800w.jpg',
                      distance: '1.7 mi',
                      online: true,
                    ),
                    _GridCard(
                      name: 'Tina',
                      age: '25',
                      img: 'https://hoirqrkdgbmvpwutwuwj-all.supabase.co/storage/v1/object/public/assets/assets/c62627bc-d916-4071-90de-5b3aa885cbf0_800w.jpg',
                      distance: '3.1 mi',
                    ),
                    _GridCard(
                      name: 'Evelyn',
                      age: '21',
                      img: 'https://hoirqrkdgbmvpwutwuwj-all.supabase.co/storage/v1/object/public/assets/assets/f45d0d38-734a-45d6-9529-9a3ee7531761_800w.jpg',
                      distance: '0.5 mi',
                      online: true,
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

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  
  const _RoundButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSecondaryBackground : AppColors.lightSecondaryBackground,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 0.5,
          ),
        ),
        child: Icon(
          icon,
          color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
          size: 20,
        ),
      ),
    );
  }
}

class _GridCard extends StatelessWidget {
  final String name;
  final String age;
  final String img;
  final String distance;
  final bool online;
  final bool isNew;

  const _GridCard({
    required this.name,
    required this.age,
    required this.img,
    required this.distance,
    this.online = false,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        // TODO: Navigate to profile
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSecondaryBackground : AppColors.lightSecondaryBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 0.5,
          ),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: img,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: isDark ? AppColors.darkSecondaryBackground : AppColors.lightSecondaryBackground,
                  child: Icon(
                    CupertinoIcons.person_circle,
                    size: 40,
                    color: isDark ? Colors.white24 : AppColors.darkBackground.withOpacity(0.3),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: isDark ? AppColors.darkSecondaryBackground : AppColors.lightSecondaryBackground,
                  child: Icon(
                    CupertinoIcons.person_circle,
                    size: 40,
                    color: isDark ? Colors.white24 : AppColors.darkBackground.withOpacity(0.3),
                  ),
                ),
              ),
            ),
            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),
            // Content
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$name, $age',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (online)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    distance,
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // New badge
            if (isNew)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.systemBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'NEW',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}