import 'dart:convert';
import 'package:e_rents_desktop/services/api_service.dart';

class BookingService extends ApiService {
  BookingService(super.baseUrl, super.storageService);

  Future<List<BookingSummary>> getPropertyBookings(String propertyId) async {
    final response = await get(
      '/Bookings?PropertyId=$propertyId',
      authenticated: true,
    );
    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => BookingSummary.fromJson(json)).toList();
  }

  Future<List<BookingSummary>> getCurrentBookings(String propertyId) async {
    final response = await get(
      '/Bookings/current?PropertyId=$propertyId',
      authenticated: true,
    );
    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => BookingSummary.fromJson(json)).toList();
  }

  Future<List<BookingSummary>> getUpcomingBookings(String propertyId) async {
    final response = await get(
      '/Bookings/upcoming?PropertyId=$propertyId',
      authenticated: true,
    );
    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => BookingSummary.fromJson(json)).toList();
  }

  Future<PropertyBookingStats> getPropertyBookingStats(
    String propertyId,
  ) async {
    final response = await get(
      '/Properties/$propertyId/booking-stats',
      authenticated: true,
    );
    final Map<String, dynamic> data = json.decode(response.body);
    return PropertyBookingStats.fromJson(data);
  }
}

class BookingSummary {
  final int bookingId;
  final int propertyId;
  final String propertyName;
  final DateTime startDate;
  final DateTime? endDate;
  final double totalPrice;
  final String status;
  final String currency;
  final String? tenantName;
  final String? tenantEmail;

  BookingSummary({
    required this.bookingId,
    required this.propertyId,
    required this.propertyName,
    required this.startDate,
    this.endDate,
    required this.totalPrice,
    required this.status,
    required this.currency,
    this.tenantName,
    this.tenantEmail,
  });

  factory BookingSummary.fromJson(Map<String, dynamic> json) {
    return BookingSummary(
      bookingId: json['bookingId'] ?? 0,
      propertyId: json['propertyId'] ?? 0,
      propertyName: json['propertyName'] ?? '',
      startDate: DateTime.parse(
        json['startDate'] ?? DateTime.now().toIso8601String(),
      ),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? json['bookingStatus'] ?? 'Unknown',
      currency: json['currency'] ?? 'BAM',
      tenantName: json['tenantName'],
      tenantEmail: json['tenantEmail'],
    );
  }
}

class PropertyBookingStats {
  final int totalBookings;
  final double totalRevenue;
  final double averageBookingValue;
  final int currentOccupancy;
  final double occupancyRate;

  PropertyBookingStats({
    required this.totalBookings,
    required this.totalRevenue,
    required this.averageBookingValue,
    required this.currentOccupancy,
    required this.occupancyRate,
  });

  factory PropertyBookingStats.fromJson(Map<String, dynamic> json) {
    return PropertyBookingStats(
      totalBookings: json['totalBookings'] ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      averageBookingValue:
          (json['averageBookingValue'] as num?)?.toDouble() ?? 0.0,
      currentOccupancy: json['currentOccupancy'] ?? 0,
      occupancyRate: (json['occupancyRate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
