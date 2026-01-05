import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:e_rents_desktop/base/base_provider.dart';

/// Notification model for desktop app
class AppNotification {
  final int notificationId;
  final String? title;
  final String? message;
  final String? type;
  final int userId;
  final String? userName;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? actionUrl;
  final String? icon;
  final String? priority;

  AppNotification({
    required this.notificationId,
    this.title,
    this.message,
    this.type,
    required this.userId,
    this.userName,
    required this.isRead,
    required this.createdAt,
    this.readAt,
    this.actionUrl,
    this.icon,
    this.priority,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      notificationId: json['notificationId'] ?? json['id'] ?? 0,
      title: json['title'] as String?,
      message: json['message'] as String?,
      type: json['type'] as String?,
      userId: json['userId'] ?? 0,
      userName: json['userName'] as String?,
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      readAt: json['readAt'] != null 
          ? DateTime.parse(json['readAt']) 
          : null,
      actionUrl: json['actionUrl'] as String?,
      icon: json['icon'] as String?,
      priority: json['priority'] as String?,
    );
  }

  AppNotification copyWith({
    int? notificationId,
    String? title,
    String? message,
    String? type,
    int? userId,
    String? userName,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
    String? actionUrl,
    String? icon,
    String? priority,
  }) {
    return AppNotification(
      notificationId: notificationId ?? this.notificationId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      actionUrl: actionUrl ?? this.actionUrl,
      icon: icon ?? this.icon,
      priority: priority ?? this.priority,
    );
  }
}

/// Provider for managing notifications in desktop app
/// 
/// Features:
/// - Load user notifications (paginated)
/// - Get unread count for badge display
/// - Mark notifications as read (single or all)
/// - Delete notifications
class NotificationProvider extends BaseProvider {
  NotificationProvider(super.api);

  // ─── State ─────────────────────────────────────────────────────────────────
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _hasMore = true;
  int _currentSkip = 0;
  static const int _pageSize = 20;

  // ─── Getters ───────────────────────────────────────────────────────────────
  
  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get hasMore => _hasMore;
  bool get isEmpty => _notifications.isEmpty;
  
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
    notifyListeners();
  }

  // ─── Private Methods ───────────────────────────────────────────────────────

  Future<void> _loadMoreNotifications() async {
    final newNotifications = await executeWithState<List<AppNotification>?>(() async {
      debugPrint('NotificationProvider: Loading notifications (skip=$_currentSkip, take=$_pageSize)');
      
      final response = await api.get(
        '/notifications/my?skip=$_currentSkip&take=$_pageSize',
        authenticated: true,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => AppNotification.fromJson(json)).toList();
      }
      return null;
    });

    if (newNotifications != null) {
      _notifications.addAll(newNotifications);
      _currentSkip += newNotifications.length;
      _hasMore = newNotifications.length >= _pageSize;
      
      _unreadCount = _notifications.where((n) => !n.isRead).length;
      
      debugPrint('NotificationProvider: Loaded ${newNotifications.length} notifications, total=${_notifications.length}');
      notifyListeners();
    }
  }
}
