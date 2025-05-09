import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChatRoomScreen extends StatelessWidget {
  // Sample data for chat rooms
  final List<Map<String, dynamic>> _chatRooms = [
    {
      'name': 'Emir Kovačević',
      'lastMessage': 'Thanks for contacting me!',
      'time': '15:23',
      'imageUrl': 'assets/images/user-image.png',
      'unreadCount': 2,
    },
    {
      'name': 'Tom Cruise',
      'lastMessage': 'Your payment was accepted.',
      'time': 'Yesterday',
      'imageUrl': 'assets/images/user-image.png',
      'unreadCount': 0,
    },
    // Add more chat rooms here...
  ];

  ChatRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      showTitle: true,
      showBackButton: false,
      showAppBar: true,
      titleText: 'Chat Room',
      body: ListView.builder(
        itemCount: _chatRooms.length,
        itemBuilder: (context, index) {
          final chatRoom = _chatRooms[index];
          return _buildChatRoomTile(
            name: chatRoom['name'],
            lastMessage: chatRoom['lastMessage'],
            time: chatRoom['time'],
            imageUrl: chatRoom['imageUrl'],
            unreadCount: chatRoom['unreadCount'],
            context: context,
          );
        },
      ),
    );
  }

  Widget _buildChatRoomTile({
    required String name,
    required String lastMessage,
    required String time,
    required String imageUrl,
    required int unreadCount,
    required BuildContext context,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: AssetImage(imageUrl),
        radius: 25,
      ),
      title: Text(
        name,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        lastMessage,
        style: TextStyle(
          color: Colors.grey[600],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(time, style: const TextStyle(color: Colors.grey)),
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.all(6.0),
              decoration: const BoxDecoration(
                color: Colors.purple,
                shape: BoxShape.circle,
              ),
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        context.push(
          '/chat', // push the route to add it to the stack
          extra: {
            'name': name,
            'imageUrl': imageUrl,
          },
        );
      },
    );
  }
}
