import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/core/models/booking_model.dart';
import 'package:e_rents_mobile/core/services/api_service.dart';

class PropertyAvailabilityService {
  final ApiService _apiService;

  PropertyAvailabilityService(this._apiService);

  /// Get property availability considering existing bookings
  Future<Map<DateTime, bool>> getPropertyAvailability(
    int propertyId, {
    DateTime? startDate,
    DateTime? endDate,
    List<Booking>? existingBookings,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 600));

      final start = startDate ?? DateTime.now();
      final end = endDate ?? DateTime.now().add(const Duration(days: 90));
      final Map<DateTime, bool> availability = {};

      // Initialize all dates as available
      for (var i = 0; i <= end.difference(start).inDays; i++) {
        final date = start.add(Duration(days: i));
        final normalizedDate = DateTime(date.year, date.month, date.day);

        // Mark past dates as unavailable
        if (normalizedDate.isBefore(DateTime.now())) {
          availability[normalizedDate] = false;
          continue;
        }

        availability[normalizedDate] = true;
      }

      // Block dates based on existing bookings
      if (existingBookings != null) {
        for (final booking in existingBookings) {
          if (booking.propertyId == propertyId &&
              booking.status != BookingStatus.cancelled) {
            _blockBookingDates(availability, booking);
          }
        }
      }

      // Add some mock maintenance/unavailable periods
      _addMaintenancePeriods(availability, start, end);

      return availability;

      /* Real API call would be:
      final response = await _apiService.get(
        '/api/properties/$propertyId/availability?start=${start.toIso8601String()}&end=${end.toIso8601String()}',
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

  /// Block dates for a specific booking
  void _blockBookingDates(Map<DateTime, bool> availability, Booking booking) {
    final startDate = DateTime(
      booking.startDate.year,
      booking.startDate.month,
      booking.startDate.day,
    );

    DateTime endDate;
    if (booking.endDate != null) {
      endDate = DateTime(
        booking.endDate!.year,
        booking.endDate!.month,
        booking.endDate!.day,
      );
    } else {
      // For indefinite bookings, block for a reasonable period
      endDate = startDate.add(const Duration(days: 365));
    }

    // Block all dates in the booking range
    for (var date = startDate;
        date.isBefore(endDate) || date.isAtSameMomentAs(endDate);
        date = date.add(const Duration(days: 1))) {
      availability[date] = false;
    }
  }

  /// Add mock maintenance periods
  void _addMaintenancePeriods(
      Map<DateTime, bool> availability, DateTime start, DateTime end) {
    // Mock: Block every 30th day for maintenance
    for (var i = 30; i <= end.difference(start).inDays; i += 30) {
      final maintenanceDate = start.add(Duration(days: i));
      final normalizedDate = DateTime(
        maintenanceDate.year,
        maintenanceDate.month,
        maintenanceDate.day,
      );
      availability[normalizedDate] = false;
    }
  }

  /// Check if a date range is available
  bool isDateRangeAvailable(
    Map<DateTime, bool> availability,
    DateTime startDate,
    DateTime endDate,
  ) {
    for (var date = startDate;
        date.isBefore(endDate) || date.isAtSameMomentAs(endDate);
        date = date.add(const Duration(days: 1))) {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      if (!(availability[normalizedDate] ?? false)) {
        return false;
      }
    }
    return true;
  }

  /// Get next available date from a given start date
  DateTime? getNextAvailableDate(
    Map<DateTime, bool> availability,
    DateTime fromDate,
  ) {
    for (var i = 0; i <= 365; i++) {
      final date = fromDate.add(Duration(days: i));
      final normalizedDate = DateTime(date.year, date.month, date.day);
      if (availability[normalizedDate] ?? false) {
        return normalizedDate;
      }
    }
    return null;
  }

  /// Calculate pricing for a date range
  Map<String, dynamic> calculatePricing({
    required Property property,
    required DateTime startDate,
    required DateTime endDate,
    required bool isDailyRental,
  }) {
    final duration = endDate.difference(startDate).inDays;
    double baseRate;
    String unitLabel;
    int unitCount;

    if (isDailyRental && property.dailyRate != null) {
      baseRate = property.dailyRate!;
      unitLabel = 'nights';
      unitCount = duration;
    } else {
      // Monthly calculation
      baseRate = property.price;
      unitLabel = 'months';
      unitCount = (duration / 30).ceil();
      if (unitCount < 1) unitCount = 1;
    }

    final subtotal = baseRate * unitCount;
    final serviceFee = subtotal * 0.1; // 10% service fee
    final total = subtotal + serviceFee;

    return {
      'baseRate': baseRate,
      'unitLabel': unitLabel,
      'unitCount': unitCount,
      'subtotal': subtotal,
      'serviceFee': serviceFee,
      'total': total,
      'isDailyRental': isDailyRental,
    };
  }
}
