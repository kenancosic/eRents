import '../../../base/base.dart';
import '../../../repositories/booking_repository.dart';
import '../../../models/booking.dart';

/// Detail provider for managing single booking operations
class BookingDetailProvider extends DetailProvider<Booking> {
  BookingDetailProvider(BookingRepository repository) : super(repository);

  /// Get typed repository reference
  BookingRepository get bookingRepository => repository as BookingRepository;

  // Booking-specific operations

  /// Cancel the current booking
  Future<void> cancelCurrentBooking({
    String? cancellationReason,
    bool requestRefund = false,
    String? refundMethod,
  }) async {
    if (currentId == null) {
      throw AppError(
        type: ErrorType.validation,
        message: 'Cannot cancel booking: no booking ID set',
      );
    }

    if (state.isLoading) return;

    try {
      final request = BookingCancellationRequest(
        bookingId: int.parse(currentId!),
        cancellationReason: cancellationReason,
        requestRefund: requestRefund,
        refundMethod: refundMethod,
      );

      final success = await bookingRepository.cancelBooking(request);

      if (success && item != null) {
        // Update the local booking status
        final updatedBooking = item!.copyWith(status: BookingStatus.cancelled);
        setItem(updatedBooking, currentId!);
      } else {
        throw Exception('Failed to cancel booking');
      }
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Calculate refund amount for the current booking
  Future<double> calculateRefundForCurrentBooking() async {
    if (currentId == null) return 0.0;

    try {
      return await bookingRepository.calculateRefundAmount(
        int.parse(currentId!),
      );
    } catch (e) {
      return 0.0; // Conservative approach
    }
  }

  /// Check if the current booking can be cancelled
  bool get canCancelCurrentBooking {
    if (item == null) return false;
    return item!.canBeCancelled;
  }

  /// Check if the current booking is currently active
  bool get isCurrentBookingActive {
    if (item == null) return false;
    return item!.isActive;
  }

  /// Get formatted date range for current booking
  String get currentBookingDateRange {
    if (item == null) return '';
    return item!.dateRange;
  }

  /// Get formatted price for current booking
  String get currentBookingFormattedPrice {
    if (item == null) return '';
    return item!.formattedPrice;
  }

  /// Get duration in days for current booking
  int? get currentBookingDurationInDays {
    if (item == null) return null;
    return item!.durationInDays;
  }

  /// Get status display name for current booking
  String get currentBookingStatusDisplay {
    if (item == null) return '';
    return item!.status.displayName;
  }

  /// Load booking by ID with enhanced error handling
  Future<void> loadBookingById(int bookingId) async {
    await loadItem(bookingId.toString());
  }

  /// Update booking details (only certain fields are updatable)
  Future<void> updateBookingDetails({
    DateTime? startDate,
    DateTime? endDate,
    int? numberOfGuests,
    String? specialRequests,
  }) async {
    if (currentId == null || item == null) {
      throw AppError(
        type: ErrorType.validation,
        message: 'Cannot update booking: no booking loaded',
      );
    }

    if (state.isLoading) return;

    try {
      final updatedBooking = item!.copyWith(
        startDate: startDate ?? item!.startDate,
        endDate: endDate ?? item!.endDate,
        numberOfGuests: numberOfGuests ?? item!.numberOfGuests,
        specialRequests: specialRequests ?? item!.specialRequests,
      );

      await updateItem(updatedBooking);
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Validate if booking dates are valid
  bool validateBookingDates(DateTime startDate, DateTime? endDate) {
    final now = DateTime.now();

    // Start date must be in the future (with some tolerance for today)
    if (startDate.isBefore(now.subtract(const Duration(hours: 1)))) {
      return false;
    }

    // If end date is provided, it must be after start date
    if (endDate != null && !endDate.isAfter(startDate)) {
      return false;
    }

    return true;
  }

  /// Calculate total price for a booking period
  double calculateTotalPrice({
    required DateTime startDate,
    DateTime? endDate,
    required double dailyRate,
  }) {
    if (endDate == null) {
      // For open-ended bookings, calculate for minimum 30 days
      return dailyRate * 30;
    }

    final days = endDate.difference(startDate).inDays;
    return dailyRate * days;
  }

  /// Get booking summary for current booking
  Map<String, dynamic>? get currentBookingSummary {
    if (item == null) return null;

    return {
      'id': item!.bookingId,
      'propertyName': item!.propertyName ?? 'Unknown Property',
      'status': item!.status.displayName,
      'dateRange': item!.dateRange,
      'totalPrice': item!.formattedPrice,
      'numberOfGuests': item!.numberOfGuests,
      'paymentMethod': item!.paymentMethod,
      'paymentStatus': item!.paymentStatus ?? 'Unknown',
      'canCancel': item!.canBeCancelled,
      'isActive': item!.isActive,
      'durationDays': item!.durationInDays,
    };
  }

  /// Check if booking belongs to specific property
  bool belongsToProperty(int propertyId) {
    if (item == null) return false;
    return item!.propertyId == propertyId;
  }

  /// Check if booking belongs to specific user
  bool belongsToUser(int userId) {
    if (item == null) return false;
    return item!.userId == userId;
  }

  /// Get time until booking starts (if upcoming)
  Duration? get timeUntilStart {
    if (item == null) return null;

    final now = DateTime.now();
    if (item!.startDate.isAfter(now)) {
      return item!.startDate.difference(now);
    }

    return null;
  }

  /// Get time until booking ends (if active)
  Duration? get timeUntilEnd {
    if (item == null || item!.endDate == null) return null;

    final now = DateTime.now();
    if (item!.endDate!.isAfter(now)) {
      return item!.endDate!.difference(now);
    }

    return null;
  }
}
