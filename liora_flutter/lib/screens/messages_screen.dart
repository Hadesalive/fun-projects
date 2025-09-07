// Legacy messages screen - now using enhanced version
// This file is kept for backward compatibility
import 'package:flutter/material.dart';
import '../features/chat/screens/enhanced_messages_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EnhancedMessagesScreen();
  }
}


