/// Notification model matching backend NotificationResponse DTO
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

  /// Create a copy with updated fields
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
