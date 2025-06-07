import 'dart:convert';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/models/booking_summary.dart';
import 'package:e_rents_desktop/models/booking.dart';

/// Enhanced BookingService with comprehensive booking management
class BookingService extends ApiService {
  BookingService(super.baseUrl, super.storageService);

  // ✅ EXISTING METHODS - Property-focused booking operations
  Future<List<BookingSummary>> getPropertyBookings(String propertyId) async {
    print(
      'BookingService: Attempting to fetch bookings for property $propertyId...',
    );
    try {
      final response = await get(
        '/Bookings?PropertyId=$propertyId&Status=Confirmed,Completed',
        authenticated: true,
      );
      final List<dynamic> data = json.decode(response.body);
      final List<BookingSummary> bookings =
          data
              .map((json) {
                try {
                  return BookingSummary.fromJson(json);
                } catch (e) {
                  print(
                    'BookingService: Error parsing a booking summary for property $propertyId: $e. Skipping this item.',
                  );
                  return null;
                }
              })
              .where((booking) => booking != null)
              .cast<BookingSummary>()
              .toList();
      print(
        'BookingService: Successfully fetched and parsed ${bookings.length} bookings for property $propertyId.',
      );
      return bookings;
    } catch (e) {
      print(
        'BookingService: Error loading property bookings for $propertyId: $e. Backend integration might be pending or endpoint unavailable. Returning empty list.',
      );
      return [];
    }
  }

  Future<List<BookingSummary>> getCurrentBookings(String propertyId) async {
    print(
      'BookingService: Attempting to fetch current bookings for property $propertyId...',
    );
    try {
      final response = await get(
        '/Bookings/current?PropertyId=$propertyId&Status=Active',
        authenticated: true,
      );
      final List<dynamic> data = json.decode(response.body);
      final List<BookingSummary> bookings =
          data
              .map((json) {
                try {
                  return BookingSummary.fromJson(json);
                } catch (e) {
                  print(
                    'BookingService: Error parsing a current booking summary for property $propertyId: $e. Skipping this item.',
                  );
                  return null;
                }
              })
              .where((booking) => booking != null)
              .cast<BookingSummary>()
              .toList();
      print(
        'BookingService: Successfully fetched and parsed ${bookings.length} current bookings for property $propertyId.',
      );
      return bookings;
    } catch (e) {
      print(
        'BookingService: Error loading current bookings for $propertyId: $e. Backend integration might be pending or endpoint unavailable. Returning empty list.',
      );
      return [];
    }
  }

  Future<List<BookingSummary>> getUpcomingBookings(String propertyId) async {
    print(
      'BookingService: Attempting to fetch upcoming bookings for property $propertyId...',
    );
    try {
      final response = await get(
        '/Bookings/upcoming?PropertyId=$propertyId&Status=Upcoming',
        authenticated: true,
      );
      final List<dynamic> data = json.decode(response.body);
      final List<BookingSummary> bookings =
          data
              .map((json) {
                try {
                  return BookingSummary.fromJson(json);
                } catch (e) {
                  print(
                    'BookingService: Error parsing an upcoming booking summary for property $propertyId: $e. Skipping this item.',
                  );
                  return null;
                }
              })
              .where((booking) => booking != null)
              .cast<BookingSummary>()
              .toList();
      print(
        'BookingService: Successfully fetched and parsed ${bookings.length} upcoming bookings for property $propertyId.',
      );
      return bookings;
    } catch (e) {
      print(
        'BookingService: Error loading upcoming bookings for $propertyId: $e. Backend integration might be pending or endpoint unavailable. Returning empty list.',
      );
      return [];
    }
  }

  Future<PropertyBookingStats> getPropertyBookingStats(
    String propertyId,
  ) async {
    print(
      'BookingService: Attempting to fetch booking stats for property $propertyId...',
    );
    try {
      final response = await get(
        '/Properties/$propertyId/booking-stats',
        authenticated: true,
      );
      final Map<String, dynamic> data = json.decode(response.body);
      print(
        'BookingService: Successfully fetched booking stats for property $propertyId.',
      );
      return PropertyBookingStats.fromJson(data);
    } catch (e) {
      print(
        'BookingService: Error loading booking stats for property $propertyId: $e. Backend integration might be pending or endpoint unavailable.',
      );
      throw Exception(
        'Failed to load booking stats for property $propertyId. Backend integration pending or endpoint unavailable. Cause: $e',
      );
    }
  }

  // ✅ NEW METHODS - Full CRUD operations for comprehensive booking management

  /// Get all bookings with optional filtering
  Future<List<Booking>> getAllBookings([Map<String, dynamic>? params]) async {
    try {
      String queryString = '';
      if (params != null && params.isNotEmpty) {
        queryString =
            '?' + params.entries.map((e) => '${e.key}=${e.value}').join('&');
      }

      final response = await get('/Bookings$queryString', authenticated: true);

      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Booking.fromJson(json)).toList();
    } catch (e) {
      print('BookingService: Error loading bookings: $e');
      throw Exception('Failed to load bookings: $e');
    }
  }

  /// Get a single booking by ID
  Future<Booking> getBookingById(String id) async {
    try {
      final response = await get('/Bookings/$id', authenticated: true);

      final Map<String, dynamic> data = json.decode(response.body);
      return Booking.fromJson(data);
    } catch (e) {
      print('BookingService: Error loading booking $id: $e');
      throw Exception('Failed to load booking: $e');
    }
  }

  /// Create a new booking
  Future<Booking> createBooking(BookingInsertRequest request) async {
    try {
      final response = await post(
        '/Bookings',
        request.toJson(),
        authenticated: true,
      );

      final Map<String, dynamic> data = json.decode(response.body);
      return Booking.fromJson(data);
    } catch (e) {
      print('BookingService: Error creating booking: $e');
      throw Exception('Failed to create booking: $e');
    }
  }

  /// Update an existing booking
  Future<Booking> updateBooking(String id, BookingUpdateRequest request) async {
    try {
      final response = await put(
        '/Bookings/$id',
        request.toJson(),
        authenticated: true,
      );

      final Map<String, dynamic> data = json.decode(response.body);
      return Booking.fromJson(data);
    } catch (e) {
      print('BookingService: Error updating booking $id: $e');
      throw Exception('Failed to update booking: $e');
    }
  }

  /// Cancel a booking
  Future<bool> cancelBooking(BookingCancellationRequest request) async {
    try {
      final response = await post(
        '/Bookings/${request.bookingId}/cancel',
        request.toJson(),
        authenticated: true,
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print(
        'BookingService: Error cancelling booking ${request.bookingId}: $e',
      );
      throw Exception('Failed to cancel booking: $e');
    }
  }

  /// Delete a booking (hard delete - use with caution)
  Future<bool> deleteBooking(String id) async {
    try {
      final response = await delete('/Bookings/$id', authenticated: true);

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('BookingService: Error deleting booking $id: $e');
      throw Exception('Failed to delete booking: $e');
    }
  }

  /// Check if a property is available for specific dates
  Future<bool> checkPropertyAvailability({
    required int propertyId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final queryParams = {
        'propertyId': propertyId.toString(),
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      };

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response = await get(
        '/Bookings/availability?$queryString',
        authenticated: true,
      );

      final Map<String, dynamic> data = json.decode(response.body);
      return data['isAvailable'] ?? false;
    } catch (e) {
      print('BookingService: Error checking availability: $e');
      return false; // Conservative approach - assume not available if check fails
    }
  }

  /// Get paginated bookings (Universal System with backend pagination)
  Future<Map<String, dynamic>> getPagedBookings([
    Map<String, dynamic>? params,
  ]) async {
    try {
      // Build query parameters for Universal System
      final queryParams = <String, dynamic>{};

      // Add any additional params
      if (params != null) {
        queryParams.addAll(params);
      }

      String endpoint = '/Bookings';
      if (queryParams.isNotEmpty) {
        final queryString = queryParams.entries
            .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
            .join('&');
        endpoint = '/Bookings?$queryString';
      }

      final response = await get(endpoint, authenticated: true);

      // Backend returns PagedList<BookingResponse> from Universal System
      final Map<String, dynamic> pagedData = json.decode(response.body);
      return pagedData;
    } catch (e) {
      print('BookingService: Error loading paged bookings: $e');
      throw Exception('Failed to load paged bookings: $e');
    }
  }

  /// Get bookings by landlord (all bookings for landlord's properties)
  /// ✅ LEGACY: For backwards compatibility with existing code
  Future<List<Booking>> getBookingsByLandlord([
    Map<String, dynamic>? params,
  ]) async {
    try {
      // Use the new paginated endpoint but return only items for legacy compatibility
      final pagedData = await getPagedBookings(params);

      final List<dynamic> items = pagedData['items'] ?? [];
      return items.map((json) => Booking.fromJson(json)).toList();
    } catch (e) {
      print('BookingService: Error loading landlord bookings: $e');
      throw Exception('Failed to load landlord bookings: $e');
    }
  }

  /// Get bookings by tenant (all tenant's own bookings)
  Future<List<Booking>> getBookingsByTenant([
    Map<String, dynamic>? params,
  ]) async {
    try {
      // Build query parameters
      final queryParams = <String, dynamic>{};

      // Add any additional params
      if (params != null) {
        queryParams.addAll(params);
      }

      String endpoint = '/Bookings';
      if (queryParams.isNotEmpty) {
        final queryString = queryParams.entries
            .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
            .join('&');
        endpoint = '/Bookings?$queryString';
      }

      final response = await get(endpoint, authenticated: true);

      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Booking.fromJson(json)).toList();
    } catch (e) {
      print('BookingService: Error loading tenant bookings: $e');
      throw Exception('Failed to load tenant bookings: $e');
    }
  }

  /// Calculate refund amount for a booking cancellation
  Future<double> calculateRefundAmount(int bookingId) async {
    try {
      final response = await get(
        '/Bookings/$bookingId/refund-calculation',
        authenticated: true,
      );

      final Map<String, dynamic> data = json.decode(response.body);
      return (data['refundAmount'] ?? 0.0).toDouble();
    } catch (e) {
      print(
        'BookingService: Error calculating refund for booking $bookingId: $e',
      );
      return 0.0; // Conservative approach
    }
  }

  /// Get booking count (for pagination/statistics)
  Future<int> getBookingCount([Map<String, dynamic>? params]) async {
    try {
      String queryString = '';
      if (params != null && params.isNotEmpty) {
        queryString =
            '?' + params.entries.map((e) => '${e.key}=${e.value}').join('&');
      }

      final response = await get(
        '/Bookings/count$queryString',
        authenticated: true,
      );

      final Map<String, dynamic> data = json.decode(response.body);
      return data['count'] ?? 0;
    } catch (e) {
      print('BookingService: Error getting booking count: $e');
      return 0;
    }
  }

  /// Check if current user has an active booking for a property
  Future<bool> hasActiveBooking(int propertyId) async {
    try {
      final response = await get(
        '/Bookings/active-check?propertyId=$propertyId',
        authenticated: true,
      );

      final Map<String, dynamic> data = json.decode(response.body);
      return data['hasActiveBooking'] ?? false;
    } catch (e) {
      print(
        'BookingService: Error checking active booking for property $propertyId: $e',
      );
      return false;
    }
  }
}
