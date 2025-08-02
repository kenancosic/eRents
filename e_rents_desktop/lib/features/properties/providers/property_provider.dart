import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/services/mock_property_service.dart';
import 'package:flutter/foundation.dart';

/// Simple provider class for property data management
/// This replaces the Riverpod providers with a traditional provider pattern
class PropertyProvider extends ChangeNotifier {
  final MockPropertyService _service;

  PropertyProvider() : _service = MockPropertyService();

  /// Get the mock service instance
  MockPropertyService get service => _service;

  /// Load all properties
  Future<List<Property>> loadProperties() async {
    return await _service.getAllProperties();
  }

  /// Load a specific property by ID
  Future<Property?> loadProperty(String id) async {
    return await _service.getPropertyById(id);
  }

  /// Create a new property
  Future<Property?> createProperty(Property property) async {
    return await _service.createProperty(property);
  }

  /// Update an existing property
  Future<Property?> updateProperty(Property property) async {
    return await _service.updateProperty(property);
  }

  /// Delete a property by ID
  Future<bool> deleteProperty(String id) async {
    return await _service.deleteProperty(id);
  }

  /// Search properties by query
  Future<List<Property>> searchProperties(String query) async {
    return await _service.searchProperties(query);
  }
}

/// Simple form provider class for property form management
class PropertyFormProvider {
  final MockPropertyService _service;

  PropertyFormProvider() : _service = MockPropertyService();

  /// Load a property for editing
  Future<Property?> loadProperty(String id) async {
    return await _service.getPropertyById(id);
  }

  /// Save a property (create or update)
  Future<bool> saveProperty(Property property) async {
    try {
      if (property.propertyId == 0) {
        // Create new property
        await _service.createProperty(property);
      } else {
        // Update existing property
        await _service.updateProperty(property);
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}