import 'package:flutter/foundation.dart';
import 'api_service.dart';

/// Notification service for handling push notifications and in-app notifications
class NotificationService {
  final ApiService _apiService;

  NotificationService(this._apiService);

  /// Register device for push notifications
  Future<bool> registerDevice(String deviceToken) async {
    try {
      final response = await _apiService.post(
        '/notifications/register',
        {'deviceToken': deviceToken},
        authenticated: true,
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('NotificationService: Failed to register device: $e');
      return false;
    }
  }

  /// Get user notifications
  Future<List<Map<String, dynamic>>> getUserNotifications() async {
    try {
      final response = await _apiService.get(
        '/notifications/user',
        authenticated: true,
      );

      if (response.statusCode == 200) {
        // TODO: Parse response when backend is ready
        return [];
      } else {
        debugPrint(
            'NotificationService: Failed to load notifications: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('NotificationService: Error loading notifications: $e');
      return [];
    }
  }

  /// Mark notification as read
  Future<bool> markAsRead(int notificationId) async {
    try {
      final response = await _apiService.put(
        '/notifications/$notificationId/read',
        {},
        authenticated: true,
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint(
          'NotificationService: Failed to mark notification as read: $e');
      return false;
    }
  }

  /// Update notification preferences
  Future<bool> updatePreferences(Map<String, bool> preferences) async {
    try {
      final response = await _apiService.put(
        '/notifications/preferences',
        preferences,
        authenticated: true,
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('NotificationService: Failed to update preferences: $e');
      return false;
    }
  }
}
