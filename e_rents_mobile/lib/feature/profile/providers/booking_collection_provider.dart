import 'package:flutter/foundation.dart';
import 'package:e_rents_mobile/core/base/collection_provider.dart';
import 'package:e_rents_mobile/core/repositories/booking_repository.dart';
import 'package:e_rents_mobile/core/models/booking_model.dart';

/// Concrete collection provider for Booking entities
/// Manages user bookings with automatic caching, search, and filtering
class BookingCollectionProvider extends CollectionProvider<Booking> {
  BookingCollectionProvider(BookingRepository super.repository);

  // Get the booking repository with proper typing
  BookingRepository get bookingRepository => repository as BookingRepository;

  // Convenience getters for different booking types
  List<Booking> get currentBookings {
    final now = DateTime.now();
    return items.where((booking) {
      return booking.status == BookingStatus.active &&
          booking.startDate.isBefore(now) &&
          (booking.endDate == null || booking.endDate!.isAfter(now));
    }).toList();
  }

  List<Booking> get upcomingBookings {
    final now = DateTime.now();
    return items.where((booking) {
      return booking.status == BookingStatus.upcoming &&
          booking.startDate.isAfter(now);
    }).toList();
  }

  List<Booking> get pastBookings {
    final now = DateTime.now();
    return items.where((booking) {
      return booking.endDate != null && booking.endDate!.isBefore(now);
    }).toList();
  }

  List<Booking> get pendingBookings {
    return items
        .where((booking) => booking.status == BookingStatus.upcoming)
        .toList();
  }

  List<Booking> get cancelledBookings {
    return items
        .where((booking) => booking.status == BookingStatus.cancelled)
        .toList();
  }

  @override
  bool matchesSearch(Booking item, String query) {
    final lowerQuery = query.toLowerCase();
    return item.propertyName.toLowerCase().contains(lowerQuery) ||
        item.status.name.toLowerCase().contains(lowerQuery) ||
        (item.specialRequests?.toLowerCase().contains(lowerQuery) ?? false) ||
        (item.paymentMethod?.toLowerCase().contains(lowerQuery) ?? false);
  }

  @override
  bool matchesFilters(Booking item, Map<String, dynamic> filters) {
    // Status filter
    if (filters.containsKey('status')) {
      final statusFilter = filters['status'] as String?;
      if (statusFilter != null && item.status.name != statusFilter) {
        return false;
      }
    }

    // Property filter
    if (filters.containsKey('propertyId')) {
      final propertyId = filters['propertyId'] as int?;
      if (propertyId != null && item.propertyId != propertyId) {
        return false;
      }
    }

    // Date range filters
    if (filters.containsKey('startDate')) {
      final startDate = filters['startDate'] as DateTime?;
      if (startDate != null && item.startDate.isBefore(startDate)) {
        return false;
      }
    }

    if (filters.containsKey('endDate')) {
      final endDate = filters['endDate'] as DateTime?;
      if (endDate != null &&
          (item.endDate == null || item.endDate!.isAfter(endDate))) {
        return false;
      }
    }

    // Price range filters
    if (filters.containsKey('minPrice')) {
      final minPrice = filters['minPrice'] as double?;
      if (minPrice != null && item.totalPrice < minPrice) {
        return false;
      }
    }

    if (filters.containsKey('maxPrice')) {
      final maxPrice = filters['maxPrice'] as double?;
      if (maxPrice != null && item.totalPrice > maxPrice) {
        return false;
      }
    }

    // Payment method filter
    if (filters.containsKey('paymentMethod')) {
      final paymentMethod = filters['paymentMethod'] as String?;
      if (paymentMethod != null && item.paymentMethod != paymentMethod) {
        return false;
      }
    }

    return true;
  }

  // Booking-specific convenience methods

  /// Load current user's bookings
  Future<void> loadUserBookings({bool forceRefresh = false}) async {
    await loadItems();
  }

  /// Create a new booking
  Future<void> createBooking({
    required int propertyId,
    required DateTime startDate,
    DateTime? endDate,
    required double totalPrice,
    required int numberOfGuests,
    String? specialRequests,
    String paymentMethod = 'PayPal',
  }) async {
    await execute(() async {
      debugPrint('BookingCollectionProvider: Creating new booking');

      final booking = await bookingRepository.createBooking(
        propertyId: propertyId,
        startDate: startDate,
        endDate: endDate,
        totalPrice: totalPrice,
        numberOfGuests: numberOfGuests,
        specialRequests: specialRequests,
        paymentMethod: paymentMethod,
      );

      // Add to local collection and refresh search/filters
      allItems.add(booking);
      searchItems(
          searchQuery); // This triggers _applySearchAndFilters internally

      debugPrint('BookingCollectionProvider: Booking created successfully');
    });
  }

  /// Cancel a booking
  Future<bool> cancelBooking(String bookingId) async {
    bool success = false;

    await execute(() async {
      debugPrint('BookingCollectionProvider: Cancelling booking $bookingId');

      success = await bookingRepository.cancelBooking(bookingId);

      if (success) {
        // Remove from local collection and refresh search/filters
        allItems.removeWhere(
            (booking) => booking.bookingId.toString() == bookingId);
        searchItems(
            searchQuery); // This triggers _applySearchAndFilters internally

        debugPrint('BookingCollectionProvider: Booking cancelled successfully');
      }
    });

    return success;
  }

  /// Filter bookings by status
  void filterByStatus(String status) {
    applyFilters({'status': status});
  }

  /// Filter bookings by property
  void filterByProperty(int propertyId) {
    applyFilters({'propertyId': propertyId});
  }

  /// Filter bookings by date range
  void filterByDateRange(DateTime? startDate, DateTime? endDate) {
    final filters = <String, dynamic>{};
    if (startDate != null) filters['startDate'] = startDate;
    if (endDate != null) filters['endDate'] = endDate;
    applyFilters(filters);
  }

  /// Filter bookings by price range
  void filterByPriceRange(double? minPrice, double? maxPrice) {
    final filters = <String, dynamic>{};
    if (minPrice != null) filters['minPrice'] = minPrice;
    if (maxPrice != null) filters['maxPrice'] = maxPrice;
    applyFilters(filters);
  }

  /// Get active bookings (active status)
  Future<void> loadActiveBookings() async {
    await loadUserBookings();
    filterByStatus('active');
  }

  /// Get upcoming bookings
  Future<void> loadUpcomingBookings() async {
    await loadUserBookings();
    final now = DateTime.now();
    filterByDateRange(now, null);
  }

  /// Get past bookings
  Future<void> loadPastBookings() async {
    await loadUserBookings();
    final now = DateTime.now();
    filterByDateRange(null, now);
  }

  /// Get pending bookings
  Future<void> loadPendingBookings() async {
    await loadUserBookings();
    filterByStatus('upcoming');
  }

  /// Sort bookings by date (newest first)
  void sortByDateDesc() {
    sortItems((a, b) => b.startDate.compareTo(a.startDate));
  }

  /// Sort bookings by date (oldest first)
  void sortByDateAsc() {
    sortItems((a, b) => a.startDate.compareTo(b.startDate));
  }

  /// Sort bookings by price (highest first)
  void sortByPriceDesc() {
    sortItems((a, b) => b.totalPrice.compareTo(a.totalPrice));
  }

  /// Sort bookings by price (lowest first)
  void sortByPriceAsc() {
    sortItems((a, b) => a.totalPrice.compareTo(b.totalPrice));
  }

  /// Sort bookings by property name
  void sortByPropertyName() {
    sortItems((a, b) => a.propertyName.compareTo(b.propertyName));
  }

  /// Get booking statistics
  Map<String, dynamic> getBookingStats() {
    if (allItems.isEmpty) {
      return {
        'total': 0,
        'confirmed': 0,
        'pending': 0,
        'cancelled': 0,
        'totalSpent': 0.0,
        'averagePrice': 0.0,
      };
    }

    final confirmed =
        allItems.where((b) => b.status == BookingStatus.active).length;
    final pending =
        allItems.where((b) => b.status == BookingStatus.upcoming).length;
    final cancelled =
        allItems.where((b) => b.status == BookingStatus.cancelled).length;
    final totalSpent =
        allItems.fold<double>(0.0, (sum, b) => sum + b.totalPrice);
    final averagePrice = totalSpent / allItems.length;

    return {
      'total': allItems.length,
      'confirmed': confirmed,
      'pending': pending,
      'cancelled': cancelled,
      'totalSpent': totalSpent,
      'averagePrice': averagePrice,
    };
  }

  @override
  void onItemsLoaded(List<Booking> items) {
    debugPrint('BookingCollectionProvider: Loaded ${items.length} bookings');

    // Auto-sort by newest first
    sortByDateDesc();
  }
}
