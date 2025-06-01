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

  Map<String, IconData> get amenityIcons => _amenityService.getAmenityIcons();

  /// Enhanced method to fetch amenities from backend with icons
  Future<Map<String, IconData>> fetchAmenitiesWithIcons() async {
    return await _amenityService.fetchAmenitiesWithIcons();
  }

  /// Adds custom amenities to the existing set
  Map<String, IconData> addCustomAmenities(List<String> customAmenities) {
    return _amenityService.addCustomAmenities(customAmenities);
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
      final newProperty = await _propertyService.createProperty(property);
      items_.add(newProperty);
    });
  }

  Future<void> updateProperty(Property property) async {
    await execute(() async {
      final updatedProperty = await _propertyService.updateProperty(
        property.id,
        property,
      );
      final index = items.indexWhere((p) => p.id == updatedProperty.id);
      if (index != -1) {
        items_[index] = updatedProperty;
      }
    });
  }

  Future<void> deleteProperty(int id) async {
    await execute(() async {
      await _propertyService.deleteProperty(id);
      items_.removeWhere((property) => property.id == id);
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
