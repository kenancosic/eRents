import 'package:flutter/material.dart';
// import 'package:e_rents_desktop/services/api_service.dart'; // No longer needed directly
import 'package:e_rents_desktop/services/mock_data_service.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/services/amenity_service.dart';
import 'package:e_rents_desktop/services/property_service.dart'; // Import PropertyService

class PropertyProvider extends BaseProvider<Property> {
  final PropertyService _propertyService; // Use PropertyService
  final AmenityService _amenityService;

  PropertyProvider(this._propertyService, this._amenityService)
    : super(_propertyService) {
    // Enable mock data for development
    enableMockData();
  }

  @override
  String get endpoint => '/properties';

  @override
  Property fromJson(Map<String, dynamic> json) => Property.fromJson(json);

  @override
  Map<String, dynamic> toJson(Property item) => item.toJson();

  @override
  List<Property> getMockItems() => MockDataService.getMockProperties();

  List<Property> get properties => items;

  Map<String, IconData> get amenityIcons => _amenityService.getAmenityIcons();

  void updateProperties(List<Property> newProperties) {
    items_ = newProperties;
    notifyListeners();
  }

  Future<void> fetchProperties({Map<String, String>? queryParams}) async {
    await execute(() async {
      if (isMockDataEnabled) {
        items_ = getMockItems();
        // TODO: If mock data needs filtering by queryParams for testing consistency
      } else {
        items_ = await _propertyService.getProperties(queryParams: queryParams);
      }
    });
  }

  Future<void> addProperty(Property property) async {
    await execute(() async {
      if (isMockDataEnabled) {
        items_.add(
          property.copyWith(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
          ),
        );
      } else {
        final newItem = await _propertyService.createProperty(property);
        items_.add(newItem);
      }
    });
  }

  Future<void> updateProperty(Property property) async {
    await execute(() async {
      if (isMockDataEnabled) {
        final index = items.indexWhere((i) => i.id == property.id);
        if (index != -1) items_[index] = property;
      } else {
        final updatedItem = await _propertyService.updateProperty(
          property.id,
          property,
        );
        final index = items.indexWhere((i) => i.id == updatedItem.id);
        if (index != -1) items_[index] = updatedItem;
      }
    });
  }

  Future<void> deleteProperty(String id) async {
    await execute(() async {
      if (isMockDataEnabled) {
        items_.removeWhere((item) => item.id == id);
      } else {
        await _propertyService.deleteProperty(id);
        items_.removeWhere((item) => item.id == id);
      }
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

  Property? getPropertyById(String id) {
    try {
      return items.firstWhere((property) => property.id == id);
    } catch (e) {
      return null;
    }
  }
}
