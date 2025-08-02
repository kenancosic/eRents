import 'dart:typed_data';

import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/models/paged_result.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/base/api_service_extensions.dart';

/// Refactored Properties Provider using the new base architecture.
///
/// This provider consolidates all property-related functionality and leverages
/// [BaseProvider] for state management, caching, and simplified API calls.
class PropertiesProvider extends BaseProvider {
  PropertiesProvider(super.api);

  // ─── Properties State ──────────────────────────────────────────────────
  List<Property> _properties = [];
  List<Property> get properties => _properties;

  PagedResult<Property>? _pagedResult;
  PagedResult<Property>? get pagedResult => _pagedResult;

  Property? _selectedProperty;
  Property? get selectedProperty => _selectedProperty;

  // ─── Reviews State ─────────────────────────────────────────────────────

  // ─── Public API ────────────────────────────────────────────────────────

  /// Get paginated properties with filtering.
  Future<void> getPagedProperties({Map<String, dynamic>? params}) async {
    final result = await executeWithState<PagedResult<Property>>(() async {
      return await api.getPagedAndDecode(
        'api/Properties${api.buildQueryString(params)}',
        Property.fromJson,
        authenticated: true,
      );
    });
    
    if (result != null) {
      _pagedResult = result;
      _properties = result.items;
      notifyListeners();
    }
  }

  /// Get property by ID, using cache first.
  Future<void> getPropertyById(String propertyId, {bool forceRefresh = false}) async {
    final result = await executeWithCache<Property>(
      'property_$propertyId',
      () => api.getAndDecode('api/Properties/$propertyId', Property.fromJson, authenticated: true),
    );
    
    if (result != null) {
      _selectedProperty = result;
      notifyListeners();
    }
  }

  /// Save property (create or update).
  Future<bool> saveProperty(
    Property property, {
    List<Uint8List>? newImageData,
    List<String>? newImageFileNames,
    List<int>? existingImageIds,
  }) async {
    // For academic simplification, imagine this successfully calls an endpoint
    // without complex file uploads. Actual upload logic would be in ApiService
    // or a dedicated service.
    // Replace with actual API call if backend supports it without multipart:
    return await executeWithStateForSuccess(() async {
      final endpoint = property.propertyId == 0 ? 'api/Properties' : 'api/Properties/${property.propertyId}';
      if (property.propertyId == 0) {
        await api.postJson(endpoint, property.toJson(), authenticated: true);
      } else {
        await api.putJson(endpoint, property.toJson(), authenticated: true);
      }
      invalidateCache('property_${property.propertyId}'); // Invalidate cache for this property
      getPagedProperties(); // Refresh property list
    });
  }

  /// Delete property.
  Future<bool> deleteProperty(String propertyId) async {
    final result = await executeWithState<bool>(() async {
      return await api.deleteAndConfirm('api/Properties/$propertyId', authenticated: true);
    });
    
    if (result == true) {
      _properties.removeWhere((p) => p.propertyId == propertyId);
      if (_selectedProperty?.propertyId == propertyId) {
        _selectedProperty = null;
      }
      invalidateCache('property_$propertyId');
      notifyListeners();
      return true;
    }
    return false;
  }

}
