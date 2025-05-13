import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/models/message.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:flutter/foundation.dart';

class ChatProvider extends BaseProvider<Message> {
  final ApiService _apiService;
  final Map<String, List<Message>> _conversationMessages = {};
  final Map<String, User> _contacts = {};
  String? _selectedContactId;
  bool _isLoading = false;
  String? _error;

  ChatProvider(this._apiService) : super(_apiService) {
    enableMockData(); // Use mock data by default
  }

  // Getters
  List<Message> get messages => _conversationMessages[_selectedContactId] ?? [];
  List<User> get contacts => _contacts.values.toList();
  User? get selectedContact =>
      _selectedContactId != null ? _contacts[_selectedContactId] : null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Set the currently selected contact
  void selectContact(String contactId) {
    _selectedContactId = contactId;
    notifyListeners();
    loadMessages(contactId);
  }

  @override
  String get endpoint => '/messages';

  @override
  Message fromJson(Map<String, dynamic> json) => Message.fromJson(json);

  @override
  Map<String, dynamic> toJson(Message item) => item.toJson();

  @override
  List<Message> getMockItems() {
    // Just return an empty list here since we're managing messages per conversation
    return [];
  }

  // Helper method to determine if we should use mock data
  bool _shouldUseMockData() {
    // In a real app, this might check if we're in debug mode or have a flag set
    return true; // For now, always use mock data
  }

  // Load all contacts
  Future<void> loadContacts() async {
    _isLoading = true;
    notifyListeners();

    try {
      // In a real app, we would fetch contacts from the API
      // For now, use mock data
      await Future.delayed(
        const Duration(milliseconds: 500),
      ); // Simulate network delay

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

      for (final user in mockUsers) {
        _contacts[user.id] = user;
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading contacts: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load messages for a specific contact
  Future<void> loadMessages(String contactId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // In a real app, we would fetch messages from the API
      // For now, use mock data
      await Future.delayed(
        const Duration(milliseconds: 500),
      ); // Simulate network delay

      if (!_conversationMessages.containsKey(contactId)) {
        _conversationMessages[contactId] = [];

        // Generate some mock messages
        final currentUserId =
            'currentUser'; // This would come from auth service
        final mockMessages = List.generate(
          5,
          (index) => Message(
            id: 'msg$index-$contactId',
            senderId: index % 2 == 0 ? currentUserId : contactId,
            receiverId: index % 2 == 0 ? contactId : currentUserId,
            messageText:
                'This is message ${index + 1} between you and contact $contactId',
            dateSent: DateTime.now().subtract(Duration(hours: index * 2)),
          ),
        );

        _conversationMessages[contactId] = mockMessages;
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading messages: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Send a message
  Future<void> sendMessage(Message message) async {
    _isLoading = true;
    notifyListeners();

    try {
      // In a real app, we would send the message to the API
      // For now, just add it to our local collection
      await Future.delayed(
        const Duration(milliseconds: 300),
      ); // Simulate network delay

      if (_shouldUseMockData()) {
        if (!_conversationMessages.containsKey(message.receiverId)) {
          _conversationMessages[message.receiverId] = [];
        }

        _conversationMessages[message.receiverId]!.add(message);
      } else {
        // In a real app, we would send the message via API
        await _apiService.post('$endpoint/send', message.toJson());

        // And then add it to our local collection
        if (!_conversationMessages.containsKey(message.receiverId)) {
          _conversationMessages[message.receiverId] = [];
        }

        _conversationMessages[message.receiverId]!.add(message);
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error sending message: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Send a property offer message
  Future<void> sendPropertyOfferMessage(
    String receiverId,
    String propertyId,
    String senderId,
  ) async {
    final String offerMessageContent = "PROPERTY_OFFER::$propertyId";
    final newMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: senderId,
      receiverId: receiverId,
      messageText: offerMessageContent,
      dateSent: DateTime.now(),
    );
    await sendMessage(newMessage); // Use the existing sendMessage logic
  }

  // Delete a message
  Future<void> deleteMessage(String messageId) async {
    if (_selectedContactId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // In a real app, we would update the message on the API
      // For now, just update our local collection
      await Future.delayed(
        const Duration(milliseconds: 300),
      ); // Simulate network delay

      final messageIndex = _conversationMessages[_selectedContactId]!
          .indexWhere((message) => message.id == messageId);

      if (messageIndex != -1) {
        final message =
            _conversationMessages[_selectedContactId]![messageIndex];
        _conversationMessages[_selectedContactId]![messageIndex] = message
            .copyWith(isDeleted: true);
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting message: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
