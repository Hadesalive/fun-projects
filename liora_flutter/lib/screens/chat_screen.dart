import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatScreen extends StatefulWidget {
  final String peerName;
  final String peerAvatarUrl;
  const ChatScreen({super.key, required this.peerName, required this.peerAvatarUrl});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_Message> _messages = [
    _Message(text: 'Hey! Are you free later today?', isMe: false, time: DateTime.now().subtract(const Duration(minutes: 42))),
    _Message(text: 'Yeah! After 6 works for me 😊', isMe: true, time: DateTime.now().subtract(const Duration(minutes: 40))),
    _Message(text: 'Coffee at the new place?', isMe: false, time: DateTime.now().subtract(const Duration(minutes: 38))),
    _Message(text: "Sounds perfect. See you then!", isMe: true, time: DateTime.now().subtract(const Duration(minutes: 37))),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_Message(text: text, isMe: true, time: DateTime.now()));
      _controller.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final top = media.padding.top;
    final bottom = media.padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Column(
        children: [
          SizedBox(height: top),
          _ChatAppBar(name: widget.peerName, avatarUrl: widget.peerAvatarUrl),
          const Divider(height: 1, color: Color(0x1AFFFFFF)),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final m = _messages[index];
                final showAvatar = !m.isMe;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: m.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      if (showAvatar)
                        Padding(
                          padding: const EdgeInsets.only(right: 6, left: 2),
                          child: CircleAvatar(radius: 14, backgroundImage: NetworkImage(widget.peerAvatarUrl)),
                        ),
                      Flexible(
                        child: _Bubble(
                          text: m.text,
                          isMe: m.isMe,
                        ),
                      ),
                      if (!showAvatar) const SizedBox(width: 6),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(8, 8, 8, (bottom > 0 ? bottom : 8)),
            child: _InputBar(
              controller: _controller,
              onSend: _send,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatAppBar extends StatelessWidget {
  final String name; final String avatarUrl;
  const _ChatAppBar({required this.name, required this.avatarUrl});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.chevron_left, size: 28),
          ),
          CircleAvatar(radius: 18, backgroundImage: NetworkImage(avatarUrl)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
              Text('Online now', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7))),
            ],
          ),
          const Spacer(),
          IconButton(onPressed: () {}, icon: const Icon(Icons.videocam_outlined)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.call_outlined)),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String text; final bool isMe;
  const _Bubble({required this.text, required this.isMe});
  @override
  Widget build(BuildContext context) {
    final bg = isMe ? const Color(0xFF0A84FF) : const Color(0x1AFFFFFF);
    final fg = isMe ? Colors.white : Colors.white;
    final align = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
      bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
    );
    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: radius,
            border: isMe ? null : Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Text(text, style: TextStyle(color: fg, fontSize: 16, height: 1.25)),
        ),
      ],
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller; final VoidCallback onSend;
  const _InputBar({required this.controller, required this.onSend});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.add_circle_outline)),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'iMessage',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                      isDense: true,
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textInputAction: TextInputAction.newline,
                  ),
                ),
                IconButton(onPressed: () {}, icon: const Icon(Icons.camera_alt_outlined, size: 20)),
                IconButton(onPressed: () {}, icon: const Icon(Icons.mic_none_outlined, size: 20)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onSend,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Color(0xFF0A84FF), shape: BoxShape.circle),
            child: const Icon(Icons.arrow_upward, size: 18, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _Message {
  final String text; final bool isMe; final DateTime time;
  _Message({required this.text, required this.isMe, required this.time});
}


