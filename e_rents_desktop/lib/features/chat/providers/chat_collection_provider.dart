import 'package:e_rents_desktop/base/base.dart';
import 'package:e_rents_desktop/models/message.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/repositories/chat_repository.dart';

/// Collection provider for managing chat contacts and conversations list
/// Handles contacts loading, conversation overview, and real-time updates
class ChatCollectionProvider extends CollectionProvider<Message> {
  final ChatRepository _chatRepository;

  // Contacts management
  List<User> _contacts = [];
  bool _isLoadingContacts = false;

  // Active conversation tracking
  int? _selectedContactId;
  User? _selectedContact;

  // Real-time updates
  final Map<int, DateTime> _lastActivityMap = {};
  final Map<int, int> _unreadCountMap = {};

  ChatCollectionProvider(this._chatRepository) : super(_chatRepository);

  // Getters for contacts
  List<User> get contacts => _contacts;
  bool get isLoadingContacts => _isLoadingContacts;
  User? get selectedContact => _selectedContact;
  int? get selectedContactId => _selectedContactId;

  // Statistics getters
  int get totalContacts => _contacts.length;
  int get totalUnreadMessages =>
      _unreadCountMap.values.fold(0, (sum, count) => sum + count);
  int get activeChatsCount => _lastActivityMap.length;

  // Required by CollectionProvider
  @override
  String _getItemId(Message item) => item.id.toString();

  @override
  Future<void> loadAllData() async {
    await loadContacts();
    await _updateContactStatistics();
  }

  /// Load all contacts using disposal-safe operations
  Future<void> loadContacts({bool forceRefresh = false}) async {
    if (_isLoadingContacts || disposed) return;

    _isLoadingContacts = true;
    if (!disposed) notifyListeners();

    try {
      final contacts = await _chatRepository.getContacts(
        forceRefresh: forceRefresh,
      );

      if (!disposed) {
        _contacts = contacts;
        // Update statistics after loading contacts
        await _updateContactStatistics();
      }
    } catch (e, stackTrace) {
      if (!disposed) {
        // Handle error appropriately for contacts loading
        throw AppError.fromException(e, stackTrace);
      }
    } finally {
      if (!disposed) {
        _isLoadingContacts = false;
        notifyListeners();
      }
    }
  }

  /// Refresh contacts
  Future<void> refreshContacts() async {
    await loadContacts(forceRefresh: true);
  }

  /// Select a contact for conversation
  void selectContact(int contactId) {
    if (disposed) return;

    _selectedContactId = contactId;
    _selectedContact = _contacts.firstWhere(
      (contact) => contact.id == contactId,
      orElse:
          () => User(
            id: contactId,
            email: 'unknown@example.com',
            username: 'unknown',
            firstName: 'Unknown',
            lastName: 'User',
            role: UserType.tenant,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
    );
    notifyListeners();
  }

  /// Clear contact selection
  void clearSelection() {
    if (disposed) return;

    _selectedContactId = null;
    _selectedContact = null;
    notifyListeners();
  }

  /// Get unread message count for a specific contact
  int getUnreadCount(int contactId) {
    return _unreadCountMap[contactId] ?? 0;
  }

  /// Get last activity timestamp for a contact
  DateTime? getLastActivity(int contactId) {
    return _lastActivityMap[contactId];
  }

  /// Get last message for a contact
  Message? getLastMessage(int contactId) {
    return _chatRepository.getLastMessage(contactId);
  }

  /// Update unread count for a contact
  void updateUnreadCount(int contactId, int count) {
    if (disposed) return;

    _unreadCountMap[contactId] = count;
    notifyListeners();
  }

  /// Mark all messages as read for a contact
  Future<void> markContactAsRead(int contactId) async {
    if (disposed) return;

    _unreadCountMap[contactId] = 0;
    notifyListeners();
  }

  /// Update last activity for a contact
  void updateLastActivity(int contactId, DateTime timestamp) {
    if (disposed) return;

    _lastActivityMap[contactId] = timestamp;
    notifyListeners();
  }

  /// Search contacts by name or email
  List<User> searchContacts(String query) {
    if (query.isEmpty) return _contacts;

    final lowercaseQuery = query.toLowerCase();
    return _contacts.where((contact) {
      return contact.fullName.toLowerCase().contains(lowercaseQuery) ||
          contact.email.toLowerCase().contains(lowercaseQuery) ||
          contact.username.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  /// Get contacts sorted by last activity
  List<User> getContactsByActivity() {
    final sortedContacts = List<User>.from(_contacts);
    sortedContacts.sort((a, b) {
      final aActivity = _lastActivityMap[a.id];
      final bActivity = _lastActivityMap[b.id];

      if (aActivity == null && bActivity == null) return 0;
      if (aActivity == null) return 1;
      if (bActivity == null) return -1;

      return bActivity.compareTo(aActivity); // Most recent first
    });
    return sortedContacts;
  }

  /// Get contacts with unread messages
  List<User> getContactsWithUnread() {
    return _contacts.where((contact) {
      final unreadCount = _unreadCountMap[contact.id] ?? 0;
      return unreadCount > 0;
    }).toList();
  }

  /// Send a property offer message through repository
  Future<Message> sendPropertyOfferMessage(
    int receiverId,
    int propertyId,
  ) async {
    try {
      final message = await _chatRepository.sendPropertyOfferMessage(
        receiverId,
        propertyId,
      );

      // Update activity tracking
      updateLastActivity(receiverId, message.dateSent);

      return message;
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Get conversation statistics
  Map<String, dynamic> getConversationStatistics() {
    final stats = _chatRepository.getContactStatistics(_contacts);

    return {
      ...stats,
      'unreadContacts': getContactsWithUnread().length,
      'lastActivity':
          _lastActivityMap.isNotEmpty
              ? _lastActivityMap.values.reduce((a, b) => a.isAfter(b) ? a : b)
              : null,
    };
  }

  /// Update contact statistics from repository
  Future<void> _updateContactStatistics() async {
    _unreadCountMap.clear();
    _lastActivityMap.clear();

    for (final contact in _contacts) {
      // Get unread count from repository
      final unreadCount = _chatRepository.getUnreadMessageCount(contact.id);
      if (unreadCount > 0) {
        _unreadCountMap[contact.id] = unreadCount;
      }

      // Get last message to determine activity
      final lastMessage = _chatRepository.getLastMessage(contact.id);
      if (lastMessage != null) {
        _lastActivityMap[contact.id] = lastMessage.dateSent;
      }
    }

    if (!disposed) notifyListeners();
  }

  /// Clear specific contact cache
  void clearContactCache(int contactId) {
    _chatRepository.clearContactCache(contactId);
    _unreadCountMap.remove(contactId);
    _lastActivityMap.remove(contactId);
    if (!disposed) notifyListeners();
  }

  /// Clear all chat caches
  Future<void> clearAllCache() async {
    await _chatRepository.clearCache();
    _unreadCountMap.clear();
    _lastActivityMap.clear();
    _contacts.clear();
    clearSelection();
    if (!disposed) notifyListeners();
  }

  /// Refresh all data
  @override
  Future<void> refreshAllData() async {
    await clearAllCache();
    await loadAllData();
  }

  @override
  void dispose() {
    _contacts.clear();
    _unreadCountMap.clear();
    _lastActivityMap.clear();
    clearSelection();
    super.dispose();
  }
}
