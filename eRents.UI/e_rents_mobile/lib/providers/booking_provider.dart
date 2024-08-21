import 'package:flutter/foundation.dart';
import '../services/booking_service.dart';
import '../models/booking.dart';
import 'base_provider.dart';

class BookingProvider extends BaseProvider {
  final BookingService _bookingService;
  List<Booking> _bookings = [];

  List<Booking> get bookings => _bookings;

  BookingProvider({required BookingService bookingService})
      : _bookingService = bookingService {
    _bookingService.subscribeToBookingUpdates(_handleBookingUpdate);
  }

  void _handleBookingUpdate(Map<String, dynamic> bookingData) {
    final updatedBooking = Booking.fromJson(bookingData);
    _bookings = _bookings.map((b) => b.bookingId == updatedBooking.bookingId ? updatedBooking : b).toList();
    notifyListeners();
  }

  Future<void> fetchBookings() async {
    setState(ViewState.Busy);
    try {
      _bookings = await _bookingService.getBookings();
      setState(ViewState.Idle);
    } catch (e) {
      setError(e.toString());
    }
  }
}
