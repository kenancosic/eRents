import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/base/api_service_extensions.dart';

/// Property provider using the base provider architecture
/// 
/// This provides:
/// - Automatic state management (loading, error states)
/// - Built-in caching with TTL
/// - Cleaner API calls with automatic JSON decoding
/// - Consistent error handling
/// - Reduced boilerplate code
class PropertyProvider extends BaseProvider {
  PropertyProvider(super.api);

  /// Load all properties
  Future<List<Property>?> loadProperties() async {
    return executeWithState(
      () => api.getListAndDecode('/api/properties', Property.fromJson),
    );
  }

  /// Load all properties with sorting
  Future<List<Property>?> loadPropertiesSorted({String? sortBy, bool? ascending}) async {
    final queryParams = <String, dynamic>{};
    if (sortBy != null) queryParams['sortBy'] = sortBy;
    if (ascending != null) queryParams['ascending'] = ascending;
    
    final queryString = api.buildQueryString(queryParams);
    
    return executeWithState(
      () => api.getListAndDecode('/api/properties$queryString', Property.fromJson),
    );
  }

  /// Load a specific property by ID
  Future<Property?> loadProperty(int id) async {
    return executeWithState(
      () => api.getAndDecode('/api/properties/$id', Property.fromJson),
    );
  }

  /// Create a new property
  Future<Property?> createProperty(Property property) async {
    return executeWithState(() => api.postAndDecode(
      '/api/properties',
      property.toJson(),
      Property.fromJson,
    ));
  }

  /// Update an existing property
  Future<Property?> updateProperty(Property property) async {
    return executeWithState(() => api.putAndDecode(
      '/api/properties/${property.propertyId}',
      property.toJson(),
      Property.fromJson,
    ));
  }

  /// Delete a property by ID
  Future<bool> deleteProperty(int id) async {
    return await executeWithStateForSuccess(
      () => api.deleteAndConfirm('/api/properties/$id'),
    );
  }

  /// Search properties by query
  Future<List<Property>?> searchProperties(String query) async {
    return executeWithState(
      () => api.getListAndDecode(
        '/api/properties/search?q=$query',
        Property.fromJson,
      ),
    );
  }
}

/// Property form provider for handling create/edit operations
/// This separates form-specific logic from the main data provider
class PropertyFormProvider extends BaseProvider {
  PropertyFormProvider(super.api);

  /// Load a property for editing
  Future<Property?> loadProperty(int id) async {
    return executeWithState(() async {
      return await api.getAndDecode('/api/properties/$id', Property.fromJson);
    });
  }

  /// Save a property (create or update)
  Future<Property?> saveProperty(Property property) async {
    return executeWithState(() async {
      if (property.propertyId == 0) {
        // Create new property
        return await api.postAndDecode(
          '/api/properties',
          property.toJson(),
          Property.fromJson,
        );
      } else {
        // Update existing property
        return await api.putAndDecode(
          '/api/properties/${property.propertyId}',
          property.toJson(),
          Property.fromJson,
        );
      }
    });
  }
}