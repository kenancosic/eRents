import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/base/api_service_extensions.dart';
import 'package:e_rents_mobile/core/models/user.dart';
import 'package:e_rents_mobile/core/models/message.dart' as core;
import 'package:signalr_core/signalr_core.dart';

/// Backend-aligned chat provider using MessagesController REST API
/// Does not impact existing chat UI; integrate when ready.
class BackendChatProvider extends BaseProvider {
  BackendChatProvider(super.api);

  // Contacts and conversations
  List<User> _contacts = [];
  final Map<int, List<core.Message>> _conversations = {};
  final Map<int, bool> _hasMore = {};
  final Map<int, int> _page = {};
  static const int _pageSize = 50;

  // Presence (from SignalR when added)
  final Map<int, bool> _online = {};

  // SignalR
  HubConnection? _hub;
  bool _isRealtimeConnected = false;

  // Getters
  List<User> get contacts => _contacts;
  List<core.Message> messagesFor(int contactId) => _conversations[contactId] ?? [];
  bool hasMore(int contactId) => _hasMore[contactId] ?? true;
  bool isOnline(int contactId) => _online[contactId] ?? false;

  bool get isRealtimeConnected => _isRealtimeConnected;

  // Load contacts
  Future<void> loadContacts() async {
    final result = await executeWithState<List<User>>(() async {
      // Backend returns PascalCase fields: { Id, FirstName, LastName, Email, Username, ProfileImageId }
      const ep = '/Messages/Contacts';
      // ignore: avoid_print
      print('BackendChatProvider: GET contacts -> ${api.baseUrl.endsWith('/') ? api.baseUrl.substring(0, api.baseUrl.length - 1) : api.baseUrl}$ep');
      final raw = await api.getListAndDecode(
        ep,
        (json) => json, // decode as raw map first
        authenticated: true,
      );
      return raw.map<User>((dynamic item) {
        final m = (item as Map<String, dynamic>);
        // Support both camelCase and PascalCase
        final id = m['userId'] ?? m['UserId'] ?? m['id'] ?? m['Id'];
        final firstName = m['firstName'] ?? m['FirstName'];
        final lastName = m['lastName'] ?? m['LastName'];
        final email = m['email'] ?? m['Email'];
        final username = m['username'] ?? m['Username'];
        final profileImageId = m['profileImageId'] ?? m['ProfileImageId'];
        return User(
          userId: id is int ? id : (int.tryParse(id.toString()) ?? 0),
          username: username is String ? username : (username?.toString() ?? ''),
          email: email is String ? email : (email?.toString() ?? ''),
          firstName: firstName is String ? firstName : (firstName?.toString()),
          lastName: lastName is String ? lastName : (lastName?.toString()),
          profileImageId: profileImageId is int ? profileImageId : (int.tryParse(profileImageId?.toString() ?? '') ?? 0),
        );
      }).toList();
    });
    if (result != null) {
      _contacts = result;
      notifyListeners();
    }
  }

  // Load conversation (paged)
  Future<void> loadMessages(int contactId, {bool refresh = false}) async {
    if (refresh) {
      _conversations.remove(contactId);
      _page[contactId] = 0;
      _hasMore[contactId] = true;
    }

    if (!(_hasMore[contactId] ?? true)) return;

    final page = _page[contactId] ?? 0;
    final endpoint = '/Messages/$contactId/Messages';
    final params = {'page': page, 'pageSize': _pageSize};
    // ignore: avoid_print
    print('BackendChatProvider: GET messages -> ' 
      '${api.baseUrl.endsWith('/') ? api.baseUrl.substring(0, api.baseUrl.length - 1) : api.baseUrl}'
      '$endpoint${api.buildQueryString(params)}');

    final result = await executeWithState<PagedListLike<core.Message>>(() async {
      // Controller returns { items: [...] } with PascalCase fields
      final paged = await api.getPagedAndDecode(
        '$endpoint${api.buildQueryString(params)}',
        (json) {
          // Map backend MessageResponse to mobile Message
          // Handle both camelCase and PascalCase field names
          final id = json['messageId'] ?? json['MessageId'] ?? json['id'] ?? json['Id'] ?? 0;
          final senderId = json['senderId'] ?? json['SenderId'] ?? 0;
          final receiverId = json['receiverId'] ?? json['ReceiverId'] ?? 0;
          final messageText = json['messageText'] ?? json['MessageText'] ?? '';
          final isRead = json['isRead'] ?? json['IsRead'] ?? false;
          
          // Handle date parsing for both string and numeric timestamps
          DateTime? dateSent;
          final createdAt = json['createdAt'] ?? json['CreatedAt'];
          if (createdAt != null) {
            if (createdAt is String) {
              dateSent = DateTime.tryParse(createdAt);
            } else if (createdAt is int) {
              // Handle both milliseconds and seconds since epoch
              if (createdAt > 10000000000) {
                // Milliseconds
                dateSent = DateTime.fromMillisecondsSinceEpoch(createdAt);
              } else {
                // Seconds
                dateSent = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
              }
            }
          }

          return core.Message(
            messageId: id is int ? id : (int.tryParse(id.toString()) ?? 0),
            senderId: senderId is int ? senderId : (int.tryParse(senderId.toString()) ?? 0),
            receiverId: receiverId is int ? receiverId : (int.tryParse(receiverId.toString()) ?? 0),
            messageText: messageText is String ? messageText : messageText.toString(),
            dateSent: dateSent,
            isRead: isRead is bool ? isRead : (isRead?.toString().toLowerCase() == 'true'),
          );    
        },
        authenticated: true,
      );
      return PagedListLike(items: paged.items);
    });

    if (result != null) {
      final items = result.items;
      if (page == 0) {
        _conversations[contactId] = items;
      } else {
        _conversations[contactId]?.insertAll(0, items); // older first
      }
      // Sort messages by dateSent to ensure correct order
      _conversations[contactId]?.sort((a, b) => (a.dateSent ?? DateTime.now()).compareTo(b.dateSent ?? DateTime.now()));
      _hasMore[contactId] = items.length == _pageSize;
      _page[contactId] = page + 1;
      notifyListeners();
    }
  }

  // Send message via REST
  Future<bool> sendMessage(int receiverId, String text) async {
    final result = await executeWithState<core.Message>(() async {
      const ep = '/Messages/SendMessage';
      // ignore: avoid_print
      print('BackendChatProvider: POST send -> ' 
        '${api.baseUrl.endsWith('/') ? api.baseUrl.substring(0, api.baseUrl.length - 1) : api.baseUrl}$ep');
      final resp = await api.postJson(
        ep,
        {'receiverId': receiverId, 'messageText': text},
        authenticated: true,
      );
      // Map response supporting both camelCase and PascalCase
      final id = resp['messageId'] ?? resp['MessageId'] ?? resp['id'] ?? resp['Id'] ?? 0;
      final senderId = resp['senderId'] ?? resp['SenderId'] ?? 0;
      final respReceiverId = resp['receiverId'] ?? resp['ReceiverId'] ?? 0;
      final messageText = resp['messageText'] ?? resp['MessageText'] ?? '';
      final isRead = resp['isRead'] ?? resp['IsRead'] ?? false;
      
      // Handle date parsing for both string and numeric timestamps
      DateTime? dateSent;
      final createdAt = resp['createdAt'] ?? resp['CreatedAt'];
      if (createdAt != null) {
        if (createdAt is String) {
          dateSent = DateTime.tryParse(createdAt);
        } else if (createdAt is int) {
          // Handle both milliseconds and seconds since epoch
          if (createdAt > 10000000000) {
            // Milliseconds
            dateSent = DateTime.fromMillisecondsSinceEpoch(createdAt);
          } else {
            // Seconds
            dateSent = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
          }
        }
      } else {
        dateSent = DateTime.now();
      }

      return core.Message(
        messageId: id is int ? id : (int.tryParse(id.toString()) ?? 0),
        senderId: senderId is int ? senderId : (int.tryParse(senderId.toString()) ?? 0),
        receiverId: respReceiverId is int ? respReceiverId : (int.tryParse(respReceiverId.toString()) ?? 0),
        messageText: messageText is String ? messageText : messageText.toString(),
        dateSent: dateSent,
        isRead: isRead is bool ? isRead : (isRead?.toString().toLowerCase() == 'true'),
      );
    });

    if (result != null) {
      (_conversations[receiverId] ??= []).add(result);
      // Sort messages by dateSent to ensure correct order
      _conversations[receiverId]?.sort((a, b) => (a.dateSent ?? DateTime.now()).compareTo(b.dateSent ?? DateTime.now()));
      notifyListeners();
      return true;
    }
    return false;
  }

  // Presence setter (to be driven by SignalR later)
  void setUserOnline(int userId, bool online) {
    _online[userId] = online;
    notifyListeners();
  }

  // ─── Real-time (SignalR) ────────────────────────────────────────────────
  Future<void> connectRealtime() async {
    // Prevent multiple simultaneous connection attempts
    if (_hub != null && (_isRealtimeConnected || _hub!.state == HubConnectionState.connecting)) return;
    
    // Build hub URL at root (strip trailing /api if present)
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
    // Debug: log hub URL for diagnostics
    // ignore: avoid_print
    print('BackendChatProvider: Connecting to SignalR hub at: $hubUrl');

    final token = await api.secureStorageService.getToken();
    
    // Check if we have a valid token before attempting connection
    if (token == null || token.isEmpty) {
      print('BackendChatProvider: Cannot connect to SignalR - no auth token available');
      return;
    }

    // Create new hub connection with better error handling
    _hub = HubConnectionBuilder()
        .withUrl(
          hubUrl,
          HttpConnectionOptions(
            accessTokenFactory: () async => token,
            transport: HttpTransportType.webSockets, // Force WebSocket transport
            logging: (level, message) => print('SignalR Log [$level]: $message'),
          ),
        )
        .withAutomaticReconnect([
          0,      // First retry immediately
          2000,   // Second retry after 2 seconds
          10000,  // Third retry after 10 seconds
          30000,  // Subsequent retries after 30 seconds
        ])
        .build();

    // Set connection properties
    try {
      // These properties are available on signalr_core HubConnection
      _hub!.keepAliveIntervalInMilliseconds = 15000; // 15s
      _hub!.serverTimeoutInMilliseconds = 60000; // 60s (increased from 45s)
    } catch (_) {
      // no-op if not supported by library version
    }

    _registerHubHandlers();

    try {
      await _hub!.start();
      _isRealtimeConnected = _hub!.state == HubConnectionState.connected;
      // ignore: avoid_print
      print('BackendChatProvider: SignalR connected: $_isRealtimeConnected');
    } catch (e) {
      _isRealtimeConnected = false;
      // ignore: avoid_print
      print('BackendChatProvider: SignalR connection failed: $e');
      
      // Log additional details for debugging
      print('BackendChatProvider: Token available: ${token != null}');
      if (token != null) {
        print('BackendChatProvider: Token length: ${token.length}');
      }
    } finally {
      notifyListeners();
    }
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

    // Incoming chat message
    hub.on('ReceiveMessage', (args) {
      // Expected payloads:
      // - From ChatHub: { senderId, receiverId, messageText, dateSent, isRead }
      // - From MessagingService: { senderId, receiverId, messageText, CreatedAt, IsRead }
      if (args == null || args.isEmpty) return;
      final data = args.first;
      if (data is Map) {
        // Handle both camelCase and PascalCase field names
        final senderId = (data['senderId'] ?? data['SenderId']) as num?;
        final receiverId = (data['receiverId'] ?? data['ReceiverId']) as num?;
        final messageText = (data['messageText'] ?? data['MessageText']) as String?;
        
        // Handle date parsing for both string and numeric timestamps
        DateTime? dateSent;
        final createdAt = data['dateSent'] ?? data['DateSent'] ?? data['CreatedAt'] ?? data['createdAt'];
        if (createdAt != null) {
          if (createdAt is String) {
            dateSent = DateTime.tryParse(createdAt);
          } else if (createdAt is int) {
            // Handle both milliseconds and seconds since epoch
            if (createdAt > 10000000000) {
              // Milliseconds
              dateSent = DateTime.fromMillisecondsSinceEpoch(createdAt);
            } else {
              // Seconds
              dateSent = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
            }
          } else {
            dateSent = DateTime.now();
          }
        } else {
          dateSent = DateTime.now();
        }
        
        final isRead = (data['isRead'] ?? data['IsRead']) as bool? ?? false;
        
        if (senderId != null && receiverId != null && messageText != null) {
          final msg = core.Message(
            messageId: 0,
            senderId: senderId.toInt(),
            receiverId: receiverId.toInt(),
            messageText: messageText,
            dateSent: dateSent,
            isRead: isRead,
          );
          (_conversations[senderId.toInt()] ??= []).add(msg);
          // Sort messages by dateSent to ensure correct order
          _conversations[senderId.toInt()]?.sort((a, b) => (a.dateSent ?? DateTime.now()).compareTo(b.dateSent ?? DateTime.now()));
          notifyListeners();
        }
      }
    });

    // Confirmation back to sender when message is sent via hub
    hub.on('MessageSent', (args) {
      if (args == null || args.isEmpty) return;
      final data = args.first;
      if (data is Map) {
        // Handle both camelCase and PascalCase field names
        final senderId = (data['senderId'] ?? data['SenderId']) as num?;
        final receiverId = (data['receiverId'] ?? data['ReceiverId']) as num?;
        final messageText = (data['messageText'] ?? data['MessageText']) as String?;
        
        // Handle date parsing for both string and numeric timestamps
        DateTime? dateSent;
        final createdAt = data['dateSent'] ?? data['DateSent'] ?? data['CreatedAt'] ?? data['createdAt'];
        if (createdAt != null) {
          if (createdAt is String) {
            dateSent = DateTime.tryParse(createdAt);
          } else if (createdAt is int) {
            // Handle both milliseconds and seconds since epoch
            if (createdAt > 10000000000) {
              // Milliseconds
              dateSent = DateTime.fromMillisecondsSinceEpoch(createdAt);
            } else {
              // Seconds
              dateSent = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
            }
          } else {
            dateSent = DateTime.now();
          }
        } else {
          dateSent = DateTime.now();
        }
        
        if (senderId != null && receiverId != null && messageText != null) {
          final msg = core.Message(
            messageId: 0,
            senderId: senderId.toInt(),
            receiverId: receiverId.toInt(),
            messageText: messageText,
            dateSent: dateSent,
            isRead: false,
          );
          (_conversations[receiverId.toInt()] ??= []).add(msg);
          // Sort messages by dateSent to ensure correct order
          _conversations[receiverId.toInt()]?.sort((a, b) => (a.dateSent ?? DateTime.now()).compareTo(b.dateSent ?? DateTime.now()));
          notifyListeners();
        }
      }
    });

    // Presence updates
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

  /// Send a message using SignalR hub (real-time broadcast)
  Future<bool> sendMessageRealtime(int receiverId, String text) async {
    final hub = _hub;
    try {
      // Check connection state more efficiently
      if (hub == null || hub.state != HubConnectionState.connected) {
        // Try to connect without waiting if already connecting
        if (hub == null || hub.state != HubConnectionState.connecting) {
          await connectRealtime();
        }
        // Don't wait indefinitely for connection, proceed with REST if still not connected
        if (hub?.state != HubConnectionState.connected) {
          return await sendMessage(receiverId, text);
        }
      }
      
      // Send via SignalR with timeout
      await _hub!.invoke('SendMessageToUser', args: [receiverId, text])
          .timeout(const Duration(seconds: 5));
      
      // The hub will echo back 'MessageSent' which we handle to update local state
      return true;
    } catch (e) {
      // Fallback to REST if hub fails
      return await sendMessage(receiverId, text);
    }
  }

  @override
  void dispose() {
    // ensure hub is stopped
    final hub = _hub;
    if (hub != null) {
      hub.stop();
      _hub = null;
    }
    super.dispose();
  }
}

/// Minimal adapter for ApiService paged results used above
class PagedListLike<T> {
  final List<T> items;
  PagedListLike({required this.items});
}
