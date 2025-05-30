import 'package:flutter/material.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/services/secure_storage_service.dart';
import 'dart:convert';

/// Service responsible for providing amenity-related data, such as the mapping
/// between amenity names and their corresponding icons.
/// TODO: Full backend integration for amenities is pending.
class AmenityService {
  // Keep the internal source private
  final Map<String, IconData>
  _amenityIcons; // This can be kept for default icons if backend doesn\'t specify
  final ApiService _apiService;

  // Private constructor for singleton pattern or controlled instantiation
  AmenityService._(this._amenityIcons, this._apiService);

  // Static factory method to create the instance (can be adapted for DI)
  factory AmenityService.create() {
    final apiService = ApiService(
      'http://localhost:5000',
      SecureStorageService(),
    ); // Default config

    // Default amenity icons mapping - these can be used as a temporary local fallback
    // or if backend only provides names.
    final defaultAmenityIcons = <String, IconData>{
      'WiFi': Icons.wifi,
      'Parking': Icons.local_parking,
      'Pool': Icons.pool,
      'Gym': Icons.fitness_center,
      'Laundry': Icons.local_laundry_service,
      'Air Conditioning': Icons.ac_unit,
      'Heating': Icons.whatshot,
      'Kitchen': Icons.kitchen,
      'Balcony': Icons.balcony,
      'Garden': Icons.yard,
      'Pets Allowed': Icons.pets,
      'Smoking Allowed': Icons.smoking_rooms,
      'Elevator': Icons.elevator,
      'Security': Icons.security,
      'Furnished': Icons.weekend,
    };

    return AmenityService._(defaultAmenityIcons, apiService);
  }

  /// Returns an unmodifiable map of available amenity names to their icons.
  /// This may return a default set if backend integration is not complete.
  /// TODO: Confirm behavior once backend for amenities is fully integrated.
  Map<String, IconData> getAmenityIcons() {
    print(
      'AmenityService: getAmenityIcons() is using a default set. Full backend integration pending.',
    );
    return Map.unmodifiable(_amenityIcons); // Returning default icons for now
  }

  /// Fetches amenities from backend and merges with local icon mappings
  Future<Map<String, IconData>> fetchAmenitiesWithIcons() async {
    print('AmenityService: Attempting to fetch amenities from /Amenities...');
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
        print(
          'AmenityService: Successfully fetched and processed ${backendAmenities.length} amenities from backend.',
        );
        return Map.unmodifiable(combinedAmenities);
      } else {
        print(
          'AmenityService: Failed to fetch amenities from backend (status: ${response.statusCode}). Backend integration might be pending or endpoint not available. Returning empty map.',
        );
        return Map.unmodifiable({}); // Return empty map on failure
      }
    } catch (e) {
      print(
        'AmenityService: Error fetching amenities from backend: $e. Backend integration might be pending. Returning empty map.',
      );
      return Map.unmodifiable({}); // Return empty map on error
    }
  }

  /// Get all available amenities with their icons
  /// TODO: This method should be integrated with the backend. Currently returns an empty list.
  List<Map<String, dynamic>> getAllAmenities() {
    print(
      'AmenityService: getAllAmenities() called. Backend integration for this feature is pending. Returning empty list.',
    );
    return []; // Placeholder, to be replaced with backend data
  }

  /// Get icon for a specific amenity name
  /// TODO: This method relies on getAllAmenities() which is pending backend integration.
  IconData getIconForAmenity(String amenityName) {
    // Attempt to use the _amenityIcons (default set) as a temporary fallback for icon resolution
    if (_amenityIcons.containsKey(amenityName)) {
      print(
        'AmenityService: getIconForAmenity() found icon for "$amenityName" in default set.',
      );
      return _amenityIcons[amenityName]!;
    }
    print(
      'AmenityService: getIconForAmenity() - Amenity "$amenityName" not found in default set. Backend integration for dynamic amenities is pending. Returning default icon.',
    );
    return Icons.check_circle_outline; // Default icon if not found
  }

  /// Adds new amenity mappings (for dynamic amenities)
  /// TODO: This method might need to interact with backend if custom amenities are to be persisted.
  Map<String, IconData> addCustomAmenities(List<String> customAmenities) {
    print(
      'AmenityService: addCustomAmenities() called. This is a local operation. Backend integration for custom amenities pending.',
    );
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
