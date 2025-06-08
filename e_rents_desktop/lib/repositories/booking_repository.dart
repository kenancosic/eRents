import '../base/base.dart';
import '../services/booking_service.dart';
import '../models/booking.dart';
import '../widgets/table/custom_table.dart';

/// Repository for booking data management with caching support
class BookingRepository extends BaseRepository<Booking, BookingService> {
  BookingRepository({
    required BookingService service,
    required CacheManager cacheManager,
  }) : super(service: service, cacheManager: cacheManager);

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

  // ✅ BOOKING-SPECIFIC METHODS

  /// Get bookings by landlord with caching
  Future<List<Booking>> getBookingsByLandlord([
    Map<String, dynamic>? params,
  ]) async {
    try {
      final cacheKey = _buildSpecialCacheKey('landlord', params);

      // Try cache first
      if (enableCaching) {
        final cached = await cacheManager.get<List<Booking>>(cacheKey);
        if (cached != null) {
          return cached;
        }
      }

      // Fetch from service
      final bookings = await service.getBookingsByLandlord(params);

      // Cache the result
      if (enableCaching) {
        await cacheManager.set(cacheKey, bookings, duration: defaultCacheTtl);
      }

      return bookings;
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Cancel a booking
  Future<bool> cancelBooking(
    int bookingId,
    String reason, [
    bool requestRefund = false,
  ]) async {
    try {
      final success = await service.cancelBooking(
        bookingId,
        reason,
        requestRefund,
      );

      if (success && enableCaching) {
        // Invalidate cache for the specific booking and lists
        final bookingCacheKey = _buildItemCacheKey(bookingId.toString());
        await cacheManager.remove(bookingCacheKey);
        await _invalidateListCaches();
      }

      return success;
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
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
  Future<double> calculateRefundAmount(int bookingId) async {
    try {
      final cacheKey = 'refund_${bookingId}';

      // Try cache first (short TTL for calculations)
      if (enableCaching) {
        final cached = await cacheManager.get<double>(cacheKey);
        if (cached != null) {
          return cached;
        }
      }

      final refundAmount = await service.calculateRefundAmount(bookingId);

      // Cache for a short time (calculations might change)
      if (enableCaching) {
        await cacheManager.set(
          cacheKey,
          refundAmount,
          duration: const Duration(minutes: 5),
        );
      }

      return refundAmount;
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
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

  /// ✅ UNIVERSAL SYSTEM: Get paginated bookings for landlords
  /// Matches BookingController.cs GET /bookings with Universal System support
  Future<PagedResult<Booking>> getPagedBookings(
    Map<String, dynamic> params,
  ) async {
    try {
      final cacheKey = _buildSpecialCacheKey('paged', params);

      // Try cache first (shorter TTL for paginated data)
      if (enableCaching) {
        final cached = await cacheManager.get<PagedResult<Booking>>(cacheKey);
        if (cached != null) {
          return cached;
        }
      }

      // ✅ LANDLORD FOCUS: The controller automatically filters for landlord's properties
      // through role-based authorization and context
      final pagedData = await service.getPagedBookings(params);

      // Parse Universal System PagedList<BookingResponse>
      final List<dynamic> items = pagedData['items'] ?? [];
      final bookings = items.map((json) => Booking.fromJson(json)).toList();

      final pagedResult = PagedResult<Booking>(
        items: bookings,
        totalCount: pagedData['totalCount'] ?? 0,
        page: (pagedData['page'] ?? 1) - 1, // Convert to 0-based for frontend
        pageSize: pagedData['pageSize'] ?? 25,
        totalPages: pagedData['totalPages'] ?? 0,
      );

      // Cache the result (shorter TTL for paginated data)
      if (enableCaching) {
        await cacheManager.set(
          cacheKey,
          pagedResult,
          duration: const Duration(minutes: 2),
        );
      }

      return pagedResult;
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
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
}
