import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/booking.dart';
import '../models/booking_summary.dart';
import '../models/property_stats_data.dart';
import 'api_service.dart';

/// ✅ UNIVERSAL SYSTEM BOOKING SERVICE - Full Universal System Integration
///
/// This service provides booking management for landlords using Universal System:
/// - Universal System pagination as default
/// - Non-paginated requests using noPaging=true parameter
/// - Property-based filtering and specialized endpoints
/// - Availability checking and cancellation management
class BookingService extends ApiService {
  BookingService(super.baseUrl, super.secureStorageService);

  String get endpoint => '/bookings';

  /// ✅ UNIVERSAL SYSTEM: Get paginated bookings with full filtering support
  /// DEFAULT METHOD - Uses pagination by default
  /// Matches: GET /bookings?page=1&pageSize=10&sortBy=StartDate&sortDesc=true
  Future<Map<String, dynamic>> getPagedBookings(
    Map<String, dynamic> params,
  ) async {
    try {
      // Build query string from params
      String queryString = '';
      if (params.isNotEmpty) {
        queryString =
            '?' + params.entries.map((e) => '${e.key}=${e.value}').join('&');
      }

      final response = await get('$endpoint$queryString', authenticated: true);
      return json.decode(response.body);
    } catch (e) {
      throw Exception('Failed to fetch paginated bookings: $e');
    }
  }

  /// ✅ UNIVERSAL SYSTEM: Get all bookings without pagination
  /// Uses noPaging=true for cases where all data is needed
  Future<List<Booking>> getAllBookings([Map<String, dynamic>? params]) async {
    try {
      // Use Universal System with noPaging=true for all items
      final queryParams = <String, dynamic>{'noPaging': 'true', ...?params};

      String queryString = '';
      if (queryParams.isNotEmpty) {
        queryString =
            '?' +
            queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
      }

      final response = await get('$endpoint$queryString', authenticated: true);
      final responseData = json.decode(response.body);

      // Handle both paginated and non-paginated responses
      final List<dynamic> items;
      if (responseData is Map && responseData['items'] != null) {
        items = responseData['items'];
      } else if (responseData is List) {
        items = responseData;
      } else {
        items = [];
      }

      return items.map((json) => Booking.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch all bookings: $e');
    }
  }

  /// ✅ LANDLORD SPECIFIC: Get current stays for landlord properties
  /// Matches: GET /bookings/current?propertyId=123
  Future<List<Booking>> getCurrentStays([int? propertyId]) async {
    try {
      final params = <String, dynamic>{};
      if (propertyId != null) {
        params['propertyId'] = propertyId;
      }

      String queryString = '';
      if (params.isNotEmpty) {
        queryString =
            '?' + params.entries.map((e) => '${e.key}=${e.value}').join('&');
      }

      final url = '$endpoint/current$queryString';
      debugPrint('🌐 BookingService: Making API call to: $url');

      final response = await get(url, authenticated: true);
      debugPrint(
        '📋 BookingService: API response status: ${response.statusCode}',
      );
      debugPrint('📋 BookingService: API response body: ${response.body}');

      final List<dynamic> data = json.decode(response.body);
      final result = data.map((json) => Booking.fromJson(json)).toList();
      debugPrint(
        '✅ BookingService: Parsed ${result.length} current bookings from API',
      );
      return result;
    } catch (e) {
      debugPrint('❌ BookingService: getCurrentStays API error: $e');
      throw Exception('Failed to fetch current stays: $e');
    }
  }

  /// ✅ LANDLORD SPECIFIC: Get upcoming stays for landlord properties
  /// Matches: GET /bookings/upcoming?propertyId=123
  Future<List<Booking>> getUpcomingStays([int? propertyId]) async {
    try {
      final params = <String, dynamic>{};
      if (propertyId != null) {
        params['propertyId'] = propertyId;
      }

      String queryString = '';
      if (params.isNotEmpty) {
        queryString =
            '?' + params.entries.map((e) => '${e.key}=${e.value}').join('&');
      }

      final url = '$endpoint/upcoming$queryString';
      debugPrint('🌐 BookingService: Making API call to: $url');

      final response = await get(url, authenticated: true);
      debugPrint(
        '📋 BookingService: API response status: ${response.statusCode}',
      );
      debugPrint('📋 BookingService: API response body: ${response.body}');

      final List<dynamic> data = json.decode(response.body);
      final result = data.map((json) => Booking.fromJson(json)).toList();
      debugPrint(
        '✅ BookingService: Parsed ${result.length} upcoming bookings from API',
      );
      return result;
    } catch (e) {
      debugPrint('❌ BookingService: getUpcomingStays API error: $e');
      throw Exception('Failed to fetch upcoming stays: $e');
    }
  }

  /// ✅ AVAILABILITY: Check property availability
  /// Matches: GET /bookings/availability/{propertyId}?startDate=...&endDate=...
  Future<bool> checkPropertyAvailability({
    required int propertyId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final params = {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      };

      String queryString =
          '?' + params.entries.map((e) => '${e.key}=${e.value}').join('&');

      final response = await get(
        '$endpoint/availability/$propertyId$queryString',
        authenticated: true,
      );

      final responseData = json.decode(response.body);
      return responseData['isAvailable'] ?? false;
    } catch (e) {
      throw Exception('Failed to check property availability: $e');
    }
  }

  /// ✅ CANCELLATION: Cancel a booking with enhanced request
  /// Matches: POST /bookings/{id}/cancel
  Future<bool> cancelBooking(
    int bookingId,
    String reason,
    bool requestRefund, {
    String? additionalNotes,
    bool isEmergency = false,
    String? refundMethod,
  }) async {
    try {
      final requestBody = {
        'bookingId': bookingId,
        'cancellationReason': reason,
        'requestRefund': requestRefund,
        'additionalNotes': additionalNotes,
        'isEmergency': isEmergency,
        'refundMethod': refundMethod ?? 'Original',
      };

      final response = await post(
        '$endpoint/$bookingId/cancel',
        requestBody,
        authenticated: true,
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }

  /// ✅ REFUND: Calculate refund amount
  /// Matches: GET /bookings/{id}/refund-calculation?cancellationDate=...
  Future<double> calculateRefundAmount(
    int bookingId,
    DateTime cancellationDate,
  ) async {
    try {
      final params = <String, dynamic>{
        'cancellationDate': cancellationDate.toIso8601String(),
      };

      String queryString = '';
      if (params.isNotEmpty) {
        queryString =
            '?' + params.entries.map((e) => '${e.key}=${e.value}').join('&');
      }

      final response = await get(
        '$endpoint/$bookingId/refund-calculation$queryString',
        authenticated: true,
      );

      final responseData = json.decode(response.body);
      return (responseData['refundAmount'] ?? 0.0).toDouble();
    } catch (e) {
      throw Exception('Failed to calculate refund amount: $e');
    }
  }

  /// ✅ CRUD: Get single booking
  /// Matches: GET /bookings/{id}
  Future<Booking> getBookingById(String id) async {
    try {
      final response = await get('$endpoint/$id', authenticated: true);
      final responseData = json.decode(response.body);
      return Booking.fromJson(responseData);
    } catch (e) {
      throw Exception('Failed to fetch booking $id: $e');
    }
  }

  /// ✅ CRUD: Create booking
  /// Matches: POST /bookings
  Future<Booking> createBooking(Map<String, dynamic> request) async {
    try {
      final response = await post(endpoint, request, authenticated: true);
      final responseData = json.decode(response.body);
      return Booking.fromJson(responseData);
    } catch (e) {
      throw Exception('Failed to create booking: $e');
    }
  }

  /// ✅ CRUD: Update booking
  /// Matches: PUT /bookings/{id}
  Future<Booking> updateBooking(String id, Map<String, dynamic> request) async {
    try {
      final response = await put('$endpoint/$id', request, authenticated: true);
      final responseData = json.decode(response.body);
      return Booking.fromJson(responseData);
    } catch (e) {
      throw Exception('Failed to update booking $id: $e');
    }
  }

  /// ✅ CRUD: Delete booking
  /// Matches: DELETE /bookings/{id}
  Future<bool> deleteBooking(String id) async {
    try {
      final response = await delete('$endpoint/$id', authenticated: true);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw Exception('Failed to delete booking $id: $e');
    }
  }

  /// ✅ UNIVERSAL SYSTEM: Get booking count using Universal System
  /// Uses Universal System count endpoint or extracts from paged response
  Future<int> getBookingCount([Map<String, dynamic>? params]) async {
    try {
      final queryParams = <String, dynamic>{
        'pageSize': 1, // Minimal page size, we only need count
        ...?params,
      };

      String queryString = '';
      if (queryParams.isNotEmpty) {
        queryString =
            '?' +
            queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
      }

      final response = await get('$endpoint$queryString', authenticated: true);
      final responseData = json.decode(response.body);
      return responseData['totalCount'] ?? 0;
    } catch (e) {
      throw Exception('Failed to get booking count: $e');
    }
  }

  /// Helper: Check if user has active booking for property
  Future<bool> hasActiveBooking(int propertyId) async {
    try {
      final currentStays = await getCurrentStays(propertyId);
      return currentStays.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check active booking status: $e');
    }
  }

  // ✅ PROPERTY STATS METHODS (for property_stats_provider.dart)

  /// Get current bookings (for property stats - BookingSummary format)
  Future<List<BookingSummary>> getCurrentBookings(String propertyId) async {
    try {
      debugPrint(
        '🔍 BookingService: getCurrentBookings called with propertyId: $propertyId',
      );

      // Convert string to int for internal API calls
      final propertyIdInt = int.tryParse(propertyId);
      if (propertyIdInt == null) {
        debugPrint('❌ BookingService: Invalid propertyId format: $propertyId');
        return [];
      }

      debugPrint(
        '🔄 BookingService: Calling getCurrentStays for propertyId: $propertyIdInt',
      );
      final bookings = await getCurrentStays(propertyIdInt);
      debugPrint(
        '✅ BookingService: getCurrentStays returned ${bookings.length} bookings',
      );

      final result =
          bookings
              .map((booking) => BookingSummary.fromBooking(booking))
              .toList();
      debugPrint(
        '✅ BookingService: Converted to ${result.length} BookingSummary objects',
      );
      return result;
    } catch (e) {
      debugPrint('❌ BookingService: Error loading current bookings: $e');
      return [];
    }
  }

  /// Get upcoming bookings (for property stats - BookingSummary format)
  Future<List<BookingSummary>> getUpcomingBookings(String propertyId) async {
    try {
      debugPrint(
        '🔍 BookingService: getUpcomingBookings called with propertyId: $propertyId',
      );

      // Convert string to int for internal API calls
      final propertyIdInt = int.tryParse(propertyId);
      if (propertyIdInt == null) {
        debugPrint('❌ BookingService: Invalid propertyId format: $propertyId');
        return [];
      }

      debugPrint(
        '🔄 BookingService: Calling getUpcomingStays for propertyId: $propertyIdInt',
      );
      final bookings = await getUpcomingStays(propertyIdInt);
      debugPrint(
        '✅ BookingService: getUpcomingStays returned ${bookings.length} bookings',
      );

      final result =
          bookings
              .map((booking) => BookingSummary.fromBooking(booking))
              .toList();
      debugPrint(
        '✅ BookingService: Converted to ${result.length} BookingSummary objects',
      );
      return result;
    } catch (e) {
      debugPrint('❌ BookingService: Error loading upcoming bookings: $e');
      return [];
    }
  }

  /// Get property booking statistics (for property stats)
  Future<PropertyBookingStats> getPropertyBookingStats(
    String propertyId,
  ) async {
    try {
      // For now, calculate basic stats from available bookings
      final propertyIdInt = int.tryParse(propertyId);
      if (propertyIdInt == null) {
        return PropertyBookingStats(
          totalBookings: 0,
          totalRevenue: 0.0,
          averageBookingValue: 0.0,
          currentOccupancy: 0,
          occupancyRate: 0.0,
        );
      }

      // Get all bookings for the property using Universal System
      final allBookings = await getAllBookings({'propertyId': propertyIdInt});
      final currentBookings = await getCurrentStays(propertyIdInt);

      // Calculate stats
      final totalBookings = allBookings.length;
      final totalRevenue = allBookings.fold<double>(
        0.0,
        (sum, booking) => sum + booking.totalPrice,
      );
      final averageBookingValue =
          totalBookings > 0 ? totalRevenue / totalBookings : 0.0;
      final currentOccupancy = currentBookings.length;

      // Simple occupancy rate calculation (could be enhanced)
      final occupancyRate = currentOccupancy > 0 ? 1.0 : 0.0;

      return PropertyBookingStats(
        totalBookings: totalBookings,
        totalRevenue: totalRevenue,
        averageBookingValue: averageBookingValue,
        currentOccupancy: currentOccupancy,
        occupancyRate: occupancyRate,
      );
    } catch (e) {
      debugPrint('Error loading property booking stats: $e');
      return PropertyBookingStats(
        totalBookings: 0,
        totalRevenue: 0.0,
        averageBookingValue: 0.0,
        currentOccupancy: 0,
        occupancyRate: 0.0,
      );
    }
  }
}
