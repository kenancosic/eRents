import 'dart:convert';
import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/models/booking_model.dart';
import 'package:e_rents_mobile/core/enums/booking_enums.dart';
import 'package:flutter/foundation.dart';

/// Provider for managing user bookings
/// Handles loading booking history, current bookings, and booking cancellation
class UserBookingsProvider extends BaseProvider {
  UserBookingsProvider(super.api);

  // ─── State ──────────────────────────────────────────────────────────────
  List<dynamic>? _bookingHistory;
  List<dynamic>? get bookingHistory => _bookingHistory;

  // ─── Convenience Getters ───────────────────────────────────────────────

  /// Get upcoming bookings
  List<dynamic> get upcomingBookings {
    if (_bookingHistory == null) return [];
    return _bookingHistory!.where((booking) {
      try {
        final parsed = Booking.fromJson(booking as Map<String, dynamic>);
        return parsed.status == BookingStatus.upcoming || parsed.status == BookingStatus.active;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  /// Get past bookings
  List<dynamic> get pastBookings {
    if (_bookingHistory == null) return [];
    return _bookingHistory!.where((booking) {
      try {
        final parsed = Booking.fromJson(booking as Map<String, dynamic>);
        return parsed.status == BookingStatus.completed;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  /// Get cancelled bookings
  List<dynamic> get cancelledBookings {
    if (_bookingHistory == null) return [];
    return _bookingHistory!.where((booking) {
      try {
        final parsed = Booking.fromJson(booking as Map<String, dynamic>);
        return parsed.status == BookingStatus.cancelled;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  // ─── Public API ─────────────────────────────────────────────────────────

  /// Load user bookings
  Future<void> loadUserBookings({bool forceRefresh = false}) async {
    // If not forcing refresh and we already have data, skip
    if (!forceRefresh && _bookingHistory != null) {
      debugPrint('UserBookingsProvider: Using existing booking data');
      return;
    }

    final bookings = await executeWithState(() async {
      debugPrint('UserBookingsProvider: Loading booking history');

      // Fetch current user to get their userId
      final meResp = await api.get('/profile', authenticated: true);
      if (meResp.statusCode != 200) {
        throw Exception('Failed to resolve current user');
      }
      final meJson = jsonDecode(meResp.body) as Map<String, dynamic>;
      final int userId = meJson['userId'] is int
          ? meJson['userId']
          : int.tryParse(meJson['userId']?.toString() ?? '') ?? 0;
      if (userId <= 0) {
        throw Exception('Invalid current user id');
      }

      final response = await api.get('/bookings?userId=$userId&page=1&pageSize=50&sortBy=createdAt&sortDirection=desc', authenticated: true);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('UserBookingsProvider: Booking history loaded successfully');
        if (data is Map<String, dynamic> && data['items'] is List) {
          return data['items'] as List<dynamic>;
        } else if (data is List) {
          return data;
        } else if (data is Map<String, dynamic> && data['bookings'] is List) {
          // Fallback shape
          return data['bookings'] as List<dynamic>;
        }
        return <dynamic>[];
      } else {
        debugPrint('UserBookingsProvider: Failed to load booking history');
        throw Exception('Failed to load booking history: ${response.statusCode}');
      }
    });

    if (bookings != null) {
      _bookingHistory = bookings;
    }
  }

  /// Cancel a booking
  /// Optionally include a cancellationDate (yyyy-MM-dd) for monthly in-stay cancellations
  Future<bool> cancelBooking(String bookingId, {DateTime? cancellationDate}) async {
    final success = await executeWithStateForSuccess(() async {
      debugPrint('UserBookingsProvider: Cancelling booking $bookingId');

      final body = <String, dynamic>{};
      if (cancellationDate != null) {
        final y = cancellationDate.year.toString().padLeft(4, '0');
        final m = cancellationDate.month.toString().padLeft(2, '0');
        final d = cancellationDate.day.toString().padLeft(2, '0');
        body['cancellationDate'] = '$y-$m-$d';
      }

      final response = await api.post(
        '/bookings/$bookingId/cancel',
        body,
        authenticated: true,
      );

      if (response.statusCode == 200) {
        // Refresh booking history
        await loadUserBookings(forceRefresh: true);
        debugPrint('UserBookingsProvider: Booking cancelled successfully');
      } else {
        debugPrint('UserBookingsProvider: Failed to cancel booking');
        throw Exception('Failed to cancel booking');
      }
    }, errorMessage: 'Failed to cancel booking');

    return success;
  }
}
