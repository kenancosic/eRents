import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:e_rents_mobile/core/models/booking_model.dart'; // Changed to booking_model.dart
import 'package:e_rents_mobile/core/services/api_service.dart';

class BookingService {
  final ApiService _apiService;

  BookingService(this._apiService);

  Future<List<Booking>> getUserBookings() async {
    try {
      // TODO: Replace with actual endpoint and ensure it returns bookings for the logged-in user.
      // The backend will need to identify the user from the auth token.
      final response =
          await _apiService.get('/Bookings/MyBookings', authenticated: true);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        // Assuming Booking.fromJson can handle the structure from your backend DTO
        return data.map((json) => Booking.fromJson(json)).toList();
      } else {
        // Consider more specific error handling based on status code
        debugPrint(
            'BookingService: Failed to load bookings: ${response.statusCode} ${response.body}');
        throw Exception('Failed to load bookings: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('BookingService.getUserBookings: $e');
      if (e is Exception) rethrow;
      throw Exception('An error occurred while fetching bookings: $e');
    }
  }

  Future<Booking> createBooking({
    required int propertyId,
    required DateTime startDate,
    DateTime? endDate,
    required double totalPrice,
    required int numberOfGuests,
    String? specialRequests,
    String paymentMethod = 'PayPal',
  }) async {
    try {
      final Map<String, dynamic> bookingData = {
        'propertyId': propertyId,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'totalPrice': totalPrice,
        'numberOfGuests': numberOfGuests,
        'specialRequests': specialRequests,
        'paymentMethod': paymentMethod,
      };

      final response = await _apiService.post(
        '/Bookings',
        bookingData,
        authenticated: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return Booking.fromJson(data);
      } else {
        debugPrint(
            'BookingService: Failed to create booking: ${response.statusCode} ${response.body}');
        throw Exception(
            'Failed to create booking: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('BookingService.createBooking: $e');
      if (e is Exception) rethrow;
      throw Exception('An error occurred while creating booking: $e');
    }
  }

  Future<Booking?> getBookingDetails(int bookingId) async {
    try {
      final response = await _apiService.get(
        '/Bookings/$bookingId',
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return Booking.fromJson(data);
      } else if (response.statusCode == 404) {
        debugPrint('BookingService: Booking $bookingId not found');
        return null;
      } else {
        debugPrint(
            'BookingService: Failed to load booking details: ${response.statusCode} ${response.body}');
        throw Exception(
            'Failed to load booking details: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('BookingService.getBookingDetails: $e');
      if (e is Exception) rethrow;
      return null;
    }
  }

  Future<bool> cancelBooking(int bookingId) async {
    try {
      final response = await _apiService.delete(
        '/Bookings/$bookingId',
        authenticated: true,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        debugPrint(
            'BookingService: Failed to cancel booking: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('BookingService.cancelBooking: $e');
      return false;
    }
  }
}
