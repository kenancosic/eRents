import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/utils/date_extensions.dart';

/// Mixin providing shared booking actions to avoid duplication across providers.
/// 
/// This mixin consolidates common booking operations like cancellation
/// that are needed by multiple providers (UserBookingsProvider, PropertyRentalProvider).
/// 
/// Usage:
/// ```dart
/// class MyProvider extends BaseProvider with BookingActionsMixin {
///   // Now has access to cancelBookingById()
/// }
/// ```
mixin BookingActionsMixin on BaseProvider {
  
  /// Cancel a booking by ID
  /// 
  /// Optionally provide a [cancellationDate] for monthly in-stay cancellations.
  /// Returns true if cancellation succeeded.
  /// 
  /// This is the core implementation - providers can call this and add
  /// their own post-cancellation logic (e.g., refreshing lists, updating local state).
  Future<bool> cancelBookingById(
    int bookingId, {
    DateTime? cancellationDate,
    String? errorMessage,
  }) async {
    return await executeWithStateForSuccess(() async {
      final payload = <String, dynamic>{};
      if (cancellationDate != null) {
        payload['cancellationDate'] = cancellationDate.toApiDate();
      }
      
      await api.post(
        '/bookings/$bookingId/cancel',
        payload,
        authenticated: true,
      );
    }, errorMessage: errorMessage ?? 'Failed to cancel booking');
  }
}
