import 'package:flutter/material.dart';
import 'package:e_rents_desktop/services/mock_data_service.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/services/secure_storage_service.dart';
import 'dart:convert';

/// Service responsible for providing amenity-related data, such as the mapping
/// between amenity names and their corresponding icons.
class AmenityService {
  // Keep the internal source private
  final Map<String, IconData> _amenityIcons;
  final ApiService _apiService;

  // Private constructor for singleton pattern or controlled instantiation
  AmenityService._(this._amenityIcons, this._apiService);

  // Static factory method to create the instance (can be adapted for DI)
  factory AmenityService.create() {
    final mockIcons = MockDataService.getMockAmenitiesWithIcons();
    final apiService = ApiService(
      'http://localhost:5000',
      SecureStorageService(),
    ); // Default config
    return AmenityService._(Map.unmodifiable(mockIcons), apiService);
  }

  /// Returns an unmodifiable map of available amenity names to their icons.
  /// Combines backend amenities with local icon mappings.
  Map<String, IconData> getAmenityIcons() {
    return _amenityIcons;
  }

  /// Fetches amenities from backend and merges with local icon mappings
  Future<Map<String, IconData>> fetchAmenitiesWithIcons() async {
    try {
      // Try to fetch from backend
      final response = await _apiService.get('/Amenities', authenticated: true);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> backendAmenities =
            json.decode(response.body) as List<dynamic>;
        final Map<String, IconData> combinedAmenities = <String, IconData>{};

        // Add backend amenities with their corresponding icons (if available)
        for (final amenity in backendAmenities) {
          final String amenityName = amenity['amenityName'] ?? '';
          if (amenityName.isNotEmpty) {
            // Use existing icon mapping if available, otherwise use default icon
            combinedAmenities[amenityName] =
                _amenityIcons[amenityName] ?? Icons.check_circle_outline;
          }
        }

        // Add any remaining local amenities that weren't in the backend
        for (final entry in _amenityIcons.entries) {
          if (!combinedAmenities.containsKey(entry.key)) {
            combinedAmenities[entry.key] = entry.value;
          }
        }

        return Map.unmodifiable(combinedAmenities);
      } else {
        // Fallback to local amenities if backend fails
        return _amenityIcons;
      }
    } catch (e) {
      // Fallback to local amenities if there's an error
      print('Failed to fetch amenities from backend: $e');
      return _amenityIcons;
    }
  }

  /// Gets the icon for a specific amenity name.
  /// Returns null if the amenity name is not found.
  IconData? getIconForAmenity(String amenityName) {
    return _amenityIcons[amenityName];
  }

  /// Adds new amenity mappings (for dynamic amenities)
  Map<String, IconData> addCustomAmenities(List<String> customAmenities) {
    final Map<String, IconData> extendedAmenities = Map.from(_amenityIcons);

    for (final amenity in customAmenities) {
      if (!extendedAmenities.containsKey(amenity)) {
        // Use a default icon for custom amenities
        extendedAmenities[amenity] = Icons.add_circle_outline;
      }
    }

    return Map.unmodifiable(extendedAmenities);
  }
}
