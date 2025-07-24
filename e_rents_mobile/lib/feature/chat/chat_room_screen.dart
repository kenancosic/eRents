import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/core/widgets/custom_app_bar.dart';
import 'package:e_rents_mobile/feature/chat/chat_provider.dart';
import 'package:e_rents_mobile/feature/chat/models/chat_room.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({super.key});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch rooms when the screen loads
    Future.microtask(() =>
        Provider.of<ChatProvider>(context, listen: false).fetchChatRooms());
  }

  @override
  Widget build(BuildContext context) {
    final appBar = CustomAppBar(
      title: 'Chat Room',
      showBackButton: false,
    );

    return BaseScreen(
      showAppBar: true,
      appBar: appBar,
      body: Consumer<ChatProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingRooms && provider.chatRooms.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.roomsError != null) {
            return Center(
              child: Text('Error: ${provider.roomsError}'),
            );
          }

          if (provider.chatRooms.isEmpty) {
            return const Center(
              child: Text('No active chats.'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchChatRooms(forceRefresh: true),
            child: ListView.builder(
              itemCount: provider.chatRooms.length,
              itemBuilder: (context, index) {
                final chatRoom = provider.chatRooms[index];
                return _buildChatRoomTile(context, chatRoom);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatRoomTile(BuildContext context, ChatRoom chatRoom) {
    final lastMessage = chatRoom.lastMessage;
    final time = lastMessage != null
        ? DateFormat('HH:mm').format(lastMessage.timestamp)
        : '';

    // Determine the other user's info
    final currentUserId = 'user1'; // This should come from an auth provider
    final otherUserId = chatRoom.userIds.firstWhere((id) => id != currentUserId, orElse: () => '');
    final name = chatRoom.userNames[otherUserId] ?? 'Unknown User';
    final imageUrl = chatRoom.userImages[otherUserId] ?? 'assets/images/user-image.png';

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
        lastMessage?.text ?? 'No messages yet',
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
          // Unread count logic would go here if available from the API
        ],
      ),
      onTap: () {
        context.push(
          '/chat/${chatRoom.id}', // Pass room ID in path
          extra: {
            'userName': name,
            'userImage': imageUrl,
          },
        );
      },
    );
  }
}

