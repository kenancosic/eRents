import 'dart:convert';

import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/base/api_service_extensions.dart';
import 'package:e_rents_desktop/models/message.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/models/paged_result.dart';
import 'package:signalr_core/signalr_core.dart';

class ChatProvider extends BaseProvider {
  ChatProvider(super.api);

  // ─── State ──────────────────────────────────────────────────────────────
  List<User> _contacts = [];
  List<User> get contacts => _contacts;

  int? _selectedContactId;
  int? get selectedContactId => _selectedContactId;

  final Map<int, List<Message>> _conversations = {};
  final Map<int, int> _currentPage = {};
  final Map<int, bool> _hasMoreMessages = {};
  static const int _pageSize = 50;

  // Presence
  final Map<int, bool> _online = {};
  bool isOnline(int userId) => _online[userId] ?? false;

  // Server-side unread counts (fetched from backend)
  final Map<int, int> _unreadCounts = {};

  // Real-time (SignalR)
  HubConnection? _hub;
  bool _isRealtimeConnected = false;
  bool get isRealtimeConnected => _isRealtimeConnected;

  // ─── Getters ────────────────────────────────────────────────────────────
  bool get isLoadingContacts => isLoading;
  bool get isLoadingMessages => isLoading;

  User? get selectedContact => _selectedContactId == null
      ? null
      : _contacts.cast<User?>().firstWhere((c) => c?.id == _selectedContactId, orElse: () => null);

  List<Message> get activeConversationMessages => _conversations[_selectedContactId] ?? [];
  bool get hasMoreActiveConversationMessages => _hasMoreMessages[_selectedContactId] ?? true;

  // ─── Public API ─────────────────────────────────────────────────────────

  void selectContact(int? contactId) {
    if (_selectedContactId == contactId) return;
    _selectedContactId = contactId;

    if (contactId != null) {
      if (_conversations[contactId] == null || _conversations[contactId]!.isEmpty) {
        loadMessages(contactId);
      }
      // Mark messages as read when selecting contact
      markConversationAsRead(contactId);
    }
    notifyListeners();
  }

  Future<void> loadContacts() async {
    final result = await executeWithState(
      () => api.getListAndDecode('/Messages/Contacts', User.fromJson, authenticated: true),
    );
    
    if (result != null) {
      _contacts = result;
      // Also load unread counts when loading contacts
      await initializeUnreadCounts();
      notifyListeners();
    }
  }

  /// Initialize unread counts from server - call after login
  Future<void> initializeUnreadCounts() async {
    try {
      final response = await api.get('/Messages/UnreadCounts', authenticated: true);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map) {
          _unreadCounts.clear();
          data.forEach((key, value) {
            final contactId = int.tryParse(key.toString());
            if (contactId != null && value is int) {
              _unreadCounts[contactId] = value;
            }
          });
          notifyListeners();
        }
      }
    } catch (e) {
      // Silent fail - unread counts are not critical
    }
  }

  /// Ensures a contact exists in the contacts list.
  /// If not found, fetches the user by ID and adds them to contacts.
  /// Returns true if contact is available, false otherwise.
  Future<bool> ensureContact(int contactId) async {
    // Check if already in contacts
    if (_contacts.any((c) => c.id == contactId)) {
      return true;
    }

    // Fetch user by ID and add to contacts
    final user = await executeWithState<User>(
      () => api.getAndDecode('/users/$contactId', User.fromJson, authenticated: true),
    );

    if (user != null) {
      _contacts.insert(0, user); // Add to top of contacts list
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> loadMessages(int contactId, {bool forceRefresh = false}) async {
    if (isLoading && !forceRefresh) return;

    if (forceRefresh) {
      _conversations.remove(contactId);
      _currentPage.remove(contactId);
      _hasMoreMessages.remove(contactId);
    }

    final page = _currentPage[contactId] ?? 0;
    final endpoint = '/Messages/$contactId/Messages';
    final params = {'page': page, 'pageSize': _pageSize};

    final result = await executeWithState<PagedResult<Message>>(() async {
      return await api.getPagedAndDecode('$endpoint${api.buildQueryString(params)}', Message.fromJson, authenticated: true);
    });

    if (result != null) {
      final newMessages = result.items;
      
      if (page == 0) {
        _conversations[contactId] = newMessages;
      } else {
        _conversations[contactId]?.insertAll(0, newMessages); // Prepend older messages
      }

      _hasMoreMessages[contactId] = newMessages.length == _pageSize;
      _currentPage[contactId] = page + 1;
      notifyListeners();
    }
  }

  Future<void> loadMoreMessages() async {
    if (_selectedContactId != null && hasMoreActiveConversationMessages) {
      await loadMessages(_selectedContactId!);
    }
  }

  Future<bool> sendMessage(int receiverId, String messageText) async {
    final result = await executeWithState<Message>(() async {
      return await api.postAndDecode(
        '/Messages/SendMessage',
        {'receiverId': receiverId, 'messageText': messageText},
        Message.fromJson,
        authenticated: true,
      );
    });
    
    if (result != null) {
      _conversations[receiverId]?.add(result);
      _updateContactActivity(receiverId);
      notifyListeners();
      return true;
    }
    return false;
  }

  // ─── Real-time (SignalR) ────────────────────────────────────────────────
  Future<void> connectRealtime() async {
    if (_hub != null && _isRealtimeConnected) return;
    String _buildHubUrl() {
      final uri = Uri.parse(api.baseUrl);
      var path = uri.path;
      if (path.endsWith('/')) path = path.substring(0, path.length - 1);
      if (path.endsWith('/api')) path = path.substring(0, path.length - 4);
      final cleanPath = path.isEmpty ? '/' : path;
      final hub = uri.replace(path: '${cleanPath == '/' ? '' : cleanPath}/chatHub');
      return hub.toString();
    }
    final hubUrl = _buildHubUrl();
    final token = await api.secureStorageService.getToken();

    _hub = HubConnectionBuilder()
        .withUrl(
          hubUrl,
          HttpConnectionOptions(
            accessTokenFactory: token == null ? null : () async => token,
            transport: HttpTransportType.webSockets,
          ),
        )
        .withAutomaticReconnect()
        .build();

    _registerHubHandlers();

    await _hub!.start();
    _isRealtimeConnected = _hub!.state == HubConnectionState.connected;
    notifyListeners();
  }

  Future<void> disconnectRealtime() async {
    final hub = _hub;
    if (hub != null) {
      try {
        await hub.stop();
      } finally {
        _isRealtimeConnected = false;
        _hub = null;
        notifyListeners();
      }
    }
  }

  void _registerHubHandlers() {
    final hub = _hub;
    if (hub == null) return;

    hub.on('ReceiveMessage', (args) {
      if (args == null || args.isEmpty) return;
      final data = args.first;
      if (data is Map) {
        final senderId = (data['senderId'] as num?)?.toInt();
        final receiverId = (data['receiverId'] as num?)?.toInt();
        final messageText = data['messageText'] as String?;
        final createdAt = data['createdAt'] as String?;
        if (senderId != null && receiverId != null && messageText != null) {
          final sentAt = createdAt != null ? DateTime.tryParse(createdAt) ?? DateTime.now() : DateTime.now();
          final msg = Message(
            messageId: 0,
            senderId: senderId,
            receiverId: receiverId,
            messageText: messageText,
            createdAt: sentAt,
            updatedAt: sentAt,
            isRead: false,
          );
          (_conversations[senderId] ??= []).add(msg);

          // Update unread count if not viewing this conversation
          if (senderId != _selectedContactId) {
            _unreadCounts[senderId] = (_unreadCounts[senderId] ?? 0) + 1;
          }

          notifyListeners();
        }
      }
    });

    hub.on('UserStatusChanged', (args) {
      if (args == null || args.isEmpty) return;
      final data = args.first;
      if (data is Map) {
        final userId = (data['userId'] as num?)?.toInt();
        final isOnline = data['isOnline'] as bool?;
        if (userId != null && isOnline != null) {
          _online[userId] = isOnline;
          notifyListeners();
        }
      }
    });
  }

  @override
  void dispose() {
    final hub = _hub;
    if (hub != null) {
      hub.stop();
      _hub = null;
    }
    super.dispose();
  }

  Future<void> markMessageAsRead(int messageId, int contactId) async {
    final result = await executeWithState<Map<String, dynamic>>(() async {
      return await api.putAndDecode('/Chat/$messageId/read', {}, (json) => json, authenticated: true);
    });
    
    if (result != null) {
      final conversation = _conversations[contactId];
      if (conversation != null) {
        final messageIndex = conversation.indexWhere((m) => m.id == messageId);
        if (messageIndex != -1) {
          conversation[messageIndex] = conversation[messageIndex].copyWith(isRead: true);
        }
      }
      notifyListeners();
    }
  }

  void clearAllData() {
    _contacts.clear();
    _conversations.clear();
    _currentPage.clear();
    _hasMoreMessages.clear();
    _unreadCounts.clear();
    _selectedContactId = null;
    clearError();
    notifyListeners();
  }

  /// Get unread message count for a specific contact
  int getUnreadCount(int contactId) {
    // Prefer server-side count if available
    if (_unreadCounts.containsKey(contactId)) {
      return _unreadCounts[contactId]!;
    }
    // Fallback to local calculation
    final conversation = _conversations[contactId];
    if (conversation == null) return 0;
    return conversation.where((message) => message.isRead == false && message.senderId == contactId).length;
  }

  /// Get total unread message count across all conversations
  int get totalUnreadCount {
    // Sum server-side counts if available
    if (_unreadCounts.isNotEmpty) {
      return _unreadCounts.values.fold(0, (sum, count) => sum + count);
    }
    // Fallback to local calculation
    int total = 0;
    for (final entry in _conversations.entries) {
      final contactId = entry.key;
      final messages = entry.value;
      total += messages.where((m) => m.isRead == false && m.senderId == contactId).length;
    }
    return total;
  }

  /// Mark all messages from a contact as read
  Future<void> markConversationAsRead(int contactId) async {
    if (getUnreadCount(contactId) == 0) return;

    try {
      await api.put('/Messages/$contactId/ReadAll', {}, authenticated: true);

      // Update local state
      _unreadCounts[contactId] = 0;

      // Update loaded messages
      final conversation = _conversations[contactId];
      if (conversation != null) {
        for (var i = 0; i < conversation.length; i++) {
          if (conversation[i].senderId == contactId && conversation[i].isRead == false) {
            conversation[i] = conversation[i].copyWith(isRead: true);
          }
        }
      }

      notifyListeners();
    } catch (e) {
      // Silent fail - will sync on next refresh
    }
  }

  /// Get the last message text for a specific contact
  String? getLastMessage(int contactId) {
    final conversation = _conversations[contactId];
    if (conversation == null || conversation.isEmpty) return null;
    return conversation.last.messageText;
  }

  /// Get the last activity timestamp for a specific contact
  DateTime? getLastActivity(int contactId) {
    final conversation = _conversations[contactId];
    if (conversation == null || conversation.isEmpty) return null;
    return conversation.last.dateSent;
  }

  // ─── Private Helpers ────────────────────────────────────────────────────

  void _updateContactActivity(int contactId) {
    final index = _contacts.indexWhere((c) => c.id == contactId);
    if (index != -1) {
      final contact = _contacts.removeAt(index);
      _contacts.insert(0, contact);
    }
  }
}
