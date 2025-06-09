import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/core/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

/// Service for handling pricing display and backend pricing API calls
/// All pricing calculations are done on the backend for security and consistency
class PricingService {
  final ApiService _apiService;

  PricingService(this._apiService);

  /// Get pricing from backend for a date range with detailed breakdown
  Future<Map<String, dynamic>?> getPricing({
    required int propertyId,
    required DateTime startDate,
    required DateTime endDate,
    required int numberOfGuests,
    String? promoCode,
    bool? isDailyRental,
  }) async {
    try {
      debugPrint(
          'PricingService: Getting pricing from backend for property $propertyId');

      final requestData = {
        'propertyId': propertyId,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'numberOfGuests': numberOfGuests,
        if (promoCode != null) 'promoCode': promoCode,
        if (isDailyRental != null) 'isDailyRental': isDailyRental,
      };

      final response = await _apiService.post(
        '/api/pricing/calculate',
        requestData,
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final pricingData = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('PricingService: Received pricing data from backend');
        return pricingData;
      } else {
        debugPrint(
            'PricingService: Failed to get pricing: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('PricingService.getPricing: Error $e');
      return null;
    }
  }

  /// Validate pricing parameters before making backend call
  Future<Map<String, dynamic>?> getPricingWithValidation({
    required int propertyId,
    required DateTime startDate,
    required DateTime endDate,
    required int numberOfGuests,
    String? promoCode,
    bool? isDailyRental,
  }) async {
    // Client-side validation only
    final duration = endDate.difference(startDate).inDays;
    if (duration <= 0) {
      debugPrint(
          'PricingService: Invalid date range - end date must be after start date');
      return null;
    }

    if (numberOfGuests <= 0) {
      debugPrint(
          'PricingService: Invalid guest count - must be greater than 0');
      return null;
    }

    // Call backend for actual pricing calculation
    return await getPricing(
      propertyId: propertyId,
      startDate: startDate,
      endDate: endDate,
      numberOfGuests: numberOfGuests,
      promoCode: promoCode,
      isDailyRental: isDailyRental,
    );
  }

  /// Get pricing estimate (for quick UI updates, less detailed)
  Future<double?> getPricingEstimate({
    required int propertyId,
    required DateTime startDate,
    required DateTime endDate,
    required int numberOfGuests,
  }) async {
    try {
      debugPrint('PricingService: Getting pricing estimate from backend');

      final requestData = {
        'propertyId': propertyId,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'numberOfGuests': numberOfGuests,
      };

      final response = await _apiService.post(
        '/api/pricing/estimate',
        requestData,
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['estimatedTotal'] as num?)?.toDouble();
      } else {
        debugPrint(
            'PricingService: Failed to get estimate: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('PricingService.getPricingEstimate: Error $e');
      return null;
    }
  }

  /// Format pricing for display (formatting only, no calculations)
  String formatPricingDisplay(Map<String, dynamic> pricing,
      [String currency = 'BAM']) {
    final total = pricing['total'] as double? ?? 0.0;
    final unitLabel = pricing['unitLabel'] as String? ?? 'units';
    final unitCount = pricing['unitCount'] as int? ?? 1;

    return '$currency ${total.toStringAsFixed(2)} for $unitCount $unitLabel';
  }

  /// Get pricing breakdown for UI display (formatting only)
  List<Map<String, dynamic>> getPricingBreakdown(Map<String, dynamic> pricing) {
    final breakdown = <Map<String, dynamic>>[];

    // Base cost
    final baseRate = pricing['baseRate'] as double? ?? 0.0;
    final unitCount = pricing['unitCount'] as int? ?? 1;
    final unitLabel = pricing['unitLabel'] as String? ?? 'units';
    final subtotal = pricing['subtotal'] as double? ?? 0.0;

    breakdown.add({
      'label': '$baseRate x $unitCount $unitLabel',
      'amount': subtotal,
      'type': 'base',
    });

    // Discount
    final discountAmount = pricing['discountAmount'] as double? ?? 0.0;
    if (discountAmount > 0) {
      breakdown.add({
        'label': pricing['discountLabel'] ?? 'Discount',
        'amount': -discountAmount,
        'type': 'discount',
      });
    }

    // Service fee
    final serviceFee = pricing['serviceFee'] as double? ?? 0.0;
    if (serviceFee > 0) {
      breakdown.add({
        'label': 'Service fee',
        'amount': serviceFee,
        'type': 'fee',
      });
    }

    // Additional fees from backend
    final additionalFees = pricing['additionalFees'] as List<dynamic>? ?? [];
    for (final fee in additionalFees) {
      if (fee is Map<String, dynamic>) {
        breakdown.add({
          'label': fee['label'] ?? 'Additional fee',
          'amount': (fee['amount'] as num?)?.toDouble() ?? 0.0,
          'type': 'fee',
        });
      }
    }

    return breakdown;
  }

  /// Format currency amount for display
  String formatCurrency(double amount, [String currency = 'BAM']) {
    return '$currency ${amount.toStringAsFixed(2)}';
  }

  /// Parse pricing response and extract key values for UI
  Map<String, dynamic> parsePricingForUI(Map<String, dynamic> backendPricing) {
    return {
      'total': (backendPricing['total'] as num?)?.toDouble() ?? 0.0,
      'subtotal': (backendPricing['subtotal'] as num?)?.toDouble() ?? 0.0,
      'discountAmount':
          (backendPricing['discountAmount'] as num?)?.toDouble() ?? 0.0,
      'serviceFee': (backendPricing['serviceFee'] as num?)?.toDouble() ?? 0.0,
      'unitLabel': backendPricing['unitLabel'] as String? ?? 'units',
      'unitCount': backendPricing['unitCount'] as int? ?? 1,
      'hasDiscount':
          (backendPricing['discountAmount'] as num?)?.toDouble() != null &&
              (backendPricing['discountAmount'] as num) > 0,
      'breakdown': getPricingBreakdown(backendPricing),
      'formattedTotal':
          formatCurrency((backendPricing['total'] as num?)?.toDouble() ?? 0.0),
    };
  }
}
