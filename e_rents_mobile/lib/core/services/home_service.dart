import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:e_rents_mobile/core/models/booking_model.dart';
import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/core/services/api_service.dart';

class HomeService {
  final ApiService _apiService;

  HomeService(this._apiService);

  /// Get bookings where the user is currently residing
  Future<List<Booking>> getCurrentResidences() async {
    try {
      final response =
          await _apiService.get('/Bookings/current', authenticated: true);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Booking.fromJson(json)).toList();
      } else {
        debugPrint(
            'HomeService: Failed to load current residences: ${response.statusCode} ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('HomeService.getCurrentResidences: $e');
      return [];
    }
  }

  /// Get upcoming bookings for the user
  Future<List<Booking>> getUpcomingStays() async {
    try {
      final response =
          await _apiService.get('/Bookings/upcoming', authenticated: true);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Booking.fromJson(json)).toList();
      } else {
        debugPrint(
            'HomeService: Failed to load upcoming stays: ${response.statusCode} ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('HomeService.getUpcomingStays: $e');
      return [];
    }
  }

  /// Get popular/most rented properties
  Future<List<Property>> getMostRentedProperties() async {
    try {
      final response = await _apiService
          .get('/Properties?sortBy=BookingCount&limit=5', authenticated: true);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Property.fromJson(json)).toList();
      } else {
        debugPrint(
            'HomeService: Failed to load popular properties: ${response.statusCode} ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('HomeService.getMostRentedProperties: $e');
      return [];
    }
  }
}
