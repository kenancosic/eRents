import '../base/base.dart';
import '../services/booking_service.dart';
import '../models/booking.dart';
import '../models/paged_result.dart';

/// Repository for booking data management with caching support
class BookingRepository extends BaseRepository<Booking, BookingService> {
  BookingRepository({required super.service, required super.cacheManager});

  @override
  String get resourceName => 'bookings';

  @override
  Duration get defaultCacheTtl => const Duration(minutes: 10); // Shorter TTL for booking data

  // Base repository methods implementation

  @override
  Future<List<Booking>> fetchAllFromService([
    Map<String, dynamic>? params,
  ]) async {
    return await service.getAllBookings(params);
  }

  @override
  Future<Booking> fetchByIdFromService(String id) async {
    return await service.getBookingById(id);
  }

  @override
  Future<Booking> createInService(Booking item) async {
    // Convert Booking to Map<String, dynamic>
    final request = {
      'propertyId': item.propertyId!,
      'startDate': item.startDate?.toIso8601String(),
      'endDate':
          (item.endDate ?? item.startDate?.add(const Duration(days: 1)))
              ?.toIso8601String(),
      'totalPrice': item.totalPrice,
      'paymentMethod': item.paymentMethod ?? 'PayPal',
      'currency': item.currency ?? 'BAM',
      'numberOfGuests': item.numberOfGuests ?? 1,
      'specialRequests': item.specialRequests,
    };

    return await service.createBooking(request);
  }

  @override
  Future<Booking> updateInService(String id, Booking item) async {
    // Convert Booking to Map<String, dynamic> (only updatable fields)
    final request = {
      'startDate': item.startDate?.toIso8601String(),
      'endDate': item.endDate?.toIso8601String(),
      'numberOfGuests': item.numberOfGuests,
      'specialRequests': item.specialRequests,
    };

    return await service.updateBooking(id, request);
  }

  @override
  Future<void> deleteInService(String id) async {
    final success = await service.deleteBooking(id);
    if (!success) {
      throw Exception('Failed to delete booking $id');
    }
  }

  @override
  Future<bool> existsInService(String id) async {
    try {
      await service.getBookingById(id);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<int> countInService([Map<String, dynamic>? params]) async {
    return await service.getBookingCount(params);
  }

  @override
  String? extractIdFromItem(Booking item) {
    return item.bookingId.toString();
  }

  @override
  Booking fromJson(Map<String, dynamic> json) => Booking.fromJson(json);

  @override
  Future<PagedResult<Booking>> fetchPagedFromService([
    Map<String, dynamic>? params,
  ]) async {
    final result = await service.getPagedBookings(params ?? {});
    return PagedResult.fromJson(result, (json) => Booking.fromJson(json));
  }

  // ✅ BOOKING-SPECIFIC METHODS

  /// Cancel a booking
  Future<void> cancelBooking(
    int bookingId,
    String reason,
    bool requestRefund, {
    String? additionalNotes,
    bool isEmergency = false,
    String? refundMethod,
  }) async {
    try {
      await service.cancelBooking(
        bookingId,
        reason,
        requestRefund,
        additionalNotes: additionalNotes,
        isEmergency: isEmergency,
        refundMethod: refundMethod,
      );

      if (enableCaching) {
        // Invalidate cache for the specific booking and lists
        final bookingCacheKey = _buildItemCacheKey(bookingId.toString());
        await cacheManager.remove(bookingCacheKey);
        await _invalidateListCaches();
      }
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }

  /// Check property availability
  Future<bool> checkPropertyAvailability({
    required int propertyId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final cacheKey =
          'availability_${propertyId}_${startDate.toIso8601String()}_${endDate.toIso8601String()}';

      // Try cache first (short TTL for availability checks)
      if (enableCaching) {
        final cached = await cacheManager.get<bool>(cacheKey);
        if (cached != null) {
          return cached;
        }
      }

      // Check availability via service
      final isAvailable = await service.checkPropertyAvailability(
        propertyId: propertyId,
        startDate: startDate,
        endDate: endDate,
      );

      // Cache with very short TTL (availability changes frequently)
      if (enableCaching) {
        await cacheManager.set(
          cacheKey,
          isAvailable,
          duration: const Duration(minutes: 2),
        );
      }

      return isAvailable;
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Calculate refund amount
  Future<double> calculateRefundAmount(
    int bookingId,
    DateTime cancellationDate,
  ) async {
    try {
      final response = await service.calculateRefundAmount(
        bookingId,
        cancellationDate,
      );
      return response;
    } catch (e) {
      throw Exception('Failed to calculate refund amount: $e');
    }
  }

  /// Check if user has active booking for property
  Future<bool> hasActiveBooking(int propertyId) async {
    try {
      final cacheKey = 'active_booking_${propertyId}';

      // Try cache first (very short TTL)
      if (enableCaching) {
        final cached = await cacheManager.get<bool>(cacheKey);
        if (cached != null) {
          return cached;
        }
      }

      final hasActive = await service.hasActiveBooking(propertyId);

      // Cache for very short time
      if (enableCaching) {
        await cacheManager.set(
          cacheKey,
          hasActive,
          duration: const Duration(minutes: 1),
        );
      }

      return hasActive;
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  // Helper methods

  /// Build cache key for special operations
  String _buildSpecialCacheKey(
    String operation, [
    Map<String, dynamic>? params,
  ]) {
    final buffer = StringBuffer();
    buffer.write('${resourceName}_$operation');

    if (params != null && params.isNotEmpty) {
      final sortedParams = Map.fromEntries(
        params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
      );

      for (final entry in sortedParams.entries) {
        buffer.write('_${entry.key}:${entry.value}');
      }
    }

    return buffer.toString();
  }

  /// Build cache key for individual items
  String _buildItemCacheKey(String id) {
    return '${resourceName}_item_$id';
  }

  /// Invalidate list-related cache entries
  Future<void> _invalidateListCaches() async {
    await cacheManager.clearByRegex(
      RegExp('^${resourceName}_(all|count|landlord|tenant)'),
    );
  }

  /// ✅ LANDLORD SPECIFIC: Get current stays for landlord's properties
  /// Matches: GET /bookings/current?propertyId=123
  Future<List<Booking>> getCurrentStaysForProperty(int? propertyId) async {
    try {
      final cacheKey = _buildSpecialCacheKey('current', {
        'propertyId': propertyId,
      });

      if (enableCaching) {
        final cached = await cacheManager.get<List<Booking>>(cacheKey);
        if (cached != null) {
          return cached;
        }
      }

      final bookings = await service.getCurrentStays(propertyId);

      if (enableCaching) {
        await cacheManager.set(
          cacheKey,
          bookings,
          duration: const Duration(minutes: 1),
        );
      }

      return bookings;
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// ✅ LANDLORD SPECIFIC: Get upcoming stays for landlord's properties
  /// Matches: GET /bookings/upcoming?propertyId=123
  Future<List<Booking>> getUpcomingStaysForProperty(int? propertyId) async {
    try {
      final cacheKey = _buildSpecialCacheKey('upcoming', {
        'propertyId': propertyId,
      });

      if (enableCaching) {
        final cached = await cacheManager.get<List<Booking>>(cacheKey);
        if (cached != null) {
          return cached;
        }
      }

      final bookings = await service.getUpcomingStays(propertyId);

      if (enableCaching) {
        await cacheManager.set(
          cacheKey,
          bookings,
          duration: const Duration(minutes: 1),
        );
      }

      return bookings;
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Convenience wrapper that aligns with RentalManagementService expectations.
  /// When [propertyId] is omitted it returns stays for ALL landlord properties.
  Future<List<Booking>> getCurrentStays([int? propertyId]) async {
    return await getCurrentStaysForProperty(propertyId);
  }

  /// Convenience wrapper that aligns with RentalManagementService expectations.
  /// When [propertyId] is omitted it returns upcoming stays for ALL landlord properties.
  Future<List<Booking>> getUpcomingStays([int? propertyId]) async {
    return await getUpcomingStaysForProperty(propertyId);
  }

  /// Build a cache key for this repository
  String _buildCacheKey(String operation, [Map<String, dynamic>? params]) {
    final buffer = StringBuffer();
    buffer.write('${resourceName}_$operation');

    if (params != null && params.isNotEmpty) {
      final sortedParams = Map.fromEntries(
        params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
      );

      for (final entry in sortedParams.entries) {
        buffer.write('_${entry.key}:${entry.value}');
      }
    }

    return buffer.toString();
  }
}
