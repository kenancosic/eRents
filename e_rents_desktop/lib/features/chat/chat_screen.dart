import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/base/app_base_screen.dart';
import 'package:e_rents_desktop/features/chat/widgets/chat_message.dart';
import 'package:e_rents_desktop/features/chat/widgets/chat_input.dart';
import 'package:e_rents_desktop/features/chat/widgets/chat_contact.dart';
import 'package:e_rents_desktop/features/chat/providers/chat_provider.dart';
import 'package:e_rents_desktop/models/message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final String _currentUserId =
      'currentUser'; // Replace with actual user ID from auth

  @override
  void initState() {
    super.initState();
    // Load contacts when the screen is first opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.loadContacts();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final selectedContact = chatProvider.selectedContact;

    if (_messageController.text.trim().isEmpty || selectedContact == null) {
      return;
    }

    final newMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: _currentUserId,
      receiverId: selectedContact.id,
      messageText: _messageController.text.trim(),
      dateSent: DateTime.now(),
    );

    _messageController.clear();

    // Send message to backend via provider
    chatProvider.sendMessage(newMessage);
  }

  void _deleteMessage(BuildContext context, Message message) {
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
                  final chatProvider = Provider.of<ChatProvider>(
                    context,
                    listen: false,
                  );
                  chatProvider.deleteMessage(message.id);
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
      child: Consumer<ChatProvider>(
        builder: (context, chatProvider, _) {
          final contacts = chatProvider.contacts;
          final messages = chatProvider.messages;
          final selectedContact = chatProvider.selectedContact;
          final isLoading = chatProvider.isLoading;

          return Row(
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
                      child:
                          isLoading && contacts.isEmpty
                              ? const Center(child: CircularProgressIndicator())
                              : ListView.builder(
                                itemCount: contacts.length,
                                itemBuilder: (context, index) {
                                  final contact = contacts[index];
                                  return ChatContact(
                                    name: contact.fullName,
                                    lastMessage:
                                        'Tap to view conversation', // This would come from actual messages
                                    lastMessageTime: DateTime.now().subtract(
                                      Duration(minutes: index * 30),
                                    ),
                                    isOnline: index % 2 == 0,
                                    hasUnread: index % 3 == 0,
                                    unreadCount: index % 3 == 0 ? index + 1 : 0,
                                    onTap: () {
                                      chatProvider.selectContact(contact.id);
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
                    if (selectedContact != null)
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
                              backgroundImage:
                                  selectedContact.profileImage != null
                                      ? NetworkImage(
                                        selectedContact.profileImage!,
                                      )
                                      : null,
                              child:
                                  selectedContact.profileImage == null
                                      ? Text(
                                        selectedContact.firstName[0] +
                                            selectedContact.lastName[0],
                                      )
                                      : null,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedContact.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Online', // This would be a dynamic status
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
                          selectedContact == null
                              ? Center(
                                child: Text(
                                  'Select a contact to start chatting',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              )
                              : isLoading && messages.isEmpty
                              ? const Center(child: CircularProgressIndicator())
                              : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: messages.length,
                                itemBuilder: (context, index) {
                                  final message = messages[index];
                                  final isMe =
                                      message.senderId == _currentUserId;
                                  return ChatMessageBubble(
                                    message: message,
                                    isMe: isMe,
                                    onDelete:
                                        isMe && !message.isDeleted
                                            ? () =>
                                                _deleteMessage(context, message)
                                            : null,
                                  );
                                },
                              ),
                    ),
                    // Chat input
                    if (selectedContact != null)
                      ChatInput(
                        controller: _messageController,
                        onSend: () => _sendMessage(context),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
