import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:signalr_core/signalr_core.dart';
import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/base/api_service_extensions.dart';
import 'package:e_rents_mobile/core/models/notification.dart';

/// Provider for managing user notifications
/// 
/// Features:
/// - Load user notifications (paginated)
/// - Load unread notifications
/// - Get unread count for badge display
/// - Mark notifications as read (single or all)
/// - Delete notifications
/// - Optimistic UI updates
class NotificationProvider extends BaseProvider {
  NotificationProvider(super.api);

  // ─── State ─────────────────────────────────────────────────────────────────
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _hasMore = true;
  int _currentSkip = 0;
  static const int _pageSize = 20;

  // ─── SignalR ───────────────────────────────────────────────────────────────
  HubConnection? _hub;
  bool _isRealtimeConnected = false;
  bool get isRealtimeConnected => _isRealtimeConnected;

  // ─── Getters ───────────────────────────────────────────────────────────────
  
  /// All loaded notifications
  List<AppNotification> get notifications => _notifications;
  
  /// Unread notification count (for badge)
  int get unreadCount => _unreadCount;
  
  /// Whether there are more notifications to load
  bool get hasMore => _hasMore;
  
  /// Whether the list is empty
  @override
  bool get isEmpty => _notifications.isEmpty;
  
  /// Unread notifications only
  List<AppNotification> get unreadNotifications => 
      _notifications.where((n) => !n.isRead).toList();

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Load initial notifications (resets pagination)
  Future<void> loadNotifications() async {
    _currentSkip = 0;
    _notifications = [];
    _hasMore = true;
    
    await _loadMoreNotifications();
  }

  /// Load more notifications (pagination)
  Future<void> loadMore() async {
    if (!_hasMore || isLoading) return;
    await _loadMoreNotifications();
  }

  /// Refresh notifications and unread count
  Future<void> refresh() async {
    await Future.wait([
      loadNotifications(),
      loadUnreadCount(),
    ]);
  }

  /// Load only the unread count (for badge display)
  Future<void> loadUnreadCount() async {
    final result = await executeWithState<int?>(() async {
      debugPrint('NotificationProvider: Loading unread count');
      final response = await api.get('/notifications/my/count', authenticated: true);
      
      if (response.statusCode == 200) {
        // Parse JSON response { "unreadCount": N }
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json['unreadCount'] as int? ?? 0;
      }
      return null;
    });

    if (result != null) {
      _unreadCount = result;
      notifyListeners();
    }
  }

  /// Mark a single notification as read
  Future<bool> markAsRead(int notificationId) async {
    final success = await executeWithStateForSuccess(() async {
      debugPrint('NotificationProvider: Marking notification $notificationId as read');
      await api.put('/notifications/$notificationId/read', {}, authenticated: true);
    });

    if (success) {
      // Optimistic update
      final index = _notifications.indexWhere((n) => n.notificationId == notificationId);
      if (index != -1 && !_notifications[index].isRead) {
        _notifications[index] = _notifications[index].copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
        _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
        notifyListeners();
      }
    }

    return success;
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead() async {
    final success = await executeWithStateForSuccess(() async {
      debugPrint('NotificationProvider: Marking all notifications as read');
      await api.put('/notifications/my/read-all', {}, authenticated: true);
    });

    if (success) {
      // Optimistic update
      _notifications = _notifications.map((n) => n.copyWith(
        isRead: true,
        readAt: n.readAt ?? DateTime.now(),
      )).toList();
      _unreadCount = 0;
      notifyListeners();
    }

    return success;
  }

  /// Delete a notification
  Future<bool> deleteNotification(int notificationId) async {
    final success = await executeWithStateForSuccess(() async {
      debugPrint('NotificationProvider: Deleting notification $notificationId');
      await api.delete('/notifications/$notificationId', authenticated: true);
    });

    if (success) {
      // Optimistic update
      final notification = _notifications.firstWhere(
        (n) => n.notificationId == notificationId,
        orElse: () => _notifications.first,
      );
      _notifications.removeWhere((n) => n.notificationId == notificationId);
      if (!notification.isRead) {
        _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
      }
      notifyListeners();
    }

    return success;
  }

  /// Clear all notifications (local state only)
  void clearOnLogout() {
    _notifications = [];
    _unreadCount = 0;
    _hasMore = true;
    _currentSkip = 0;
    disconnectRealtime();
    notifyListeners();
  }

  // ─── SignalR Real-time ─────────────────────────────────────────────────────

  /// Connect to SignalR hub for real-time notifications
  Future<void> connectRealtime() async {
    if (_hub != null && _isRealtimeConnected) return;

    String buildHubUrl() {
      final uri = Uri.parse(api.baseUrl);
      var path = uri.path;
      if (path.endsWith('/')) path = path.substring(0, path.length - 1);
      if (path.endsWith('/api')) path = path.substring(0, path.length - 4);
      final cleanPath = path.isEmpty ? '/' : path;
      final hub = uri.replace(path: '${cleanPath == '/' ? '' : cleanPath}/chatHub');
      return hub.toString();
    }

    try {
      final token = await api.secureStorageService.getToken();
      if (token == null) {
        debugPrint('NotificationProvider: No token available for SignalR connection');
        return;
      }

      _hub = HubConnectionBuilder()
          .withUrl(
            buildHubUrl(),
            HttpConnectionOptions(
              accessTokenFactory: () async => token,
              transport: HttpTransportType.webSockets,
            ),
          )
          .withAutomaticReconnect()
          .build();

      _hub!.onclose((error) {
        debugPrint('NotificationProvider: SignalR connection closed: $error');
        _isRealtimeConnected = false;
        notifyListeners();
      });

      _hub!.onreconnecting((error) {
        debugPrint('NotificationProvider: SignalR reconnecting: $error');
        _isRealtimeConnected = false;
        notifyListeners();
      });

      _hub!.onreconnected((connectionId) {
        debugPrint('NotificationProvider: SignalR reconnected: $connectionId');
        _isRealtimeConnected = true;
        notifyListeners();
      });

      await _hub!.start();
      _isRealtimeConnected = true;
      debugPrint('NotificationProvider: SignalR connected');

      _setupNotificationListener();
      notifyListeners();
    } catch (e) {
      debugPrint('NotificationProvider: SignalR connection error: $e');
      _isRealtimeConnected = false;
    }
  }

  /// Disconnect from SignalR hub
  Future<void> disconnectRealtime() async {
    if (_hub != null) {
      try {
        await _hub!.stop();
      } catch (e) {
        debugPrint('NotificationProvider: Error disconnecting SignalR: $e');
      }
      _hub = null;
      _isRealtimeConnected = false;
    }
  }

  /// Setup listener for real-time notifications
  void _setupNotificationListener() {
    final hub = _hub;
    if (hub == null) return;

    hub.on('ReceiveNotification', (args) {
      if (args == null || args.isEmpty) return;
      final data = args.first;
      if (data is Map) {
        debugPrint('NotificationProvider: Received real-time notification: $data');
        
        final notification = AppNotification(
          notificationId: data['notificationId'] ?? 0,
          title: data['title']?.toString(),
          message: data['message']?.toString(),
          type: data['type']?.toString(),
          userId: data['userId'] ?? 0,
          isRead: data['isRead'] ?? false,
          createdAt: data['createdAt'] != null 
              ? DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now()
              : DateTime.now(),
        );

        _notifications.insert(0, notification);
        _unreadCount++;
        notifyListeners();
      }
    });
  }

  // ─── Private Methods ───────────────────────────────────────────────────────

  Future<void> _loadMoreNotifications() async {
    final newNotifications = await executeWithState<List<AppNotification>?>(() async {
      debugPrint('NotificationProvider: Loading notifications (skip=$_currentSkip, take=$_pageSize)');
      
      return await api.getListAndDecode(
        '/notifications/my?skip=$_currentSkip&take=$_pageSize',
        AppNotification.fromJson,
        authenticated: true,
      );
    });

    if (newNotifications != null) {
      _notifications.addAll(newNotifications);
      _currentSkip += newNotifications.length;
      _hasMore = newNotifications.length >= _pageSize;
      
      // Update unread count based on loaded notifications
      _unreadCount = _notifications.where((n) => !n.isRead).length;
      
      debugPrint('NotificationProvider: Loaded ${newNotifications.length} notifications, total=${_notifications.length}');
      notifyListeners();
    }
  }
}
