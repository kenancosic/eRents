import 'package:e_rents_desktop/features/auth/providers/auth_provider.dart';
import 'package:e_rents_desktop/features/chat/providers/chat_provider.dart';
import 'package:e_rents_desktop/features/chat/widgets/chat_contact.dart';
import 'package:e_rents_desktop/features/chat/widgets/chat_input.dart';
import 'package:e_rents_desktop/features/chat/widgets/chat_message.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/widgets/custom_avatar.dart';
import 'package:go_router/go_router.dart';
  
class ChatScreen extends StatefulWidget {
  final String? contactId;

  const ChatScreen({super.key, this.contactId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int? _currentUserId;
  bool _hasAutoSelected = false;
  ChatProvider? _chatProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      setState(() {
        _currentUserId = authProvider.currentUser?.id;
      });
      if (_currentUserId == null) {
        log.severe("ChatScreen: Error - Current user ID is null.");
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
      
      // Note: SignalR connection is now managed globally by main.dart
      // which connects immediately after login, so no need to call connectRealtime() here
      _chatProvider = Provider.of<ChatProvider>(context, listen: false);
      log.info("ChatScreen: SignalR connected: ${_chatProvider!.isRealtimeConnected}");
      
      // Add listener for message changes to auto-scroll
      _chatProvider!.addListener(_onMessagesChanged);
    });
  }

  void _onMessagesChanged() {
    if (mounted) {
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _chatProvider?.removeListener(_onMessagesChanged);
    _messageController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(BuildContext context) {
    if (_currentUserId == null) {
      log.warning("ChatScreen: Cannot send message, user ID is null.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error: Cannot send message. User not identified."),
        ),
      );
      return;
    }

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final selectedContact = chatProvider.selectedContact;

    if (_messageController.text.trim().isEmpty || selectedContact == null) {
      return;
    }

    final messageText = _messageController.text.trim();
    _messageController.clear();

    chatProvider.sendMessage(selectedContact.id, messageText).then((success) {
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(chatProvider.error ?? 'Failed to send message')),
        );
      } else if (success && mounted) {
        // Scroll to bottom after sending message
        _scrollToBottom();
      }
    });
  }


  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _selectContact(BuildContext context, int contactId) {
    Provider.of<ChatProvider>(context, listen: false).selectContact(contactId);
    // Scroll to bottom when switching to a new conversation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  List<User> _getFilteredContacts(ChatProvider chatProvider) {
    final searchQuery = _searchController.text.trim();
    if (searchQuery.isEmpty) {
      return chatProvider.contacts;
    }
    return chatProvider.contacts
        .where((c) => c.fullName.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }

  Future<void> _handleAutoSelection(ChatProvider chatProvider) async {
    if (widget.contactId != null) {
      log.info("ChatScreen: contactId from widget is not null: ${widget.contactId}");
      try {
        final contactIdInt = int.tryParse(widget.contactId!);
        log.info("ChatScreen: Parsed contactId: $contactIdInt");
        if (contactIdInt != null) {
          _hasAutoSelected = true; // Mark early to prevent duplicate calls
          
          // Check if contact exists, if not fetch and add them
          final contactExists = chatProvider.contacts.any((c) => c.id == contactIdInt);
          if (!contactExists) {
            log.info("ChatScreen: Contact not in list, fetching user $contactIdInt...");
            final success = await chatProvider.ensureContact(contactIdInt);
            if (!success) {
              log.warning("ChatScreen: Failed to fetch contact with ID $contactIdInt");
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Contact not found. Please select a contact from the list."),
                  ),
                );
              }
              return;
            }
          }
          
          log.info("ChatScreen: Contact available, auto-selecting...");
          chatProvider.selectContact(contactIdInt);
        }
      } catch (e, stackTrace) {
        log.severe("ChatScreen: Error parsing contactId", e, stackTrace);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        // Schedule auto-selection after build to avoid setState during build
        // Always try to auto-select if contactId is provided, even if contacts list is empty
        // This handles the case of navigating to chat with a new contact (prospective tenant)
        if (!_hasAutoSelected && widget.contactId != null && !chatProvider.isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_hasAutoSelected) {
              _handleAutoSelection(chatProvider);
            }
          });
        }

        final contacts = _getFilteredContacts(chatProvider);
        final selectedContact = chatProvider.selectedContact;
        final messages = chatProvider.activeConversationMessages;
        final isLoading = chatProvider.isLoading;

        return Row(
          children: [
            Container(
              width: 300,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search contacts...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                  ),
                  Expanded(
                    child: isLoading && contacts.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            itemCount: contacts.length,
                            itemBuilder: (context, index) {
                              final contact = contacts[index];
                              final unreadCount = chatProvider.getUnreadCount(contact.id);
                              return ChatContact(
                                name: contact.fullName,
                                lastMessage: chatProvider.getLastMessage(contact.id) ?? 'Tap to view conversation',
                                lastMessageTime: chatProvider.getLastActivity(contact.id) ?? DateTime.now().subtract(const Duration(days: 1)),
                                hasUnread: unreadCount > 0,
                                unreadCount: unreadCount,
                                isSelected: contact.id == selectedContact?.id,
                                onTap: () => _selectContact(context, contact.id),
                                profileImageId: contact.profileImageId,
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  if (selectedContact != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: (selectedContact.profileImageId != null)
                                ? CustomAvatar(
                                    imageUrl: '/Images/${selectedContact.profileImageId}',
                                    size: 40,
                                    borderWidth: 0,
                                  )
                                : ClipOval(
                                    child: Center(
                                      child: Text(
                                        selectedContact.firstName![0] + selectedContact.lastName![0],
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(selectedContact.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                              Text('Online', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            ],
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: selectedContact == null
                        ? Center(child: Text('Select a contact to start chatting', style: TextStyle(color: Colors.grey[600])))
                        : isLoading && messages.isEmpty
                            ? const Center(child: CircularProgressIndicator())
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(16),
                                itemCount: messages.length,
                                itemBuilder: (context, index) {
                                  final message = messages[index];
                                  final isMe = message.senderId == _currentUserId;
                                  return ChatMessageBubble(
                                    message: message,
                                    isMe: isMe,
                                  );
                                },
                              ),
                  ),
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
