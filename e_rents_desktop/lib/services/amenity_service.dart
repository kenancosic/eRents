import 'package:e_rents_desktop/services/api_service.dart';
import 'dart:convert';

/// Service responsible for providing amenity-related data, such as the mapping
/// between amenity names and their corresponding icons.
/// TODO: Full backend integration for amenities is pending.
class AmenityService extends ApiService {
  AmenityService(super.baseUrl, super.storageService);

  // Cached amenities to avoid repeated API calls
  static List<AmenityItem>? _cachedAmenities;

  Future<List<AmenityItem>> getAmenities() async {
    // Return cached amenities if available
    if (_cachedAmenities != null) {
      return _cachedAmenities!;
    }

    try {
      final response = await get('/amenities', authenticated: true);
      final List<dynamic> jsonResponse = json.decode(response.body);

      _cachedAmenities =
          jsonResponse.map((json) => AmenityItem.fromJson(json)).toList();

      print(
        'AmenityService: Fetched ${_cachedAmenities!.length} amenities from backend',
      );
      return _cachedAmenities!;
    } catch (e) {
      print('AmenityService: Error fetching amenities: $e');
      // Return predefined amenities as fallback
      return _getPredefinedAmenities();
    }
  }

  // Clear cache to force refresh from backend
  void clearCache() {
    _cachedAmenities = null;
  }

  // Predefined amenities with icons as fallback
  List<AmenityItem> _getPredefinedAmenities() {
    return [
      AmenityItem(id: 1, name: 'Wi-Fi', icon: 'wifi'),
      AmenityItem(id: 2, name: 'Air Conditioning', icon: 'ac_unit'),
      AmenityItem(id: 3, name: 'Parking', icon: 'local_parking'),
      AmenityItem(id: 4, name: 'Heating', icon: 'thermostat'),
      AmenityItem(id: 5, name: 'Balcony', icon: 'balcony'),
      AmenityItem(id: 6, name: 'Pool', icon: 'pool'),
      AmenityItem(id: 7, name: 'Gym', icon: 'fitness_center'),
      AmenityItem(id: 8, name: 'Kitchen', icon: 'kitchen'),
      AmenityItem(id: 9, name: 'Laundry', icon: 'local_laundry_service'),
      AmenityItem(id: 10, name: 'Pet Friendly', icon: 'pets'),
    ];
  }
}

class AmenityItem {
  final int id;
  final String name;
  final String icon; // Icon name for Flutter Icons

  AmenityItem({required this.id, required this.name, required this.icon});

  factory AmenityItem.fromJson(Map<String, dynamic> json) {
    final amenityName = json['amenityName'] as String;
    return AmenityItem(
      id: json['amenityId'] as int,
      name: amenityName,
      icon: _getIconForAmenity(amenityName),
    );
  }

  Map<String, dynamic> toJson() {
    return {'amenityId': id, 'amenityName': name};
  }

  // Map amenity names to appropriate Flutter icon names
  static String _getIconForAmenity(String amenityName) {
    switch (amenityName.toLowerCase()) {
      case 'wi-fi':
      case 'wifi':
        return 'wifi';
      case 'air conditioning':
      case 'ac':
        return 'ac_unit';
      case 'parking':
        return 'local_parking';
      case 'heating':
        return 'thermostat';
      case 'balcony':
        return 'balcony';
      case 'pool':
        return 'pool';
      case 'gym':
      case 'fitness':
        return 'fitness_center';
      case 'kitchen':
        return 'kitchen';
      case 'laundry':
        return 'local_laundry_service';
      case 'pet friendly':
      case 'pets':
        return 'pets';
      case 'elevator':
        return 'elevator';
      case 'security':
        return 'security';
      case 'garden':
        return 'eco';
      case 'furnished':
        return 'chair';
      default:
        return 'check_circle'; // Default icon
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AmenityItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'AmenityItem(id: $id, name: $name, icon: $icon)';
}
