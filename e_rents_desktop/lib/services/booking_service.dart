import 'dart:convert';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/models/booking_summary.dart';

class BookingService extends ApiService {
  BookingService(super.baseUrl, super.storageService);

  Future<List<BookingSummary>> getPropertyBookings(String propertyId) async {
    try {
      final response = await get(
        '/Bookings?PropertyId=$propertyId',
        authenticated: true,
      );
      final List<dynamic> data = json.decode(response.body);
      return data
          .map((json) {
            try {
              return BookingSummary.fromJson(json);
            } catch (e) {
              print('Error parsing booking: $e');
              return null;
            }
          })
          .where((booking) => booking != null)
          .cast<BookingSummary>()
          .toList();
    } catch (e) {
      print('Error loading property bookings: $e');
      return [];
    }
  }

  Future<List<BookingSummary>> getCurrentBookings(String propertyId) async {
    try {
      final response = await get(
        '/Bookings/current?PropertyId=$propertyId',
        authenticated: true,
      );
      final List<dynamic> data = json.decode(response.body);
      return data
          .map((json) {
            try {
              return BookingSummary.fromJson(json);
            } catch (e) {
              print('Error parsing current booking: $e');
              return null;
            }
          })
          .where((booking) => booking != null)
          .cast<BookingSummary>()
          .toList();
    } catch (e) {
      print('Error loading current bookings: $e');
      return [];
    }
  }

  Future<List<BookingSummary>> getUpcomingBookings(String propertyId) async {
    try {
      final response = await get(
        '/Bookings/upcoming?PropertyId=$propertyId',
        authenticated: true,
      );
      final List<dynamic> data = json.decode(response.body);
      return data
          .map((json) {
            try {
              return BookingSummary.fromJson(json);
            } catch (e) {
              print('Error parsing upcoming booking: $e');
              return null;
            }
          })
          .where((booking) => booking != null)
          .cast<BookingSummary>()
          .toList();
    } catch (e) {
      print('Error loading upcoming bookings: $e');
      return [];
    }
  }

  Future<PropertyBookingStats> getPropertyBookingStats(
    String propertyId,
  ) async {
    try {
      final response = await get(
        '/Properties/$propertyId/booking-stats',
        authenticated: true,
      );
      final Map<String, dynamic> data = json.decode(response.body);
      return PropertyBookingStats.fromJson(data);
    } catch (e) {
      print('Error loading booking stats: $e');
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
