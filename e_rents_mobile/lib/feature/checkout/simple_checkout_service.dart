import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/models/booking_model.dart';
import 'package:e_rents_mobile/core/services/api_service.dart';

/// Simplified checkout service for tenant booking operations
/// Handles property booking, payment processing, and rental requests
class SimpleCheckoutService {
  final ApiService _apiService;

  SimpleCheckoutService(this._apiService);

  /// Create a new booking/rental request
  Future<bool> createBooking({
    required int propertyId,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    required int numberOfGuests,
    String? specialRequests,
    Map<String, dynamic>? paymentInfo,
  }) async {
    try {
      final bookingData = {
        'propertyId': propertyId,
        'checkInDate': checkInDate.toIso8601String(),
        'checkOutDate': checkOutDate.toIso8601String(),
        'numberOfGuests': numberOfGuests,
        'specialRequests': specialRequests,
        'paymentInfo': paymentInfo,
        'status': 'pending',
      };

      final response = await _apiService.post('api/Bookings', bookingData);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error creating booking: $e');
      return false;
    }
  }

  /// Submit rental application for long-term rental
  Future<bool> submitRentalApplication({
    required int propertyId,
    required DateTime desiredMoveInDate,
    required String employmentInfo,
    required String incomeInfo,
    String? references,
    String? additionalNotes,
  }) async {
    try {
      final applicationData = {
        'propertyId': propertyId,
        'desiredMoveInDate': desiredMoveInDate.toIso8601String(),
        'employmentInfo': employmentInfo,
        'incomeInfo': incomeInfo,
        'references': references,
        'additionalNotes': additionalNotes,
        'status': 'submitted',
      };

      final response = await _apiService.post('api/RentalApplications', applicationData);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error submitting rental application: $e');
      return false;
    }
  }

  /// Calculate booking cost
  Future<Map<String, dynamic>?> calculateBookingCost({
    required int propertyId,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    required int numberOfGuests,
  }) async {
    try {
      final costData = {
        'propertyId': propertyId,
        'checkInDate': checkInDate.toIso8601String(),
        'checkOutDate': checkOutDate.toIso8601String(),
        'numberOfGuests': numberOfGuests,
      };

      final response = await _apiService.post('api/Bookings/calculate-cost', costData);
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Error calculating booking cost: $e');
      return null;
    }
  }

  /// Process payment for booking
  Future<bool> processPayment({
    required int bookingId,
    required double amount,
    required String paymentMethod,
    Map<String, dynamic>? paymentDetails,
  }) async {
    try {
      final paymentData = {
        'bookingId': bookingId,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'paymentDetails': paymentDetails,
      };

      final response = await _apiService.post('api/Payments/process', paymentData);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error processing payment: $e');
      return false;
    }
  }

  /// Get booking details
  Future<Booking?> getBookingDetails(int bookingId) async {
    try {
      final response = await _apiService.get('api/Bookings/$bookingId');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Booking.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting booking details: $e');
      return null;
    }
  }

  /// Get tenant's bookings
  Future<List<Booking>> getTenantBookings({String? status}) async {
    try {
      String endpoint = 'api/Bookings/tenant';
      if (status != null) {
        endpoint += '?status=$status';
      }

      final response = await _apiService.get(endpoint);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Booking.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting tenant bookings: $e');
      return [];
    }
  }

  /// Cancel booking
  Future<bool> cancelBooking(int bookingId, {String? reason}) async {
    try {
      final cancelData = {
        'reason': reason ?? 'Cancelled by tenant',
        'status': 'cancelled',
      };

      final response = await _apiService.put('api/Bookings/$bookingId/cancel', cancelData);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error cancelling booking: $e');
      return false;
    }
  }

  /// Check property availability
  Future<bool> checkAvailability({
    required int propertyId,
    required DateTime checkInDate,
    required DateTime checkOutDate,
  }) async {
    try {
      final availabilityData = {
        'propertyId': propertyId,
        'checkInDate': checkInDate.toIso8601String(),
        'checkOutDate': checkOutDate.toIso8601String(),
      };

      final response = await _apiService.post('api/Properties/check-availability', availabilityData);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['available'] as bool? ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking availability: $e');
      return false;
    }
  }
}