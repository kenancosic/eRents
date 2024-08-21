import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/booking.dart';
import '../config.dart';

class BookingService {
  final String _baseUrl = Config.baseUrl;

  Future<List<Booking>> getBookings() async {
    final url = Uri.parse('$_baseUrl/bookings');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((bookingJson) => Booking.fromJson(bookingJson)).toList();
    } else {
      throw Exception('Failed to load bookings');
    }
  }

  void subscribeToBookingUpdates(Function(Map<String, dynamic>) onBookingUpdate) {
    // Implementation for subscribing to booking updates via a WebSocket or another real-time mechanism.
  }
}
