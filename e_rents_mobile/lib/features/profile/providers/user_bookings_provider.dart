import 'dart:convert';
import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/base/booking_actions_mixin.dart';
import 'package:e_rents_mobile/core/models/booking_model.dart';
import 'package:e_rents_mobile/core/enums/booking_enums.dart';
import 'package:e_rents_mobile/core/providers/current_user_provider.dart';
import 'package:flutter/foundation.dart';

/// Provider for managing user bookings
/// Handles loading booking history, current bookings, and booking cancellation
/// Uses BookingActionsMixin for shared booking operations.
class UserBookingsProvider extends BaseProvider with BookingActionsMixin {
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

  /// Load user bookings using CurrentUserProvider
  /// 
  /// Uses CurrentUserProvider to avoid duplicate /profile API calls.
  Future<void> loadUserBookings({bool forceRefresh = false, CurrentUserProvider? currentUserProvider}) async {
    // If not forcing refresh and we already have data, skip
    if (!forceRefresh && _bookingHistory != null) {
      debugPrint('UserBookingsProvider: Using existing booking data');
      return;
    }

    final bookings = await executeWithState(() async {
      debugPrint('UserBookingsProvider: Loading booking history');

      // Get userId from CurrentUserProvider if available, otherwise fetch directly
      int? userId;
      if (currentUserProvider != null) {
        final user = await currentUserProvider.ensureLoaded();
        userId = user?.userId;
      } else {
        // Fallback to direct API call if no provider passed
        final meResp = await api.get('/profile', authenticated: true);
        if (meResp.statusCode == 200) {
          final meJson = jsonDecode(meResp.body) as Map<String, dynamic>;
          userId = meJson['userId'] is int
              ? meJson['userId']
              : int.tryParse(meJson['userId']?.toString() ?? '');
        }
      }
      
      if (userId == null || userId <= 0) {
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
  /// 
  /// Uses shared [BookingActionsMixin.cancelBookingById] and refreshes booking history.
  /// Optionally include a cancellationDate for monthly in-stay cancellations.
  Future<bool> cancelBooking(String bookingId, {DateTime? cancellationDate, CurrentUserProvider? currentUserProvider}) async {
    debugPrint('UserBookingsProvider: Cancelling booking $bookingId');
    
    final id = int.tryParse(bookingId);
    if (id == null) {
      debugPrint('UserBookingsProvider: Invalid booking ID');
      return false;
    }
    
    final success = await cancelBookingById(id, cancellationDate: cancellationDate);
    
    if (success) {
      // Refresh booking history after successful cancellation
      await loadUserBookings(forceRefresh: true, currentUserProvider: currentUserProvider);
      debugPrint('UserBookingsProvider: Booking cancelled successfully');
    }
    
    return success;
  }
}
