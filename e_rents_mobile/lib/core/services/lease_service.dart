import 'dart:convert';
import 'package:e_rents_mobile/core/models/lease_extension_request.dart';
import 'package:e_rents_mobile/core/models/booking_model.dart';
import 'package:e_rents_mobile/core/services/api_service.dart';

class LeaseService {
  final ApiService _apiService;

  LeaseService(this._apiService);

  /// Submit a lease extension request
  Future<bool> requestLeaseExtension(LeaseExtensionRequest request) async {
    try {
      // Mock API delay
      await Future.delayed(const Duration(milliseconds: 1200));

      // In a real app, this would send the request to the server
      /* Real API call:
      final response = await _apiService.post(
        '/leases/extension-requests',
        request.toJson(),
        authenticated: true,
      );
      
      return response.statusCode == 201;
      */

      return true; // Mock success
    } catch (e) {
      print('Error requesting lease extension: $e');
      return false;
    }
  }

  /// Get lease extension requests for a tenant
  Future<List<LeaseExtensionRequest>> getLeaseExtensionRequests(
      int tenantId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));

      // Mock data
      return [
        LeaseExtensionRequest(
          requestId: 1,
          bookingId: 201,
          propertyId: 101,
          tenantId: tenantId,
          newEndDate: null, // Request for indefinite extension
          newMinimumStayEndDate: DateTime.now().add(const Duration(days: 90)),
          reason: 'Would like to extend my stay for at least 3 more months',
          status: LeaseExtensionStatus.pending,
          dateRequested: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];

      /* Real API call:
      final response = await _apiService.get(
        '/leases/extension-requests/tenant/$tenantId',
        authenticated: true,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => LeaseExtensionRequest.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load lease extension requests');
      }
      */
    } catch (e) {
      print('Error getting lease extension requests: $e');
      return [];
    }
  }

  /// Cancel a booking
  Future<bool> cancelBooking(int bookingId, String reason) async {
    try {
      await Future.delayed(const Duration(milliseconds: 1500));

      // In a real app, this would:
      // 1. Update booking status to cancelled
      // 2. Process any refunds according to cancellation policy
      // 3. Send notification to landlord

      /* Real API call:
      final response = await _apiService.put(
        '/bookings/$bookingId/cancel',
        {'reason': reason},
        authenticated: true,
      );
      
      return response.statusCode == 200;
      */

      return true; // Mock success
    } catch (e) {
      print('Error cancelling booking: $e');
      return false;
    }
  }

  /// Get booking availability for a property
  Future<Map<DateTime, bool>> getPropertyAvailability(
    int propertyId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 600));

      // Mock availability data
      final Map<DateTime, bool> availability = {};
      final start = startDate ?? DateTime.now();
      final end = endDate ?? DateTime.now().add(const Duration(days: 60));

      for (var i = 0; i <= end.difference(start).inDays; i++) {
        final date = start.add(Duration(days: i));
        // Mock some dates as unavailable (weekends for example)
        availability[date] = date.weekday != 6 && date.weekday != 7;
      }

      return availability;

      /* Real API call:
      final response = await _apiService.get(
        '/properties/$propertyId/availability?start=${start.toIso8601String()}&end=${end.toIso8601String()}',
        authenticated: true,
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data.map((key, value) => MapEntry(DateTime.parse(key), value as bool));
      } else {
        throw Exception('Failed to load property availability');
      }
      */
    } catch (e) {
      print('Error getting property availability: $e');
      return {};
    }
  }

  /// Get booking details with calendar information
  Future<Booking?> getBookingDetails(int bookingId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      // Mock implementation - would fetch from API
      return null;

      /* Real API call:
      final response = await _apiService.get(
        '/bookings/$bookingId',
        authenticated: true,
      );
      
      if (response.statusCode == 200) {
        return Booking.fromJson(jsonDecode(response.body));
      }
      return null;
      */
    } catch (e) {
      print('Error getting booking details: $e');
      return null;
    }
  }
}
