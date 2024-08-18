import 'dart:async';
import 'dart:convert';
import 'package:e_rents_mobile/providers/base_provider.dart';
import 'package:e_rents_mobile/models/booking_notification_message.dart';
import 'package:e_rents_mobile/models/review_notification_message.dart';
import 'package:e_rents_mobile/models/user_message.dart';

class NotificationProvider extends BaseProvider {
  NotificationProvider() : super("notifications");

  Future<List<BookingNotificationMessage>> getBookingNotifications({int? page, int? pageSize, bool onlyUnread = false}) async {
    var url = Uri.parse("$baseUrl$endpoint/bookings?page=$page&pageSize=$pageSize");
    if (onlyUnread) {
      url = Uri.parse("$baseUrl$endpoint/bookings?unread=true&page=$page&pageSize=$pageSize");
    }

    try {
      var response = await http!.get(url, headers: await createHeaders());
      return (jsonDecode(response.body) as List)
          .map((x) => BookingNotificationMessage.fromJson(x))
          .toList();
    } catch (e) {
      handleException(e, 'getBookingNotifications');
      rethrow;
    }
  }

  Future<List<ReviewNotificationMessage>> getReviewNotifications({int? page, int? pageSize, bool onlyUnread = false}) async {
    var url = Uri.parse("$baseUrl$endpoint/reviews?page=$page&pageSize=$pageSize");
    if (onlyUnread) {
      url = Uri.parse("$baseUrl$endpoint/reviews?unread=true&page=$page&pageSize=$pageSize");
    }

    try {
      var response = await http!.get(url, headers: await createHeaders());
      return (jsonDecode(response.body) as List)
          .map((x) => ReviewNotificationMessage.fromJson(x))
          .toList();
    } catch (e) {
      handleException(e, 'getReviewNotifications');
      rethrow;
    }
  }

  Future<List<UserMessage>> getUserMessages({int? page, int? pageSize, bool onlyUnread = false}) async {
    var url = Uri.parse("$baseUrl$endpoint/messages?page=$page&pageSize=$pageSize");
    if (onlyUnread) {
      url = Uri.parse("$baseUrl$endpoint/messages?unread=true&page=$page&pageSize=$pageSize");
    }

    try {
      var response = await http!.get(url, headers: await createHeaders());
      return (jsonDecode(response.body) as List)
          .map((x) => UserMessage.fromJson(x))
          .toList();
    } catch (e) {
      handleException(e, 'getUserMessages');
      rethrow;
    }
  }

  Future<int> getUnreadNotificationCount() async {
    var url = Uri.parse("$baseUrl$endpoint/unreadCount");

    try {
      var response = await http!.get(url, headers: await createHeaders());
      var count = jsonDecode(response.body)['count'];
      return count;
    } catch (e) {
      handleException(e, 'getUnreadNotificationCount');
      rethrow;
    }
  }
  
 // Mark notifications as read
  Future<void> markNotificationAsRead(int notificationId) async {
    var url = Uri.parse("$baseUrl$endpoint/$notificationId/markAsRead");

    try {
      await http!.put(url, headers: await createHeaders());
    } catch (e) {
      handleException(e, 'markNotificationAsRead');
      rethrow;
    }
  }

  void startPollingNotifications({Duration interval = const Duration(seconds: 10)}) {
    Timer.periodic(interval, (timer) async {
      try {
        var newNotifications = await getBookingNotifications(onlyUnread: true);
        if (newNotifications.isNotEmpty) {
          notifyListeners();
        }
      } catch (e) {
        handleException(e, 'startPollingNotifications');
      }
    });
  }
}
