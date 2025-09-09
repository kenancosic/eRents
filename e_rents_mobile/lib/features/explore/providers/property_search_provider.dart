import 'package:flutter/foundation.dart';
import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/base/api_service_extensions.dart';
import 'package:e_rents_mobile/core/models/paged_list.dart';
import 'package:e_rents_mobile/core/models/property_card_model.dart';
import 'package:e_rents_mobile/core/models/user.dart';

/// Provider for managing property search functionality
/// Handles property search, filtering, and pagination
class PropertySearchProvider extends BaseProvider {
  PropertySearchProvider(super.api);

  // ─── State ──────────────────────────────────────────────────────────────
  PagedList<PropertyCardModel>? _properties;
  PropertyCardModel? _selectedProperty;
  Map<String, dynamic> _currentFilters = {};
  int _currentPage = 1;
  int _pageSize = 10;
  bool _hasMorePages = true;

  // ─── Getters ────────────────────────────────────────────────────────────
  PagedList<PropertyCardModel>? get properties => _properties;
  PropertyCardModel? get selectedProperty => _selectedProperty;
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
      ..._translateFilters(_currentFilters),
      'Page': _currentPage,
      'PageSize': _pageSize,
    };
    
    final properties = await executeWithState(() async {
      final endpoint = '/properties${api.buildQueryString(params)}';
      return await api.getPagedAndDecode(
        endpoint,
        (json) => PropertyCardModel.fromJson(json),
        authenticated: true,
      );
    });
    
    if (properties != null) {
      _properties = properties;
      _hasMorePages = properties.hasNextPage;
      debugPrint('PropertySearchProvider: Loaded ${properties.items.length} properties');
    }
  }

  /// Apply new filters and reset pagination
  Future<void> applyFilters(Map<String, dynamic> filters) async {
    // Preserve default City filter unless explicitly overridden
    final merged = {
      ..._currentFilters,
      ...filters,
      if (!filters.containsKey('City') && _currentFilters.containsKey('City'))
        'City': _currentFilters['City'],
      if (!filters.containsKey('Status') && _currentFilters.containsKey('Status'))
        'Status': _currentFilters['Status'],
    };
    _currentFilters = merged;
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
  void selectProperty(PropertyCardModel property) {
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

  /// Apply property filters
  Future<void> applyPropertyFilters(Map<String, dynamic> filters) async {
    _currentFilters = {..._currentFilters, ...filters};
    _currentPage = 1;
    await fetchProperties();
  }

  /// Apply sort option
  Future<void> applySortOption(String? sortOption) async {
    if (sortOption != null) {
      _currentFilters = {..._currentFilters, 'sortBy': sortOption};
    } else {
      _currentFilters.remove('sortBy');
    }
    _currentPage = 1;
    await fetchProperties();
  }

  /// Initialize search defaults based on current user's city
  Future<void> initializeWithUserCity() async {
    // If city already set, just fetch
    if (_currentFilters.containsKey('City')) {
      await fetchProperties(page: 1);
      return;
    }

    final user = await executeWithState(() async {
      return await api.getAndDecode('/profile', User.fromJson, authenticated: true);
    });

    final city = user?.address?.city;
    if (city != null && city.isNotEmpty) {
      _currentFilters = {
        ..._currentFilters,
        'City': city,
        // Provide sensible defaults
        'Status': 'Available',
        'sortBy': 'createdat',
        'sortDirection': 'desc',
      };
      debugPrint('PropertySearchProvider: Initialized with user city "$city"');
    }

    _currentPage = 1;
    await fetchProperties();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────
  Map<String, dynamic> _translateFilters(Map<String, dynamic> raw) {
    final out = <String, dynamic>{};

    // Text search
    final search = raw['NameContains'] ?? raw['searchTerm'] ?? raw['name'] ?? raw['searchText'];
    if (search != null && search.toString().trim().isNotEmpty) {
      out['NameContains'] = search;
    }

    // City mapping
    final city = raw['City'] ?? raw['city'] ?? raw['cityName'];
    if (city != null && city.toString().trim().isNotEmpty) {
      out['City'] = city;
    }

    // Price range
    if (raw['MinPrice'] != null) out['MinPrice'] = raw['MinPrice'];
    if (raw['MaxPrice'] != null) out['MaxPrice'] = raw['MaxPrice'];
    if (raw['minPrice'] != null) out['MinPrice'] = raw['minPrice'];
    if (raw['maxPrice'] != null) out['MaxPrice'] = raw['maxPrice'];

    // Enums
    final status = raw['Status'] ?? raw['status'];
    if (status != null) out['Status'] = status;

    final propertyType = raw['PropertyType'] ?? raw['propertyType'];
    if (propertyType != null) out['PropertyType'] = propertyType;

    final rentingType = raw['RentingType'] ?? raw['rentalType'] ?? raw['rentingType'];
    if (rentingType != null) out['RentingType'] = rentingType;

    // Sorting
    var sortBy = raw['SortBy'] ?? raw['sortBy'];
    final sortDesc = raw['SortDirection'] ?? raw['sortDirection'] ?? raw['sortDescending'];
    if (sortBy != null) {
      final normalized = sortBy.toString().trim().toLowerCase();
      out['SortBy'] = normalized; // backend handles: price|name|createdat|updatedat
    }
    if (sortDesc != null) {
      // Accept bool or string
      String direction;
      if (sortDesc is bool) {
        direction = sortDesc ? 'desc' : 'asc';
      } else {
        final v = sortDesc.toString().toLowerCase();
        direction = (v == 'desc' || v == 'descending' || v == 'true') ? 'desc' : 'asc';
      }
      out['SortDirection'] = direction;
    }

    return out;
  }
}
