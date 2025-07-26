import 'package:e_rents_mobile/core/models/paged_list.dart';
import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/core/models/property_search_object.dart';
import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/base/api_service_extensions.dart';
import 'package:e_rents_mobile/core/services/api_service.dart';
import 'package:flutter/material.dart';

/// Property exploration provider for searching and filtering properties
/// Migrated from ChangeNotifier to BaseProvider for consistent state management
/// Uses built-in caching, error handling, pagination, and type-safe API calls
class ExploreProvider extends BaseProvider {
  ExploreProvider(ApiService api) : super(api);

  // ─── State ──────────────────────────────────────────────────────────────
  // Use inherited loading/error state from BaseProvider
  // isLoading, error, hasError are available from BaseProvider

  PagedList<Property>? _properties;
  PropertySearchObject _searchObject = PropertySearchObject();

  // ─── Getters ────────────────────────────────────────────────────────────
  PagedList<Property>? get properties => _properties;
  PropertySearchObject get searchObject => _searchObject;
  
  // Convenience getters for UI
  List<Property> get propertyList => _properties?.items ?? [];
  bool get hasProperties => _properties?.items.isNotEmpty ?? false;
  bool get hasMorePages => _properties?.hasNextPage ?? false;
  int get totalCount => _properties?.totalCount ?? 0;
  int get currentPage => _searchObject.page;

  // ─── Public API ─────────────────────────────────────────────────────────

  /// Fetch properties with built-in caching and pagination support
  /// Uses BaseProvider's executeWithCache for 10-minute caching
  Future<void> fetchProperties({bool loadMore = false}) async {
    // Skip if already loading or no more pages available for load more
    if (isLoading) return;
    
    if (loadMore) {
      if (_properties == null || !_properties!.hasNextPage) {
        return;
      }
      _searchObject.page++;
    } else {
      _searchObject.page = 1;
    }

    // Generate cache key based on search filters
    final searchFilters = _searchObject.toQueryParameters();
    final cacheKey = generateCacheKey('explore_properties', searchFilters);
    
    final pagedResult = await executeWithCache(
      cacheKey,
      () => api.searchAndDecode(
        'properties/search',
        Property.fromJson,
        filters: searchFilters,
        page: _searchObject.page,
      ),
      cacheTtl: const Duration(minutes: 10),
      errorMessage: 'Failed to load properties',
    );

    if (pagedResult != null) {
      if (loadMore && _properties != null) {
        // Append to existing results for load more
        _properties = PagedList(
          items: [..._properties!.items, ...pagedResult.items],
          page: pagedResult.page,
          pageSize: pagedResult.pageSize,
          totalCount: pagedResult.totalCount,
        );
      } else {
        // Replace results for new search/refresh
        _properties = pagedResult;
      }
      
      debugPrint('ExploreProvider: Loaded ${pagedResult.items.length} properties (page ${pagedResult.page})');
    }
  }

  /// Apply filters to property search and refresh results
  /// Invalidates cache to ensure fresh results with new filters
  void applyFilters(Map<String, dynamic> filters) {
    _searchObject = PropertySearchObject(
      cityName: filters['city'],
      minPrice: filters['minPrice'],
      maxPrice: filters['maxPrice'],
      sortBy: filters['sortBy'],
      sortDescending: filters['sortDescending'],
    );
    
    // Clear existing results and cache for new filter criteria
    _properties = null;
    invalidateCache('explore_properties');
    
    fetchProperties();
    debugPrint('ExploreProvider: Applied filters - city: ${filters['city']}, price: ${filters['minPrice']}-${filters['maxPrice']}');
  }

  /// Search properties by query string
  /// Clears previous results and starts fresh search
  void search(String query) {
    _searchObject = PropertySearchObject(cityName: query);
    
    // Clear existing results and cache for new search
    _properties = null;
    invalidateCache('explore_properties');
    
    fetchProperties();
    debugPrint('ExploreProvider: Searching for properties with query: "$query"');
  }

  /// Load more properties (pagination)
  /// Uses existing search criteria to load next page
  Future<void> loadMore() async {
    if (hasMorePages && !isLoading) {
      await fetchProperties(loadMore: true);
    }
  }

  /// Refresh current search results
  /// Forces cache invalidation and reloads current search
  Future<void> refresh() async {
    invalidateCache('explore_properties');
    _searchObject.page = 1; // Reset to first page
    _properties = null; // Clear existing results
    await fetchProperties();
    debugPrint('ExploreProvider: Refreshed property search results');
  }

  /// Clear all search criteria and results
  void clearSearch() {
    _searchObject = PropertySearchObject();
    _properties = null;
    invalidateCache();
    notifyListeners();
    debugPrint('ExploreProvider: Cleared search criteria and results');
  }

  /// Update search object with new criteria without immediately fetching
  /// Useful for building complex search criteria before executing
  void updateSearchCriteria({
    String? cityName,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    bool? sortDescending,
  }) {
    _searchObject = PropertySearchObject(
      cityName: cityName ?? _searchObject.cityName,
      minPrice: minPrice ?? _searchObject.minPrice,
      maxPrice: maxPrice ?? _searchObject.maxPrice,
      sortBy: sortBy ?? _searchObject.sortBy,
      sortDescending: sortDescending ?? _searchObject.sortDescending,
    );
    
    debugPrint('ExploreProvider: Updated search criteria');
  }

  /// Get property by ID from current results
  Property? getPropertyById(int propertyId) {
    return propertyList.cast<Property?>().firstWhere(
      (property) => property?.propertyId == propertyId,
      orElse: () => null,
    );
  }
}
