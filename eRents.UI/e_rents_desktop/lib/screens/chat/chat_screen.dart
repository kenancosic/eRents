import 'package:flutter/material.dart';
import 'package:e_rents_desktop/base/app_base_screen.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBaseScreen(
      title: 'Chat',
      currentPath: '/chat',
      content: const Center(child: Text('Chat Screen Content')),
    );
  }
}
