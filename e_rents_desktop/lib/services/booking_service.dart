import 'dart:convert';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/models/booking_summary.dart';

// TODO: Full backend integration for all booking features is pending.
// Ensure all endpoints are functional and error handling is robust.
class BookingService extends ApiService {
  BookingService(super.baseUrl, super.storageService);

  Future<List<BookingSummary>> getPropertyBookings(String propertyId) async {
    print(
      'BookingService: Attempting to fetch bookings for property $propertyId...',
    );
    try {
      final response = await get(
        '/Bookings?PropertyId=$propertyId',
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
        '/Bookings/current?PropertyId=$propertyId',
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
        '/Bookings/upcoming?PropertyId=$propertyId',
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
}
