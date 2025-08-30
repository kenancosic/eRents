import 'package:flutter/foundation.dart';
import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/core/base/api_service_extensions.dart';
import 'package:e_rents_mobile/core/models/paged_list.dart';

/// Provider for managing property search functionality
/// Handles property search, filtering, and pagination
class PropertySearchProvider extends BaseProvider {
  PropertySearchProvider(super.api);

  // ─── State ──────────────────────────────────────────────────────────────
  PagedList<Property>? _properties;
  Property? _selectedProperty;
  Map<String, dynamic> _currentFilters = {};
  int _currentPage = 1;
  int _pageSize = 10;
  bool _hasMorePages = true;

  // ─── Getters ────────────────────────────────────────────────────────────
  PagedList<Property>? get properties => _properties;
  Property? get selectedProperty => _selectedProperty;
  Map<String, dynamic> get currentFilters => _currentFilters;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  bool get hasMorePages => _hasMorePages;
  bool get isEmpty => _properties?.items.isEmpty ?? true;

  // ─── Public API ─────────────────────────────────────────────────────────
  
  /// Fetch properties with current filters and pagination
  Future<void> fetchProperties({int? page, int? pageSize}) async {
    _currentPage = page ?? _currentPage;
    _pageSize = pageSize ?? _pageSize;
    
    final params = {
      ..._currentFilters,
      'pageNumber': _currentPage,
      'pageSize': _pageSize,
    };
    
    final properties = await executeWithState(() async {
      final endpoint = 'properties${api.buildQueryString(params)}';
      return await api.getPagedAndDecode(endpoint, Property.fromJson, authenticated: false);
    });
    
    if (properties != null) {
      _properties = properties;
      _hasMorePages = properties.items.length == _pageSize;
      debugPrint('PropertySearchProvider: Loaded ${properties.items.length} properties');
    }
  }

  /// Apply new filters and reset pagination
  Future<void> applyFilters(Map<String, dynamic> filters) async {
    _currentFilters = filters;
    _currentPage = 1;
    await fetchProperties();
  }

  /// Load more properties for pagination
  Future<void> loadMoreProperties() async {
    if (!_hasMorePages) return;
    
    _currentPage++;
    await fetchProperties(page: _currentPage);
  }

  /// Select a property for detailed view
  void selectProperty(Property property) {
    _selectedProperty = property;
    notifyListeners();
    debugPrint('PropertySearchProvider: Selected property ${property.propertyId}');
  }

  /// Clear selected property
  void clearSelectedProperty() {
    _selectedProperty = null;
    notifyListeners();
    debugPrint('PropertySearchProvider: Cleared selected property');
  }

  /// Reset filters
  void resetFilters() {
    _currentFilters = {};
    notifyListeners();
    debugPrint('PropertySearchProvider: Reset filters');
  }
}
