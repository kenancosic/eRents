import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/services/amenity_service.dart';
import 'package:e_rents_desktop/services/property_service.dart';

class PropertyProvider extends BaseProvider<Property> {
  final PropertyService _propertyService;
  final AmenityService _amenityService;

  PropertyProvider(this._propertyService, this._amenityService)
    : super(_propertyService);

  @override
  String get endpoint => '/properties';

  @override
  Property fromJson(Map<String, dynamic> json) => Property.fromJson(json);

  @override
  Map<String, dynamic> toJson(Property item) => item.toJson();

  @override
  List<Property> getMockItems() => []; // Not using mock data

  List<Property> get properties => items;

  // IMPROVED: Fetch amenities from backend with proper caching
  Future<List<AmenityItem>> getAmenities() async {
    try {
      return await _amenityService.getAmenities();
    } catch (e) {
      print('PropertyProvider: Error fetching amenities: $e');
      return [];
    }
  }

  // IMPROVED: Get amenities as a map for easy lookup by ID
  Future<Map<int, AmenityItem>> getAmenityMap() async {
    final amenities = await getAmenities();
    return {for (var amenity in amenities) amenity.id: amenity};
  }

  // IMPROVED: Get Flutter IconData for amenity
  Future<IconData> getIconForAmenity(int amenityId) async {
    final amenityMap = await getAmenityMap();
    final amenity = amenityMap[amenityId];
    if (amenity != null) {
      return _getFlutterIcon(amenity.icon);
    }
    return Icons.check_circle; // Default icon
  }

  // Convert icon name string to Flutter IconData
  IconData _getFlutterIcon(String iconName) {
    switch (iconName) {
      case 'wifi':
        return Icons.wifi;
      case 'ac_unit':
        return Icons.ac_unit;
      case 'local_parking':
        return Icons.local_parking;
      case 'thermostat':
        return Icons.thermostat;
      case 'balcony':
        return Icons.balcony;
      case 'pool':
        return Icons.pool;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'kitchen':
        return Icons.kitchen;
      case 'local_laundry_service':
        return Icons.local_laundry_service;
      case 'pets':
        return Icons.pets;
      case 'elevator':
        return Icons.elevator;
      case 'security':
        return Icons.security;
      case 'eco':
        return Icons.eco;
      case 'chair':
        return Icons.chair;
      default:
        return Icons.check_circle;
    }
  }

  // DEPRECATED: Keep for backward compatibility but use new methods
  @deprecated
  Map<String, IconData> get amenityIcons => const {};

  // DEPRECATED: Keep for backward compatibility but use new methods
  @deprecated
  Future<Map<String, IconData>> fetchAmenitiesWithIcons() async {
    final amenities = await getAmenities();
    return {
      for (var amenity in amenities)
        amenity.name: _getFlutterIcon(amenity.icon),
    };
  }

  // Clear amenity cache to force refresh from backend
  void clearAmenityCache() {
    _amenityService.clearCache();
  }

  void updateProperties(List<Property> newProperties) {
    items_ = newProperties;
    notifyListeners();
  }

  Future<void> fetchProperties({Map<String, String>? queryParams}) async {
    await execute(() async {
      items_ = await _propertyService.getProperties(queryParams: queryParams);
    });
  }

  Future<void> addProperty(Property property) async {
    await execute(() async {
      print('PropertyProvider: Adding property "${property.title}"...');
      // Backend will set OwnerId from current user context, don't include it in request
      final newProperty = await _propertyService.createProperty(property);
      print(
        'PropertyProvider: Successfully added property with ID: ${newProperty.id}',
      );
      items_.add(newProperty);
    });
  }

  Future<void> updateProperty(Property property) async {
    await execute(() async {
      print(
        'PropertyProvider: Updating property ID: ${property.id} ("${property.title}")...',
      );
      final updatedProperty = await _propertyService.updateProperty(
        property.id,
        property,
      );
      print(
        'PropertyProvider: Successfully updated property ID: ${updatedProperty.id}',
      );
      final index = items.indexWhere((p) => p.id == updatedProperty.id);
      if (index != -1) {
        items_[index] = updatedProperty;
      } else {
        print(
          'PropertyProvider: Warning - Updated property not found in local list',
        );
      }
    });
  }

  Future<void> deleteProperty(int id) async {
    await execute(() async {
      print('PropertyProvider: Deleting property ID: $id...');
      await _propertyService.deleteProperty(id);
      items_.removeWhere((property) => property.id == id);
      print('PropertyProvider: Successfully deleted property ID: $id');
    });
  }

  List<Property> getPropertiesByStatus(PropertyStatus status) {
    return items.where((property) => property.status == status).toList();
  }

  List<Property> getPropertiesByType(PropertyType type) {
    return items.where((property) => property.type == type).toList();
  }

  List<Property> getAvailableProperties() {
    return items
        .where((property) => property.status == PropertyStatus.available)
        .toList();
  }

  List<Property> getOccupiedProperties() {
    return items
        .where((property) => property.status == PropertyStatus.rented)
        .toList();
  }

  Property? getPropertyById(int id) {
    try {
      return items.firstWhere((property) => property.id == id);
    } catch (e) {
      return null;
    }
  }

  // Additional utility methods for better data management
  int get totalProperties => items.length;

  int get availablePropertiesCount =>
      items.where((p) => p.status == PropertyStatus.available).length;

  int get occupiedPropertiesCount =>
      items.where((p) => p.status == PropertyStatus.rented).length;

  double get occupancyRate {
    if (totalProperties == 0) return 0.0;
    return occupiedPropertiesCount / totalProperties;
  }

  // Filter properties by multiple criteria
  List<Property> filterProperties({
    PropertyStatus? status,
    PropertyType? type,
    String? searchQuery,
  }) {
    return items.where((property) {
      bool matchesStatus = status == null || property.status == status;
      bool matchesType = type == null || property.type == type;
      bool matchesSearch =
          searchQuery == null ||
          searchQuery.isEmpty ||
          property.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          property.description.toLowerCase().contains(
            searchQuery.toLowerCase(),
          );

      return matchesStatus && matchesType && matchesSearch;
    }).toList();
  }
}
