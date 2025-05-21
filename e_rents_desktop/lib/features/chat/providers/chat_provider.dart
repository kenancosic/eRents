import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/models/message.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/services/chat_service.dart';
import 'package:e_rents_desktop/features/auth/providers/auth_provider.dart';
import 'package:flutter/foundation.dart';

class ChatProvider extends BaseProvider<Message> {
  final ChatService _chatService;
  final AuthProvider _authProvider;
  final Map<String, List<Message>> _conversationMessages = {};
  final Map<String, User> _contacts = {};
  String? _selectedContactId;

  ChatProvider(this._chatService, this._authProvider) : super(_chatService) {
    disableMockData(); // Use real API calls by default now
  }

  // Getters
  List<Message> get messages => _conversationMessages[_selectedContactId] ?? [];
  List<User> get contacts => _contacts.values.toList();
  User? get selectedContact =>
      _selectedContactId != null ? _contacts[_selectedContactId] : null;

  // Set the currently selected contact
  void selectContact(String contactId) {
    _selectedContactId = contactId;
    notifyListeners();
    if (_authProvider.currentUser?.id != null) {
      loadMessages(contactId, _authProvider.currentUser!.id);
    } else {
      setError("User not authenticated, cannot load messages.");
    }
  }

  @override
  String get endpoint => '/Chat';

  @override
  Message fromJson(Map<String, dynamic> json) => Message.fromJson(json);

  @override
  Map<String, dynamic> toJson(Message item) => item.toJson();

  @override
  List<Message> getMockItems() {
    // Mock messages are generated per conversation in loadMessages if needed
    return [];
  }

  // Load all contacts
  Future<void> loadContacts() async {
    await execute(() async {
      if (isMockDataEnabled) {
        await Future.delayed(const Duration(milliseconds: 500));
        final mockUsers = List.generate(
          10,
          (index) => User(
            id: 'user$index',
            email: 'user$index@example.com',
            username: 'user$index',
            firstName: 'User',
            lastName: '${index + 1}',
            role: UserType.landlord,
            createdAt: DateTime.now().subtract(Duration(days: index * 10)),
            updatedAt: DateTime.now(),
          ),
        );
        _contacts.clear();
        for (final user in mockUsers) {
          _contacts[user.id] = user;
        }
      } else {
        final fetchedContacts = await _chatService.getContacts();
        _contacts.clear();
        for (final user in fetchedContacts) {
          _contacts[user.id] = user;
        }
      }
    });
  }

  // Load messages for a specific contact
  Future<void> loadMessages(
    String contactId,
    String currentUserId, {
    int? page,
    int? pageSize,
  }) async {
    await execute(() async {
      if (isMockDataEnabled) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (!_conversationMessages.containsKey(contactId)) {
          _conversationMessages[contactId] = [];
          final mockMessages = List.generate(
            5,
            (index) => Message(
              id: 'msg$index-$contactId',
              senderId: index % 2 == 0 ? currentUserId : contactId,
              receiverId: index % 2 == 0 ? contactId : currentUserId,
              messageText: 'This is mock message ${index + 1} with $contactId',
              dateSent: DateTime.now().subtract(Duration(hours: index * 2)),
            ),
          );
          _conversationMessages[contactId] = mockMessages;
        }
      } else {
        final fetchedMessages = await _chatService.getMessages(
          contactId,
          page: page,
          pageSize: pageSize,
        );
        _conversationMessages[contactId] = fetchedMessages;
      }
    });
  }

  // Send a message
  Future<void> sendMessage(Message message) async {
    await execute(() async {
      Message sentMessage;
      if (isMockDataEnabled) {
        await Future.delayed(const Duration(milliseconds: 300));
        sentMessage = message.copyWith(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
        );
      } else {
        sentMessage = await _chatService.sendMessage(
          message.receiverId,
          message.messageText,
        );
      }
      if (!_conversationMessages.containsKey(sentMessage.receiverId)) {
        _conversationMessages[sentMessage.receiverId] = [];
      }
      _conversationMessages[sentMessage.receiverId]!.add(sentMessage);
    });
  }

  // Send a property offer message
  Future<void> sendPropertyOfferMessage(
    String receiverId,
    String propertyId,
  ) async {
    final currentUserId = _authProvider.currentUser?.id;
    if (currentUserId == null) {
      setError("User not authenticated. Cannot send property offer.");
      return;
    }
    final String offerMessageContent = "PROPERTY_OFFER::$propertyId";
    final newMessage = Message(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      senderId: currentUserId,
      receiverId: receiverId,
      messageText: offerMessageContent,
      dateSent: DateTime.now(),
    );
    await sendMessage(newMessage);
  }

  // Delete a message
  Future<void> deleteMessage(String messageId) async {
    if (_selectedContactId == null) {
      setError("No contact selected. Cannot delete message.");
      return;
    }
    await execute(() async {
      if (isMockDataEnabled) {
        await Future.delayed(const Duration(milliseconds: 300));
        final messageIndex = _conversationMessages[_selectedContactId]!
            .indexWhere((msg) => msg.id == messageId);
        if (messageIndex != -1) {
          _conversationMessages[_selectedContactId]![messageIndex] =
              _conversationMessages[_selectedContactId]![messageIndex].copyWith(
                isDeleted: true,
              );
        }
      } else {
        await _chatService.deleteMessage(messageId);
        final messageIndex = _conversationMessages[_selectedContactId]!
            .indexWhere((msg) => msg.id == messageId);
        if (messageIndex != -1) {
          _conversationMessages[_selectedContactId]![messageIndex] =
              _conversationMessages[_selectedContactId]![messageIndex].copyWith(
                isDeleted: true,
              );
        }
      }
    });
  }
}
