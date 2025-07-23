
import 'dart:convert';

import 'package:e_rents_desktop/models/message.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:e_rents_desktop/utils/logger.dart';

/// Consolidated provider for the Chat feature.
///
/// This provider manages all state and business logic for chat, including:
/// - Fetching and caching contacts and messages.
/// - Sending, deleting, and updating messages.
/// - Managing UI state such as loading indicators, errors, and selected conversations.
///
/// This replaces `ChatCollectionProvider`, `ChatDetailProvider`, `ChatRepository`, and `ChatService`.
class ChatProvider extends ChangeNotifier {
  final ApiService _apiService;

  // State
  bool _isLoadingContacts = false;
  bool _isLoadingMessages = false;
  String? _error;

  // Data
  List<User> _contacts = [];
  int? _selectedContactId;

  // Conversation messages, mapped by contact ID
  final Map<int, List<Message>> _conversations = {};
  final Map<int, DateTime> _lastActivity = {};

  // Pagination state, mapped by contact ID
  final Map<int, int> _currentPage = {};
  final Map<int, bool> _hasMoreMessages = {};
  static const int _pageSize = 50;

  // Caching
  DateTime? _contactsCacheTimestamp;
  static const Duration _contactsCacheTtl = Duration(hours: 1);

  ChatProvider(this._apiService);

  // --- Getters ---
  bool get isLoading => _isLoadingContacts || _isLoadingMessages;
  String? get error => _error;
  List<User> get contacts => _contacts;
  int? get selectedContactId => _selectedContactId;
    User? get selectedContact {
    if (_selectedContactId == null) return null;
    try {
      return _contacts.firstWhere((c) => c.id == _selectedContactId);
    } catch (e) {
      return null;
    }
  }
  List<Message> get activeConversationMessages => _conversations[_selectedContactId] ?? [];
  bool get hasMoreActiveConversationMessages => _hasMoreMessages[_selectedContactId] ?? true;

  // --- Public API ---

  int getUnreadCount(int contactId) {
    final conversation = _conversations[contactId];
    if (conversation == null) return 0;
    return conversation.where((m) => !m.isRead && m.senderId == contactId).length;
  }

  DateTime? getLastActivity(int contactId) {
    return _lastActivity[contactId];
  }

  String? getLastMessage(int contactId) {
    final conversation = _conversations[contactId];
    if (conversation == null || conversation.isEmpty) return null;
    return conversation.first.messageText;
  }

  /// Searches contacts by name or email.
  List<User> searchContacts(String query) {
    if (query.isEmpty) return _contacts;

    final lowercaseQuery = query.toLowerCase();
    return _contacts.where((contact) {
      return contact.fullName.toLowerCase().contains(lowercaseQuery) ||
          contact.email.toLowerCase().contains(lowercaseQuery) ||
          contact.username.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }


  /// Selects a contact and loads their conversation.
  void selectContact(int? contactId) {
    if (_selectedContactId == contactId) return;
    _selectedContactId = contactId;

    if (contactId != null && (_conversations[contactId] == null || _conversations[contactId]!.isEmpty)) {
      loadMessages(contactId);
    }
    notifyListeners();
  }

  /// Fetches the list of contacts, using a cache.
  Future<void> loadContacts({bool forceRefresh = false}) async {
    if (_isLoadingContacts) return;

    final isCacheValid = _contactsCacheTimestamp != null && DateTime.now().difference(_contactsCacheTimestamp!) < _contactsCacheTtl;
    if (!forceRefresh && isCacheValid && _contacts.isNotEmpty) {
      return;
    }

    _isLoadingContacts = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/Chat/Contacts', authenticated: true);
      final jsonResponse = json.decode(response.body);
      final List<dynamic> itemsJson = jsonResponse['items'] ?? jsonResponse;
      _contacts = itemsJson.map((json) => User.fromJson(json)).toList();
      _contactsCacheTimestamp = DateTime.now();
    } catch (e) {
      _error = 'Failed to load contacts: $e';
    } finally {
      _isLoadingContacts = false;
      notifyListeners();
    }
  }

  /// Fetches messages for a given contact, with pagination.
  Future<void> loadMessages(int contactId, {bool forceRefresh = false}) async {
    if (_isLoadingMessages && !forceRefresh) return;

    if (forceRefresh) {
      _conversations.remove(contactId);
      _currentPage.remove(contactId);
      _hasMoreMessages.remove(contactId);
    }

    _isLoadingMessages = true;
    _error = null;
    notifyListeners();

    try {
      final page = _currentPage[contactId] ?? 0;
      final endpoint = '/Chat/$contactId/Messages?page=${page + 1}&pageSize=$_pageSize';
      final response = await _apiService.get(endpoint, authenticated: true);

      final jsonResponse = json.decode(response.body);
      final List<dynamic> itemsJson = jsonResponse['items'] ?? [];
      final newMessages = itemsJson.map((json) => Message.fromJson(json)).toList();

      if (page == 0) {
        _conversations[contactId] = newMessages;
      } else {
        _conversations[contactId]?.insertAll(0, newMessages); // Prepend older messages
      }

      _hasMoreMessages[contactId] = newMessages.length == _pageSize;
      _currentPage[contactId] = page + 1;

    } catch (e) {
      _error = 'Failed to load messages for contact $contactId: $e';
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  /// Loads more messages for the currently active conversation.
  Future<void> loadMoreMessages() async {
    if (_selectedContactId != null && (_hasMoreMessages[_selectedContactId] ?? true)) {
      await loadMessages(_selectedContactId!);
    }
  }

  /// Sends a text message to a receiver.
  Future<bool> sendMessage(int receiverId, String messageText) async {
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post('/Chat/SendMessage', {
        'receiverId': receiverId,
        'messageText': messageText,
      }, authenticated: true);

      final newMessage = Message.fromJson(json.decode(response.body));
      _conversations[receiverId]?.add(newMessage);
      // Move contact to top
      _updateContactActivity(receiverId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to send message: $e';
      notifyListeners();
      return false;
    }
  }

  /// Marks a message as read.
  Future<void> markMessageAsRead(int messageId, int contactId) async {
    try {
      await _apiService.put('/Chat/$messageId/read', {}, authenticated: true);
      final conversation = _conversations[contactId];
      if (conversation != null) {
        final messageIndex = conversation.indexWhere((m) => m.id == messageId);
        if (messageIndex != -1) {
          conversation[messageIndex] = conversation[messageIndex].copyWith(isRead: true);
          notifyListeners();
        }
      }
    } catch (e, stackTrace) {
      // Silently fail or log error
      log.warning('Failed to mark message as read', e, stackTrace);
    }
  }

  /// Clears all local data and caches.
  void clearAllData() {
    _contacts.clear();
    _conversations.clear();
    _currentPage.clear();
    _hasMoreMessages.clear();
    _selectedContactId = null;
    _contactsCacheTimestamp = null;
    _error = null;
    notifyListeners();
  }

  // --- Private Helpers ---

  void _updateContactActivity(int contactId) {
    final index = _contacts.indexWhere((c) => c.id == contactId);
    if (index != -1) {
      final contact = _contacts.removeAt(index);
      _contacts.insert(0, contact);
    }
  }
}
