import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final top = media.padding.top;
    final bottom = media.padding.bottom;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF171717), Color(0xFF0A0A0A)],
          ),
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              children: [
                SizedBox(height: top + 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: _SearchBar(),
                ),
                _StoriesRow(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Messages',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(0.95)),
                    ),
                  ),
                ),
                const Expanded(child: _MessagesList()),
                SizedBox(height: bottom > 0 ? bottom : 0),
              ],
            ),
          ),
        ),
      ),
    );
    
    // close Scaffold
    
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.search, size: 20, color: Colors.white.withOpacity(0.8)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Search',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              Icon(Icons.tune, size: 18, color: Colors.white.withOpacity(0.8)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoriesRow extends StatelessWidget {
  final List<Map<String, String>> items = const [
    {
      'name': 'Emma',
      'img': 'https://hoirqrkdgbmvpwutwuwj-all.supabase.co/storage/v1/object/public/assets/assets/a7a0f0f5-9a19-4888-87bf-ff8780ff8008_320w.jpg',
    },
    {
      'name': 'Natalie',
      'img': 'https://images.unsplash.com/photo-1548142813-c348350df52b?q=80&w=256&auto=format&fit=crop',
    },
    {
      'name': 'Jennie',
      'img': 'https://images.unsplash.com/photo-1517841905240-472988babdf9?q=80&w=256&auto=format&fit=crop',
    },
    {
      'name': 'Diana',
      'img': 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?q=80&w=256&auto=format&fit=crop',
    },
    {
      'name': 'Alina',
      'img': 'https://images.unsplash.com/photo-1529665253569-6d01c0eaf7b6?q=80&w=256&auto=format&fit=crop',
    },
    {
      'name': 'Maya',
      'img': 'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?q=80&w=256&auto=format&fit=crop',
    },
  ];

  _StoriesRow({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final item = items[index];
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFFD946EF), Color(0xFFEC4899)]),
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.black,
                  child: CircleAvatar(
                    radius: 22,
                    backgroundImage: CachedNetworkImageProvider(item['img']!),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item['name']!,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.85)),
              )
            ],
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemCount: items.length,
      ),
    );
  }
}

class _MessagesList extends StatelessWidget {
  const _MessagesList();

  @override
  Widget build(BuildContext context) {
    final rows = [
      _MessageRow(
        name: 'Samantha',
        time: '16m',
        preview: 'Typing…',
        unread: 4,
        img: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?q=80&w=200&auto=format&fit=crop',
        ring: true,
      ),
      _MessageRow(
        name: 'Nicole',
        time: '18m',
        preview: "You: Hey! What's up, long time no s...",
        img: 'https://images.unsplash.com/photo-1548142813-c348350df52b?q=80&w=200&auto=format&fit=crop',
      ),
      _MessageRow(
        name: 'Emma Ora',
        time: '24m',
        preview: 'Love you 💕',
        unread: 2,
        img: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=200&auto=format&fit=crop',
      ),
      _MessageRow(
        name: 'Diana Morans',
        time: '24m',
        preview: 'You: Great! nice to meet you cante...',
        img: 'https://hoirqrkdgbmvpwutwuwj-all.supabase.co/storage/v1/object/public/assets/assets/930ce830-f688-4032-a702-85ace409705c_320w.jpg',
      ),
      _MessageRow(
        name: 'Maria Uloa',
        time: '34m',
        preview: 'You: Hi! how are you mbak?',
        img: 'https://images.unsplash.com/photo-1529665253569-6d01c0eaf7b6?q=80&w=200&auto=format&fit=crop',
      ),
      _MessageRow(
        name: 'Natalie Jenner',
        time: '1h',
        preview: "You: Hey! What's up, long time no s...",
        ring: true,
        img: 'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?q=80&w=200&auto=format&fit=crop',
      ),
    ];
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemBuilder: (context, i) => rows[i],
      separatorBuilder: (_, __) => Divider(color: Colors.white.withOpacity(0.06), height: 1),
      itemCount: rows.length,
    );
  }
}

class _MessageRow extends StatelessWidget {
  final String name;
  final String time;
  final String preview;
  final String img;
  final int unread;
  final bool ring;
  const _MessageRow({required this.name, required this.time, required this.preview, required this.img, this.unread = 0, this.ring = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(peerName: name, peerAvatarUrl: img),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            if (ring)
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFFD946EF), Color(0xFFEC4899)]),
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(radius: 22, backgroundImage: CachedNetworkImageProvider(img)),
              )
            else
              CircleAvatar(radius: 22, backgroundImage: CachedNetworkImageProvider(img)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      Text(time, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.6))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.7)),
                  ),
                ],
              ),
            ),
            if (unread > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDB2777),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('$unread', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
          ],
        ),
      ),
    );
  }
}

// end of file


