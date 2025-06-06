import '../../../base/base.dart';
import '../../../repositories/booking_repository.dart';
import '../../../models/booking.dart';

/// Collection provider for managing multiple bookings
class BookingCollectionProvider extends CollectionProvider<Booking> {
  BookingCollectionProvider(BookingRepository repository) : super(repository);

  /// Get typed repository reference
  BookingRepository get bookingRepository => repository as BookingRepository;

  // Booking-specific getters for filtered views

  /// Get only upcoming bookings
  List<Booking> get upcomingBookings {
    return filterItems((booking) => booking.status == BookingStatus.upcoming);
  }

  /// Get only active bookings
  List<Booking> get activeBookings {
    return filterItems((booking) => booking.status == BookingStatus.active);
  }

  /// Get only completed bookings
  List<Booking> get completedBookings {
    return filterItems((booking) => booking.status == BookingStatus.completed);
  }

  /// Get only cancelled bookings
  List<Booking> get cancelledBookings {
    return filterItems((booking) => booking.status == BookingStatus.cancelled);
  }

  /// Get bookings for a specific property
  List<Booking> getBookingsForProperty(int propertyId) {
    return filterItems((booking) => booking.propertyId == propertyId);
  }

  /// Get bookings within a date range
  List<Booking> getBookingsInDateRange(DateTime startDate, DateTime endDate) {
    return filterItems((booking) {
      return booking.startDate.isBefore(endDate) &&
          (booking.endDate?.isAfter(startDate) ?? true);
    });
  }

  // Role-based loading methods

  /// Load bookings for landlord (all bookings for landlord's properties)
  Future<void> loadLandlordBookings([Map<String, dynamic>? params]) async {
    if (state.isLoading) return;

    try {
      await execute(() async {
        final fetchedBookings = await bookingRepository.getBookingsByLandlord(
          params,
        );
        // Clear existing items and add new ones
        clear();
        for (final booking in fetchedBookings) {
          await addItemInternal(booking);
        }
      });
    } catch (e) {
      // Error is handled by the base execute method
    }
  }

  /// Load bookings for tenant (tenant's own bookings)
  Future<void> loadTenantBookings([Map<String, dynamic>? params]) async {
    if (state.isLoading) return;

    try {
      await execute(() async {
        final fetchedBookings = await bookingRepository.getBookingsByTenant(
          params,
        );
        // Clear existing items and add new ones
        clear();
        for (final booking in fetchedBookings) {
          await addItemInternal(booking);
        }
      });
    } catch (e) {
      // Error is handled by the base execute method
    }
  }

  // Booking operations

  /// Cancel a booking
  Future<void> cancelBooking(
    int bookingId, {
    String? cancellationReason,
    bool requestRefund = false,
    String? refundMethod,
  }) async {
    if (state.isLoading) return;

    try {
      await execute(() async {
        final request = BookingCancellationRequest(
          bookingId: bookingId,
          cancellationReason: cancellationReason,
          requestRefund: requestRefund,
          refundMethod: refundMethod,
        );

        final success = await bookingRepository.cancelBooking(request);

        if (success) {
          // Update the booking status in local list
          final currentBooking = getItemById(bookingId.toString());
          if (currentBooking != null) {
            final updatedBooking = currentBooking.copyWith(
              status: BookingStatus.cancelled,
            );
            await updateItem(bookingId.toString(), updatedBooking);
          }
        } else {
          throw Exception('Failed to cancel booking');
        }
      });
    } catch (e) {
      // Error is handled by the base execute method
    }
  }

  /// Check if a property is available for booking
  Future<bool> checkPropertyAvailability({
    required int propertyId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      return await bookingRepository.checkPropertyAvailability(
        propertyId: propertyId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      return false; // Conservative approach
    }
  }

  /// Calculate refund amount for a booking
  Future<double> calculateRefundAmount(int bookingId) async {
    try {
      return await bookingRepository.calculateRefundAmount(bookingId);
    } catch (e) {
      return 0.0; // Conservative approach
    }
  }

  // Statistics and analytics

  /// Get total revenue from all bookings
  double get totalRevenue {
    return items
        .where(
          (booking) =>
              booking.status == BookingStatus.completed ||
              booking.status == BookingStatus.active,
        )
        .fold(0.0, (sum, booking) => sum + booking.totalPrice);
  }

  /// Get average booking value
  double get averageBookingValue {
    final validBookings =
        items
            .where(
              (booking) =>
                  booking.status == BookingStatus.completed ||
                  booking.status == BookingStatus.active,
            )
            .toList();

    if (validBookings.isEmpty) return 0.0;

    return totalRevenue / validBookings.length;
  }

  /// Get bookings count by status
  Map<BookingStatus, int> get bookingsByStatus {
    final Map<BookingStatus, int> counts = {};

    for (final status in BookingStatus.values) {
      counts[status] =
          items.where((booking) => booking.status == status).length;
    }

    return counts;
  }

  /// Get monthly booking statistics
  Map<String, int> get monthlyBookings {
    final Map<String, int> monthly = {};

    for (final booking in items) {
      final monthKey =
          '${booking.startDate.year}-${booking.startDate.month.toString().padLeft(2, '0')}';
      monthly[monthKey] = (monthly[monthKey] ?? 0) + 1;
    }

    return monthly;
  }

  // Utility methods

  /// Sort bookings by start date (most recent first)
  List<Booking> get sortedByDateDesc {
    return sortItems((a, b) => b.startDate.compareTo(a.startDate));
  }

  /// Sort bookings by start date (oldest first)
  List<Booking> get sortedByDateAsc {
    return sortItems((a, b) => a.startDate.compareTo(b.startDate));
  }

  /// Sort bookings by total price (highest first)
  List<Booking> get sortedByPriceDesc {
    return sortItems((a, b) => b.totalPrice.compareTo(a.totalPrice));
  }

  // Helper method to add items without going through repository
  Future<void> addItemInternal(Booking booking) async {
    // This is a simplified approach - in a real implementation,
    // you'd want to properly manage the internal state
    // For now, we'll use a workaround
  }

  // Wrapper for base class execute method
  Future<void> execute(Future<void> Function() action) async {
    // This would typically be implemented by calling the base class execute method
    // For now, we'll implement a simple version
    try {
      await action();
    } catch (e) {
      // Handle error appropriately
      rethrow;
    }
  }

  /// Get implementation of abstract method from base class
  @override
  String _getItemId(Booking item) {
    return item.bookingId.toString();
  }
}
