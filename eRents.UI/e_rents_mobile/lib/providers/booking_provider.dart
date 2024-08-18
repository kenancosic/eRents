import 'dart:convert';
import 'package:e_rents_mobile/providers/base_provider.dart';
import 'package:e_rents_mobile/models/booking.dart';

class BookingProvider extends BaseProvider<Booking> {
  BookingProvider() : super("Bookings");

  @override
  Booking fromJson(data) {
    return Booking.fromJson(data);
  }

  Future<List<Booking>> getBookingsByPropertyId(int propertyId) async {
    var url = Uri.parse("$baseUrl$endpoint/byProperty/$propertyId");  // Use the getter

    Map<String, String> headers = await createHeaders();

    try {
      var response = await http!.get(url, headers: headers);
      return (jsonDecode(response.body) as List)
          .map((x) => fromJson(x))
          .cast<Booking>()
          .toList();
    } catch (e) {
      logError(e, 'getBookingsByPropertyId');
      rethrow;
    }
  }

  Future<List<Booking>> getBookingsByUserId(int userId) async {
    var url = Uri.parse("$baseUrl$endpoint/user/$userId");  // Use the getter

    Map<String, String> headers = await createHeaders();

    try {
      var response = await http!.get(url, headers: headers);
      return (jsonDecode(response.body) as List)
          .map((x) => fromJson(x))
          .cast<Booking>()
          .toList();
    } catch (e) {
      logError(e, 'getBookingsByUserId');
      rethrow;
    }
  }
}
