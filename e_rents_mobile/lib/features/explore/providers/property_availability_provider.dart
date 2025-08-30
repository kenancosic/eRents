import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/base/api_service_extensions.dart';

/// Provider for managing property availability checks
/// Handles availability checking logic for properties in explore feature
class PropertyAvailabilityProvider extends BaseProvider {
  PropertyAvailabilityProvider(super.api);

  // ─── State ──────────────────────────────────────────────────────────────
  Map<int, bool> _availabilityCache = {};

  // ─── Getters ────────────────────────────────────────────────────────────
  Map<int, bool> get availabilityCache => _availabilityCache;

  // ─── Public API ─────────────────────────────────────────────────────────
  
  /// Check if a property is available for given dates
  Future<bool?> checkAvailability(int propertyId, DateTime startDate, DateTime endDate) async {
    final result = await executeWithState(() async {
      final queryParams = {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      };
      
      // Build URL with query parameters
      final queryString = api.buildQueryString(queryParams);
      final response = await api.get('properties/$propertyId/availability$queryString', authenticated: false);
      
      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final isAvailable = body['isAvailable'] as bool?;
        _availabilityCache[propertyId] = isAvailable ?? false;
        return isAvailable;
      }
      
      return null;
    });
    
    debugPrint('PropertyAvailabilityProvider: Checked availability for property $propertyId: ${result ?? 'unknown'}');
    return result;
  }

  /// Get cached availability for a property
  bool? getCachedAvailability(int propertyId) {
    return _availabilityCache[propertyId];
  }

  /// Clear availability cache
  void clearAvailabilityCache() {
    _availabilityCache.clear();
    notifyListeners();
    debugPrint('PropertyAvailabilityProvider: Cleared availability cache');
  }
}
