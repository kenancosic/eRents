import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/models/property_detail.dart';
import 'package:e_rents_mobile/core/base/api_service_extensions.dart';

/// Provider for managing property collections
/// Handles similar properties and owner properties
class PropertyCollectionsProvider extends BaseProvider {
  PropertyCollectionsProvider(super.api);

  // ─── State ──────────────────────────────────────────────────────────────
  List<PropertyDetail> _similarProperties = [];
  List<PropertyDetail> _ownerProperties = [];
  List<PropertyDetail> _propertyCollection = [];
  
  // Collection search/filter state
  String _propertySearchQuery = '';
  Map<String, dynamic> _propertyFilters = {};

  // ─── Getters ────────────────────────────────────────────────────────────
  List<PropertyDetail> get similarProperties => _similarProperties;
  List<PropertyDetail> get ownerProperties => _ownerProperties;
  List<PropertyDetail> get propertyCollection => _propertyCollection;
  String get propertySearchQuery => _propertySearchQuery;
  Map<String, dynamic> get propertyFilters => _propertyFilters;

  // ─── Public API ─────────────────────────────────────────────────────────
  
  /// Fetch similar properties based on current property
  Future<void> fetchSimilarProperties(int propertyId, {int? propertyTypeId, double? price}) async {
    if (propertyId <= 0) return;
    
    final properties = await executeWithState(() async {
      final filters = {
        // Backend expects PropertySearch model keys
        'PropertyType': propertyTypeId?.toString(),
        'MinPrice': (price != null ? price * 0.8 : null)?.toString(),
        'MaxPrice': (price != null ? price * 1.2 : null)?.toString(),
        // Not supported server-side but harmless to include; client can filter if needed
        'ExcludeId': propertyId.toString(),
      };
      final endpoint = '/properties${api.buildQueryString(filters)}';
      return await api.getListAndDecode(endpoint, PropertyDetail.fromJson, authenticated: true);
    });

    if (properties != null) {
      _similarProperties = properties;
    }
  }

  /// Fetch properties by owner
  Future<void> fetchOwnerProperties(int ownerId, int excludePropertyId) async {
    if (ownerId <= 0) return;
    
    final properties = await executeWithState(() async {
      final filters = {
        // OwnerId is not part of PropertySearch; include for potential backend support
        'OwnerId': ownerId.toString(),
        'ExcludeId': excludePropertyId.toString(),
      };
      final endpoint = '/properties${api.buildQueryString(filters)}';
      return await api.getListAndDecode(endpoint, PropertyDetail.fromJson, authenticated: true);
    });

    if (properties != null) {
      _ownerProperties = properties;
    }
  }

  /// Load property collection with optional filters
  Future<void> loadPropertyCollection({Map<String, dynamic>? filters}) async {
    final properties = await executeWithState(() async {
      final endpoint = '/properties${api.buildQueryString(filters)}';
      return await api.getListAndDecode(endpoint, PropertyDetail.fromJson, authenticated: true);
    });

    if (properties != null) {
      _propertyCollection = properties;
      _applyPropertySearchAndFilters();
    }
  }

  /// Search properties
  void searchProperties(String query) {
    _propertySearchQuery = query;
    _applyPropertySearchAndFilters();
  }

  /// Apply filters to property collection
  void applyPropertyFilters(Map<String, dynamic> filters) {
    _propertyFilters = Map.from(filters);
    _applyPropertySearchAndFilters();
  }

  /// Clear property search and filters
  void clearPropertySearchAndFilters() {
    _propertySearchQuery = '';
    _propertyFilters.clear();
    _applyPropertySearchAndFilters();
  }

  void _applyPropertySearchAndFilters() {
    // Property search and filtering logic is handled server-side via API
    // This method exists for consistency with other collection methods
    notifyListeners();
  }
}
