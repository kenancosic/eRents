import 'dart:convert';
import 'package:e_rents_mobile/core/base/base_provider.dart';
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
      final status = booking['status'] as String;
      return status == 'Confirmed' || status == 'Pending';
    }).toList();
  }

  /// Get past bookings
  List<dynamic> get pastBookings {
    if (_bookingHistory == null) return [];
    return _bookingHistory!.where((booking) {
      return booking['status'] == 'Completed';
    }).toList();
  }

  /// Get cancelled bookings
  List<dynamic> get cancelledBookings {
    if (_bookingHistory == null) return [];
    return _bookingHistory!.where((booking) {
      return booking['status'] == 'Cancelled';
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

      final response = await api.get('/users/current/bookings', authenticated: true);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('UserBookingsProvider: Booking history loaded successfully');
        return data['bookings'] as List<dynamic>;
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
  Future<bool> cancelBooking(String bookingId) async {
    final success = await executeWithStateForSuccess(() async {
      debugPrint('UserBookingsProvider: Cancelling booking $bookingId');

      final response = await api.post(
        '/bookings/$bookingId/cancel',
        {},
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
