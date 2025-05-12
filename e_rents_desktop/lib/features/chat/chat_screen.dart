import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_desktop/base/app_base_screen.dart';
import 'package:e_rents_desktop/features/chat/widgets/chat_message.dart';
import 'package:e_rents_desktop/features/chat/widgets/chat_input.dart';
import 'package:e_rents_desktop/features/chat/widgets/chat_contact.dart';
import 'package:e_rents_desktop/models/message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  String? _selectedContact;
  final List<Message> _messages = [];
  final String _currentUserId = 'user1'; // Replace with actual user ID

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty || _selectedContact == null) {
      return;
    }

    final newMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: _currentUserId,
      receiverId: _selectedContact!,
      messageText: _messageController.text.trim(),
      dateSent: DateTime.now(),
    );

    setState(() {
      _messages.add(newMessage);
    });

    _messageController.clear();

    // TODO: Send message to backend
    // await _chatService.sendMessage(newMessage);
  }

  void _deleteMessage(Message message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Message'),
            content: const Text(
              'Are you sure you want to delete this message?',
            ),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    final index = _messages.indexWhere(
                      (m) => m.id == message.id,
                    );
                    if (index != -1) {
                      _messages[index] = message.copyWith(isDeleted: true);
                    }
                  });
                  context.pop();
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBaseScreen(
      title: 'Chat',
      currentPath: '/chat',
      child: Row(
        children: [
          // Contacts list
          Container(
            width: 300,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search contacts...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                // Contacts list
                Expanded(
                  child: ListView.builder(
                    itemCount: 10,
                    itemBuilder: (context, index) {
                      return ChatContact(
                        name: 'Contact ${index + 1}',
                        lastMessage: 'Last message from contact ${index + 1}',
                        lastMessageTime: DateTime.now().subtract(
                          Duration(minutes: index * 30),
                        ),
                        isOnline: index % 2 == 0,
                        hasUnread: index % 3 == 0,
                        unreadCount: index % 3 == 0 ? index + 1 : 0,
                        onTap: () {
                          setState(() {
                            _selectedContact = 'Contact ${index + 1}';
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Chat area
          Expanded(
            child: Column(
              children: [
                // Chat header
                if (_selectedContact != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: NetworkImage(
                            'https://i.pravatar.cc/150?img=${_selectedContact.hashCode}',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedContact!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Online',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                // Chat messages
                Expanded(
                  child:
                      _selectedContact == null
                          ? Center(
                            child: Text(
                              'Select a contact to start chatting',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          )
                          : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              final isMe = message.senderId == _currentUserId;
                              return ChatMessageBubble(
                                message: message,
                                isMe: isMe,
                                onDelete:
                                    isMe &&
                                            !message
                                                .isDeleted // Allow deleting own non-deleted messages
                                        ? () => _deleteMessage(message)
                                        : null,
                              );
                            },
                          ),
                ),
                // Chat input
                if (_selectedContact != null)
                  ChatInput(
                    controller: _messageController,
                    onSend: _sendMessage,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
