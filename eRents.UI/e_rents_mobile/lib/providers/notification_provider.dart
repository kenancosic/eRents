import 'package:flutter/foundation.dart';
import '../services/rabbitmq_service.dart';
import '../models/notification.dart';
import 'base_provider.dart';

class NotificationProvider extends BaseProvider {
  final RabbitMQService _rabbitMQService;
  List<Notification> _notifications = [];

  List<Notification> get notifications => _notifications;

  NotificationProvider({required RabbitMQService rabbitMQService})
      : _rabbitMQService = rabbitMQService {
    _rabbitMQService.subscribeToNotifications('notification_queue', _handleNotificationMessage);
  }

  void _handleNotificationMessage(Map<String, dynamic> message) {
    final notification = Notification.fromJson(message);
    _notifications.add(notification);
    notifyListeners();
  }

  void markAsRead(int notificationId) {
    _notifications.firstWhere((n) => n.id == notificationId).isRead = true;
    notifyListeners();
  }
}
