import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

class CardsScreen extends StatelessWidget {
  const CardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final top = media.padding.top; // notch / status bar
    final bottom = media.padding.bottom; // gesture / home indicator
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;

    // Adaptive card size: keep aspect and clamp to screen with margins
    final horizontalPadding = screenWidth >= 600 ? 24.0 : 20.0;
    final maxContentWidth = 430.0; // maintain design density on very wide screens
    final contentWidth = screenWidth.clamp(0, maxContentWidth).toDouble();
    final cardWidth = (contentWidth - horizontalPadding * 2).clamp(320.0, screenWidth - 32);
    final cardHeight = (screenHeight * 0.58).clamp(420.0, screenHeight - (top + bottom + 200));

    return Stack(
      children: [
        // background image
        Positioned.fill(
          child: Image.network(
            'https://hoirqrkdgbmvpwutwuwj-all.supabase.co/storage/v1/object/public/assets/assets/b9f39422-aaf1-42f2-9440-78dfbd3869c7_3840w.jpg',
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x33000000), Color(0xB3000000)],
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              children: [
                SizedBox(height: top + 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _FrostedIcon(icon: Icons.chevron_left),
                      _FrostedSegment(
                        children: const [
                          _Chip(text: 'For You', selected: false),
                          _Chip(text: 'Nearby', selected: true),
                        ],
                      ),
                      _FrostedIcon(icon: Icons.tune),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Center(
                    child: SizedBox(
                      width: cardWidth.toDouble(),
                      height: cardHeight.toDouble(),
                      child: _ProfileCard(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: EdgeInsets.only(bottom: bottom > 0 ? bottom : 16),
                  child: _ReactionBar(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FrostedIcon extends StatelessWidget {
  final IconData icon;
  const _FrostedIcon({required this.icon});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: IconButton(
            onPressed: () {},
            icon: Icon(icon, color: Colors.white.withOpacity(0.9), size: 20),
          ),
        ),
      ),
    );
  }
}

class _FrostedSegment extends StatelessWidget {
  final List<Widget> children;
  const _FrostedSegment({required this.children});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(children: children),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text; final bool selected; const _Chip({required this.text, required this.selected});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white.withOpacity(0.8),
            fontSize: 15,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Stack(
        children: [
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: 'https://hoirqrkdgbmvpwutwuwj-all.supabase.co/storage/v1/object/public/assets/assets/6d92c054-99f4-4fea-bcd0-42676b5f64c3_800w.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x14000000), Color(0x99000000)],
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: 16,
            child: _IconBadge(
              icon: Icons.bookmark_outline,
              onTap: () {},
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Text('Maya, 24', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                          SizedBox(width: 6),
                          Icon(Icons.verified, color: Colors.lightBlueAccent, size: 18),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text('online now', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 15)),
                        ],
                      )
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(50)),
                    child: Text('2.1 mi', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13, fontWeight: FontWeight.w600)),
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

class _IconBadge extends StatefulWidget {
  final IconData icon; final VoidCallback onTap; const _IconBadge({required this.icon, required this.onTap});
  @override
  State<_IconBadge> createState() => _IconBadgeState();
}

class _IconBadgeState extends State<_IconBadge> {
  bool active = false;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => setState(() => active = !active),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFF59E0B) : Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Icon(widget.icon, size: 18, color: active ? Colors.black : Colors.white.withOpacity(0.9)),
      ),
    );
  }
}

class _ReactionBar extends StatefulWidget {
  @override
  State<_ReactionBar> createState() => _ReactionBarState();
}

class _ReactionBarState extends State<_ReactionBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0B0B).withOpacity(0.9),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _CircleBtn(icon: Icons.close, size: 36, onTap: () {}),
          const SizedBox(width: 10),
          _CircleBtn(filled: true, size: 40, icon: Icons.star, onTap: () {}),
          const SizedBox(width: 10),
          _CircleBtn(icon: Icons.favorite, size: 40, filled: true, color: const Color(0xFFEC4899), onTap: () {}),
        ],
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon; final VoidCallback onTap; final bool filled; final Color? color; final double size;
  const _CircleBtn({required this.icon, required this.onTap, this.filled = false, this.color, this.size = 44});
  @override
  Widget build(BuildContext context) {
    final bg = filled ? (color ?? Colors.white) : Colors.white.withOpacity(0.1);
    final ic = filled ? (color != null ? Colors.white : Colors.black) : Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(50)),
        child: Icon(icon, color: ic, size: size * 0.5),
      ),
    );
  }
}


