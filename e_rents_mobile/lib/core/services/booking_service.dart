import 'dart:convert';
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
        print(
            'Failed to load bookings: ${response.statusCode} ${response.body}');
        throw Exception('Failed to load bookings');
      }
    } catch (e) {
      print('Error in BookingService.getUserBookings: $e');
      throw Exception('An error occurred while fetching bookings: $e');
    }
  }

  // TODO: Add other booking-related methods if needed:
  // - getBookingDetails(int bookingId)
  // - cancelBooking(int bookingId)
  // - updateBooking(int bookingId, Map<String, dynamic> bookingData) // If modification is allowed
}
