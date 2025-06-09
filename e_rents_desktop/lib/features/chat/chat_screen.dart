import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/features/chat/widgets/chat_message.dart';
import 'package:e_rents_desktop/features/chat/widgets/chat_input.dart';
import 'package:e_rents_desktop/features/chat/widgets/chat_contact.dart';
import 'package:e_rents_desktop/features/chat/providers/chat_collection_provider.dart';
import 'package:e_rents_desktop/features/chat/providers/chat_detail_provider.dart';
import 'package:e_rents_desktop/models/message.dart';
import 'package:e_rents_desktop/features/auth/providers/auth_provider.dart';

class ChatScreen extends StatefulWidget {
  final String? contactId;

  const ChatScreen({super.key, this.contactId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  int? _currentUserId;
  bool _hasAutoSelected = false; // Track if we've already auto-selected

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      setState(() {
        _currentUserId = authProvider.currentUser?.id;
      });
      if (_currentUserId == null) {
        print("ChatScreen: Error - Current user ID is null.");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Error: User not authenticated. Cannot use chat."),
            ),
          );
          context.go('/login');
        }
        return;
      }

      // Load contacts via the new collection provider - already done in router factory
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _sendMessage(BuildContext context) {
    if (_currentUserId == null) {
      print("ChatScreen: Cannot send message, user ID is null.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error: Cannot send message. User not identified."),
        ),
      );
      return;
    }

    final chatCollectionProvider = Provider.of<ChatCollectionProvider>(
      context,
      listen: false,
    );
    final chatDetailProvider = Provider.of<ChatDetailProvider>(
      context,
      listen: false,
    );
    final selectedContact = chatCollectionProvider.selectedContact;

    if (_messageController.text.trim().isEmpty || selectedContact == null) {
      return;
    }

    final messageText = _messageController.text.trim();
    _messageController.clear();

    // Send message via detail provider
    chatDetailProvider
        .sendMessage(selectedContact.id, messageText)
        .then((sentMessage) {
          // Update activity in collection provider
          chatCollectionProvider.updateLastActivity(
            selectedContact.id,
            sentMessage.dateSent,
          );
        })
        .catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to send message: $error")),
          );
        });
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
                  final chatDetailProvider = Provider.of<ChatDetailProvider>(
                    context,
                    listen: false,
                  );
                  chatDetailProvider
                      .deleteMessage(message.id)
                      .then((_) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Message deleted")),
                          );
                        }
                      })
                      .catchError((error) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Failed to delete message: $error"),
                            ),
                          );
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

  void _selectContact(BuildContext context, int contactId) {
    final chatCollectionProvider = Provider.of<ChatCollectionProvider>(
      context,
      listen: false,
    );
    final chatDetailProvider = Provider.of<ChatDetailProvider>(
      context,
      listen: false,
    );

    // Select contact in collection provider
    chatCollectionProvider.selectContact(contactId);

    // Load messages for this contact in detail provider
    chatDetailProvider.loadMessages(contactId);
  }

  List<dynamic> _getFilteredContacts(ChatCollectionProvider chatProvider) {
    final searchQuery = _searchController.text.trim();
    if (searchQuery.isEmpty) {
      return chatProvider
          .getContactsByActivity(); // Sort by activity by default
    }
    return chatProvider.searchContacts(searchQuery);
  }

  // Helper method to handle auto-selection when contacts are available
  void _handleAutoSelection(ChatCollectionProvider chatProvider) {
    if (!_hasAutoSelected &&
        widget.contactId != null &&
        chatProvider.contacts.isNotEmpty) {
      final contactIdInt = int.tryParse(widget.contactId!);
      if (contactIdInt != null) {
        print(
          "ChatScreen: Attempting to auto-select contact ID: $contactIdInt",
        );
        print(
          "ChatScreen: Available contacts: ${chatProvider.contacts.map((c) => '${c.id}: ${c.fullName}').toList()}",
        );

        // Check if the contact exists in the loaded contacts
        final contactExists = chatProvider.contacts.any(
          (contact) => contact.id == contactIdInt,
        );
        if (contactExists) {
          print("ChatScreen: Contact found, auto-selecting...");
          _selectContact(context, contactIdInt);
          _hasAutoSelected = true;
        } else {
          print(
            "ChatScreen: Contact ID $contactIdInt not found in loaded contacts",
          );
          // Show a message to the user
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Contact not found. Please select a contact from the list.",
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
          _hasAutoSelected = true; // Prevent repeated attempts
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ChatCollectionProvider, ChatDetailProvider>(
      builder: (context, chatCollectionProvider, chatDetailProvider, _) {
        // Handle auto-selection when contacts are loaded
        _handleAutoSelection(chatCollectionProvider);

        final contacts = _getFilteredContacts(chatCollectionProvider);
        final messages = chatDetailProvider.messages;
        final selectedContact = chatCollectionProvider.selectedContact;
        final isLoadingContacts = chatCollectionProvider.isLoadingContacts;
        final isLoadingMessages = chatDetailProvider.isLoadingMessages;

        // Error handling
        final collectionError = chatCollectionProvider.error;
        final detailError = chatDetailProvider.error;
        final hasError = collectionError != null || detailError != null;
        final errorMessage = collectionError?.message ?? detailError?.message;

        if (hasError && contacts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Error loading chat: $errorMessage",
                  style: const TextStyle(color: Colors.red),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedContact != null) {
                      chatDetailProvider.refreshMessages();
                    }
                    chatCollectionProvider.refreshContacts();
                  },
                  child: const Text("Retry"),
                ),
              ],
            ),
          );
        }

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
                      controller: _searchController,
                      onChanged:
                          (_) =>
                              setState(() {}), // Trigger rebuild for filtering
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
                        isLoadingContacts && contacts.isEmpty
                            ? const Center(child: CircularProgressIndicator())
                            : ListView.builder(
                              itemCount: contacts.length,
                              itemBuilder: (context, index) {
                                final contact = contacts[index];
                                final unreadCount = chatCollectionProvider
                                    .getUnreadCount(contact.id);
                                final lastActivity = chatCollectionProvider
                                    .getLastActivity(contact.id);
                                final lastMessage = chatCollectionProvider
                                    .getLastMessage(contact.id);

                                return ChatContact(
                                  name: contact.fullName,
                                  lastMessage:
                                      lastMessage?.messageText ??
                                      'Tap to view conversation',
                                  lastMessageTime:
                                      lastActivity ??
                                      DateTime.now().subtract(
                                        Duration(minutes: index * 30),
                                      ),
                                  isOnline: index % 2 == 0, // Mock data for now
                                  hasUnread: unreadCount > 0,
                                  unreadCount: unreadCount,
                                  onTap:
                                      () => _selectContact(context, contact.id),
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
                                selectedContact.profileImageId != null
                                    ? NetworkImage(
                                      '/Image/${selectedContact.profileImageId}',
                                    )
                                    : null,
                            child:
                                (selectedContact.profileImageId == null)
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
                            : isLoadingMessages && messages.isEmpty
                            ? const Center(child: CircularProgressIndicator())
                            : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final message = messages[index];
                                final isMe = message.senderId == _currentUserId;
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
    );
  }
}
