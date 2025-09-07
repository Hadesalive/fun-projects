import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final media = MediaQuery.of(context);
    final top = media.padding.top;
    final bottom = media.padding.bottom;
    final width = media.size.width;
    // Adaptive grid: 2 on phones, 3 on large phones/compact tablets, 4 on wider
    final crossAxisCount = width >= 1000 ? 4 : width >= 700 ? 3 : 2;
    
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
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    _RoundButton(icon: CupertinoIcons.slider_horizontal_3),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _FilterPill(label: '18–26', isDark: isDark),
                    _FilterPill(label: 'Nearby', isDark: isDark),
                    _FilterPill(label: 'No smokers', isDark: isDark),
                  ],
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
  const _RoundButton({required this.icon});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.1) : AppColors.darkBackground.withOpacity(0.1),
        borderRadius: BorderRadius.circular(50),
      ),
      child: IconButton(
        onPressed: () {},
        icon: Icon(
          icon, 
          color: isDark ? Colors.white.withOpacity(0.85) : AppColors.darkBackground.withOpacity(0.85), 
          size: 20,
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool isDark;
  const _FilterPill({required this.label, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.15) : AppColors.darkBackground.withOpacity(0.15),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.2) : AppColors.darkBackground.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label, 
            style: GoogleFonts.inter(
              fontSize: 13, 
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.darkBackground,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.2) : AppColors.darkBackground.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.xmark,
              size: 14,
              color: isDark ? Colors.white : AppColors.darkBackground,
            ),
          )
        ],
      ),
    );
  }
}

class _GridCard extends StatelessWidget {
  final String name; final String age; final String img; final String distance; final bool online; final bool isNew;
  const _GridCard({super.key, required this.name, required this.age, required this.img, required this.distance, this.online = false, this.isNew = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Positioned.fill(
            child: CachedNetworkImage(imageUrl: img, fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xCC000000)],
                ),
              ),
            ),
          ),
          if (online)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(50)),
                child: Row(children: [
                  Icon(CupertinoIcons.circle_fill, size: 8, color: const Color(0xFF22C55E)),
                  const SizedBox(width: 6),
                  Text(
                    'online', 
                    style: GoogleFonts.inter(
                      fontSize: 11, 
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ]),
              ),
            ),
          if (isNew)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFEC4899), borderRadius: BorderRadius.circular(50)),
                child: Text(
                  'NEW', 
                  style: GoogleFonts.inter(
                    fontSize: 11, 
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(50)),
              child: Text(
                distance, 
                style: GoogleFonts.inter(
                  fontSize: 11, 
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(
                          name, 
                          style: GoogleFonts.inter(
                            fontSize: 17, 
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          age, 
                          style: GoogleFonts.inter(
                            fontSize: 15, 
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ]),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(50), border: Border.all(color: Colors.white.withOpacity(0.1))),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(CupertinoIcons.heart, size: 16, color: Colors.white),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}


