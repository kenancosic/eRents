import 'dart:convert';
import 'package:e_rents_desktop/base/base.dart';
import 'package:e_rents_desktop/models/message.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/services/chat_service.dart';
import 'package:e_rents_desktop/services/api_service.dart';

/// Repository for chat data management with caching and real-time capabilities
/// Handles both messages and contacts with appropriate TTL strategies
class ChatRepository extends BaseRepository<Message, ChatService> {
  // Separate cache for contacts with longer TTL
  final Map<String, List<User>> _contactsCache = {};
  DateTime? _contactsCacheTimestamp;
  static const Duration _contactsCacheTtl = Duration(
    hours: 1,
  ); // Contacts change less frequently

  // Messages cache per conversation
  final Map<int, List<Message>> _messagesCache = {};
  final Map<int, DateTime> _messagesCacheTimestamp = {};
  static const Duration _messagesCacheTtl = Duration(
    minutes: 5,
  ); // Messages need more frequent updates

  final ApiService _apiService;

  ChatRepository({
    required super.service,
    required super.cacheManager,
    required ApiService apiService,
  }) : _apiService = apiService;

  @override
  String get resourceName => 'chat';

  @override
  Duration get defaultCacheTtl => _messagesCacheTtl;

  /// Get contacts (cached for 1 hour)
  Future<List<User>> getContacts({bool forceRefresh = false}) async {
    const cacheKey = 'contacts';

    // Check cache validity
    if (!forceRefresh &&
        _contactsCache.containsKey(cacheKey) &&
        _contactsCacheTimestamp != null &&
        DateTime.now().difference(_contactsCacheTimestamp!) <
            _contactsCacheTtl) {
      return _contactsCache[cacheKey]!;
    }

    try {
      final contacts = await service.getContacts();

      // Update cache
      _contactsCache[cacheKey] = contacts;
      _contactsCacheTimestamp = DateTime.now();

      return contacts;
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Get messages for a specific conversation (cached for 5 minutes)
  Future<List<Message>> getMessages(
    int contactId, {
    int? page,
    int? pageSize,
    bool forceRefresh = false,
  }) async {
    // Check cache validity
    if (!forceRefresh &&
        _messagesCache.containsKey(contactId) &&
        _messagesCacheTimestamp.containsKey(contactId) &&
        DateTime.now().difference(_messagesCacheTimestamp[contactId]!) <
            _messagesCacheTtl) {
      final messages = _messagesCache[contactId]!;

      // Apply pagination if requested
      if (page != null && pageSize != null) {
        final startIndex = page * pageSize;
        final endIndex = (startIndex + pageSize).clamp(0, messages.length);
        return messages.sublist(startIndex.clamp(0, messages.length), endIndex);
      }

      return messages;
    }

    try {
      final messages = await service.getMessages(
        contactId,
        page: page,
        pageSize: pageSize,
      );

      // Update cache
      _messagesCache[contactId] = messages;
      _messagesCacheTimestamp[contactId] = DateTime.now();

      return messages;
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Send a standard message
  Future<Message> sendMessage(int receiverId, String messageText) async {
    try {
      final response = await _apiService.post('/Chat/SendMessage', {
        'receiverId': receiverId,
        'messageText': messageText,
      });

      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      return Message.fromJson(jsonData);
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Send an enterprise message with guaranteed delivery (RabbitMQ + SignalR)
  Future<Message> sendEnterpriseMessage(
    int receiverId,
    String messageText,
  ) async {
    try {
      final response = await _apiService.post('/Chat/SendEnterpriseMessage', {
        'receiverId': receiverId,
        'messageText': messageText,
      });

      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      // Extract the actual message from the enterprise response
      final messageData = jsonData['data'] as Map<String, dynamic>;
      return Message.fromJson(messageData);
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Send a property offer message using enterprise delivery
  Future<Message> sendPropertyOfferMessage(
    int receiverId,
    int propertyId,
  ) async {
    try {
      final response = await _apiService.post('/Chat/SendPropertyOffer', {
        'receiverId': receiverId,
        'propertyId': propertyId,
      });

      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      // Extract the actual message from the enterprise response
      final messageData = jsonData['data'] as Map<String, dynamic>;
      return Message.fromJson(messageData);
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Delete a message and update cache
  Future<void> deleteMessage(int messageId, int contactId) async {
    try {
      await service.deleteMessage(messageId);

      // Update cache - mark message as deleted
      if (_messagesCache.containsKey(contactId)) {
        final messageIndex = _messagesCache[contactId]!.indexWhere(
          (msg) => msg.id == messageId,
        );
        if (messageIndex != -1) {
          _messagesCache[contactId]![messageIndex] =
              _messagesCache[contactId]![messageIndex].copyWith(
                isDeleted: true,
              );
        }
      }
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Mark message as read and update cache
  Future<void> markMessageAsRead(int messageId, int contactId) async {
    try {
      await service.markMessageAsRead(messageId);

      // Update cache - mark message as read
      if (_messagesCache.containsKey(contactId)) {
        final messageIndex = _messagesCache[contactId]!.indexWhere(
          (msg) => msg.id == messageId,
        );
        if (messageIndex != -1) {
          _messagesCache[contactId]![messageIndex] =
              _messagesCache[contactId]![messageIndex].copyWith(isRead: true);
        }
      }
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Get unread message count for a contact
  int getUnreadMessageCount(int contactId) {
    if (!_messagesCache.containsKey(contactId)) return 0;

    return _messagesCache[contactId]!
        .where((message) => !message.isRead && message.receiverId != contactId)
        .length;
  }

  /// Get last message for a contact
  Message? getLastMessage(int contactId) {
    if (!_messagesCache.containsKey(contactId) ||
        _messagesCache[contactId]!.isEmpty) {
      return null;
    }

    final messages = _messagesCache[contactId]!;
    return messages.isNotEmpty ? messages.last : null;
  }

  /// Get contact statistics
  Map<String, int> getContactStatistics(List<User> contacts) {
    int totalUnread = 0;
    int activeChats = 0;

    for (final contact in contacts) {
      final unreadCount = getUnreadMessageCount(contact.id);
      if (unreadCount > 0) totalUnread += unreadCount;
      if (_messagesCache.containsKey(contact.id) &&
          _messagesCache[contact.id]!.isNotEmpty) {
        activeChats++;
      }
    }

    return {
      'totalContacts': contacts.length,
      'activeChats': activeChats,
      'totalUnread': totalUnread,
    };
  }

  /// Clear cache for specific contact
  void clearContactCache(int contactId) {
    _messagesCache.remove(contactId);
    _messagesCacheTimestamp.remove(contactId);
  }

  /// Clear all contacts cache
  void clearContactsCache() {
    _contactsCache.clear();
    _contactsCacheTimestamp = null;
  }

  @override
  Future<void> clearCache() async {
    await super.clearCache();
    _messagesCache.clear();
    _messagesCacheTimestamp.clear();
    clearContactsCache();
  }

  // Implementing required BaseRepository abstract methods

  @override
  Future<List<Message>> fetchAllFromService([
    Map<String, dynamic>? params,
  ]) async {
    // For messages, we need a contact ID to fetch messages
    // This method could return recent messages across all conversations
    final contacts = await getContacts();
    final allMessages = <Message>[];

    for (final contact in contacts) {
      try {
        final messages = await getMessages(contact.id);
        allMessages.addAll(messages);
      } catch (e) {
        // Continue with other contacts if one fails
        continue;
      }
    }

    // Sort by date descending (most recent first)
    allMessages.sort((a, b) => b.dateSent.compareTo(a.dateSent));

    return allMessages;
  }

  @override
  Future<Message> fetchByIdFromService(String id) async {
    final messageId = int.tryParse(id);
    if (messageId == null) {
      throw AppError(
        type: ErrorType.validation,
        message: 'Invalid message ID format',
        details: 'Expected numeric ID but got: $id',
      );
    }

    // Search through all cached conversations first
    for (final messages in _messagesCache.values) {
      final foundMessage =
          messages.where((msg) => msg.id == messageId).firstOrNull;
      if (foundMessage != null) return foundMessage;
    }

    // If not found in cache, we'd need to search all conversations
    // This is expensive, so we'll throw a not found error for now
    throw AppError(
      type: ErrorType.notFound,
      message: 'Message not found',
      details: 'No message found with ID: $id',
    );
  }

  @override
  Future<Message> createInService(Message message) async {
    return await sendMessage(message.receiverId, message.messageText);
  }

  @override
  Future<Message> updateInService(String id, Message message) async {
    // Messages typically aren't updated, but this could be used for editing
    throw UnsupportedError('Message updates are not supported');
  }

  @override
  Future<void> deleteInService(String id) async {
    final messageId = int.tryParse(id);
    if (messageId == null) throw ArgumentError('Invalid message ID');

    // Find the contact ID for this message
    int? contactId;
    for (final entry in _messagesCache.entries) {
      if (entry.value.any((msg) => msg.id == messageId)) {
        contactId = entry.key;
        break;
      }
    }

    if (contactId != null) {
      await deleteMessage(messageId, contactId);
    } else {
      await service.deleteMessage(messageId);
    }
  }

  @override
  Future<bool> existsInService(String id) async {
    try {
      await fetchByIdFromService(id);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<int> countInService([Map<String, dynamic>? params]) async {
    final contacts = await getContacts();
    int totalMessages = 0;

    for (final contact in contacts) {
      try {
        final messages = await getMessages(contact.id);
        totalMessages += messages.length;
      } catch (e) {
        continue;
      }
    }

    return totalMessages;
  }

  @override
  String? extractIdFromItem(Message item) {
    return item.id.toString();
  }
}
