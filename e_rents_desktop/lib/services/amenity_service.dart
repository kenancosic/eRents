import 'package:flutter/material.dart';
import 'package:e_rents_desktop/services/mock_data_service.dart';

/// Service responsible for providing amenity-related data, such as the mapping
/// between amenity names and their corresponding icons.
class AmenityService {
  // Keep the internal source private
  final Map<String, IconData> _amenityIcons;

  // Private constructor for singleton pattern or controlled instantiation
  AmenityService._(this._amenityIcons);

  // Static factory method to create the instance (can be adapted for DI)
  // For now, it directly uses MockDataService
  // TODO: Replace MockDataService dependency with a real data source later
  factory AmenityService.create() {
    final mockIcons = MockDataService.getMockAmenitiesWithIcons();
    return AmenityService._(
      Map.unmodifiable(mockIcons),
    ); // Make it unmodifiable
  }

  /// Returns an unmodifiable map of available amenity names to their icons.
  Map<String, IconData> getAmenityIcons() {
    return _amenityIcons;
  }

  /// Gets the icon for a specific amenity name.
  /// Returns null if the amenity name is not found.
  IconData? getIconForAmenity(String amenityName) {
    return _amenityIcons[amenityName];
  }
}
