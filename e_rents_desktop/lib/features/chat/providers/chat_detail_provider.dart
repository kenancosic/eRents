import 'package:e_rents_desktop/base/base.dart';
import 'package:e_rents_desktop/models/message.dart';
import 'package:e_rents_desktop/repositories/chat_repository.dart';

/// Detail provider for managing individual chat conversations
/// Handles message loading, sending, deletion, and read status management
class ChatDetailProvider extends DetailProvider<Message> {
  final ChatRepository _chatRepository;

  // Current conversation context
  int? _contactId;
  List<Message> _messages = [];
  bool _isLoadingMessages = false;

  // Message pagination
  int _currentPage = 0;
  final int _pageSize = 50;
  bool _hasMoreMessages = true;

  ChatDetailProvider(this._chatRepository) : super(_chatRepository);

  // Getters
  int? get contactId => _contactId;
  List<Message> get messages => List.unmodifiable(_messages);
  bool get isLoadingMessages => _isLoadingMessages;
  bool get hasMoreMessages => _hasMoreMessages;
  int get messageCount => _messages.length;

  /// Load messages for a specific contact
  Future<void> loadMessages(int contactId, {bool forceRefresh = false}) async {
    if (_isLoadingMessages && !forceRefresh) return;

    // If switching to a different contact, reset the conversation
    if (_contactId != contactId) {
      _contactId = contactId;
      _messages.clear();
      _currentPage = 0;
      _hasMoreMessages = true;
    }

    _isLoadingMessages = true;
    notifyListeners();

    try {
      final messages = await _chatRepository.getMessages(
        contactId,
        page: _currentPage,
        pageSize: _pageSize,
        forceRefresh: forceRefresh,
      );

      if (_currentPage == 0) {
        // First load or refresh
        _messages = messages;
      } else {
        // Pagination - append messages
        _messages.addAll(messages);
      }

      // Update pagination state
      _hasMoreMessages = messages.length == _pageSize;
      if (messages.isNotEmpty) {
        _currentPage++;
      }

      await _updateItem(_contactId.toString());
    } catch (e, stackTrace) {
      // Handle error for message loading - don't use base provider error handling
      // as this is a custom loading operation
      rethrow;
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  /// Load more messages (for pagination)
  Future<void> loadMoreMessages() async {
    if (!_hasMoreMessages || _isLoadingMessages || _contactId == null) return;

    await loadMessages(_contactId!, forceRefresh: false);
  }

  /// Refresh current conversation
  Future<void> refreshMessages() async {
    if (_contactId == null) return;

    _currentPage = 0;
    await loadMessages(_contactId!, forceRefresh: true);
  }

  /// Send a new message
  Future<Message> sendMessage(int receiverId, String messageText) async {
    try {
      final sentMessage = await _chatRepository.sendMessage(
        receiverId,
        messageText,
      );

      // Add to local messages list
      _messages.add(sentMessage);

      await _updateItem(receiverId.toString());

      return sentMessage;
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Send a property offer message
  Future<Message> sendPropertyOffer(int receiverId, int propertyId) async {
    try {
      final sentMessage = await _chatRepository.sendPropertyOfferMessage(
        receiverId,
        propertyId,
      );

      // Add to local messages list
      _messages.add(sentMessage);

      await _updateItem(receiverId.toString());

      return sentMessage;
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Delete a message
  Future<void> deleteMessage(int messageId) async {
    if (_contactId == null) return;

    try {
      await _chatRepository.deleteMessage(messageId, _contactId!);

      // Update local message list - mark as deleted
      final messageIndex = _messages.indexWhere((msg) => msg.id == messageId);
      if (messageIndex != -1) {
        _messages[messageIndex] = _messages[messageIndex].copyWith(
          isDeleted: true,
        );
      }

      await _updateItem(_contactId.toString());
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Mark a message as read
  Future<void> markMessageAsRead(int messageId) async {
    if (_contactId == null) return;

    try {
      await _chatRepository.markMessageAsRead(messageId, _contactId!);

      // Update local message list
      final messageIndex = _messages.indexWhere((msg) => msg.id == messageId);
      if (messageIndex != -1) {
        _messages[messageIndex] = _messages[messageIndex].copyWith(
          isRead: true,
        );
      }

      await _updateItem(_contactId.toString());
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Mark all messages in conversation as read
  Future<void> markAllMessagesAsRead() async {
    if (_contactId == null) return;

    try {
      // Mark each unread message as read
      final unreadMessages =
          _messages
              .where((msg) => !msg.isRead && msg.receiverId == _contactId)
              .toList();

      for (final message in unreadMessages) {
        await markMessageAsRead(message.id);
      }
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Get unread messages count for current conversation
  int getUnreadMessagesCount() {
    if (_contactId == null) return 0;

    return _messages
        .where((msg) => !msg.isRead && msg.receiverId == _contactId)
        .length;
  }

  /// Get last message in current conversation
  Message? getLastMessage() {
    if (_messages.isEmpty) return null;
    return _messages.last;
  }

  /// Search messages in current conversation
  List<Message> searchMessages(String query) {
    if (query.isEmpty) return messages;

    final lowercaseQuery = query.toLowerCase();
    return _messages.where((message) {
      return message.messageText.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  /// Filter messages by type (e.g., property offers)
  List<Message> getMessagesByType(String type) {
    return _messages.where((message) {
      return message.messageText.startsWith(type);
    }).toList();
  }

  /// Get property offers in current conversation
  List<Message> getPropertyOffers() {
    return getMessagesByType('PROPERTY_OFFER::');
  }

  /// Clear current conversation
  void clearConversation() {
    _contactId = null;
    _messages.clear();
    _currentPage = 0;
    _hasMoreMessages = true;
    _isLoadingMessages = false;
    clear();
  }

  /// Clear conversation cache for current contact
  void clearCache() {
    if (_contactId != null) {
      _chatRepository.clearContactCache(_contactId!);
    }
  }

  // Private helper method to update item in base provider
  Future<void> _updateItem(String itemId) async {
    // Get the last message as the "item" for this conversation
    final lastMessage = getLastMessage();
    if (lastMessage != null) {
      setItem(lastMessage, itemId);
    }
  }

  @override
  void dispose() {
    clearConversation();
    super.dispose();
  }
}
