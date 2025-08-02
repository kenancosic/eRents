import 'dart:convert';
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

  // ─── Enhanced Search Operations ─────────────────────────────────────────

  /// Search properties near a specific location
  ///
  /// [latitude] - Latitude coordinate
  /// [longitude] - Longitude coordinate
  /// [radiusKm] - Search radius in kilometers (default: 10km)
  /// [maxPrice] - Optional maximum price filter
  /// [sortBy] - Sort criteria (defaults to distance for location searches)
  Future<void> searchPropertiesNearLocation(
    double latitude,
    double longitude, {
    double radiusKm = 10.0,
    int? maxPrice,
    String? sortBy,
  }) async {
    final filters = <String, dynamic>{
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'radius': radiusKm.toString(),
      if (maxPrice != null) 'maxPrice': maxPrice.toString(),
      'includeImages': 'true',
      'includeAmenities': 'true',
      'optimizeForMobile': 'true',
    };

    debugPrint('ExploreProvider: Searching properties near location ($latitude, $longitude) within ${radiusKm}km');

    // Clear existing results for new location search
    _properties = null;
    _searchObject = PropertySearchObject(); // Reset search object
    invalidateCache('explore_properties');

    final cacheKey = generateCacheKey('explore_nearby', filters);
    
    final pagedResult = await executeWithCache(
      cacheKey,
      () => api.searchAndDecode(
        'properties/search/nearby',
        Property.fromJson,
        filters: filters,
        page: 1,
        pageSize: 20,
        sortBy: sortBy ?? 'distance',
        authenticated: false,
      ),
      cacheTtl: const Duration(minutes: 15), // Longer cache for location searches
      errorMessage: 'Failed to find nearby properties',
    );

    if (pagedResult != null) {
      _properties = pagedResult;
      debugPrint('ExploreProvider: Found ${pagedResult.items.length} properties near location');
    }
  }

  /// Get featured or recommended properties
  ///
  /// [location] - Optional location for personalized recommendations
  Future<void> fetchFeaturedProperties({String? location}) async {
    final filters = <String, dynamic>{
      'featured': 'true',
      if (location != null) 'preferredLocation': location,
      'includeImages': 'true',
      'includeAmenities': 'true',
      'optimizeForMobile': 'true',
    };

    debugPrint('ExploreProvider: Fetching featured properties');

    // Clear existing results for featured search
    _properties = null;
    _searchObject = PropertySearchObject();
    invalidateCache('explore_properties');

    final cacheKey = generateCacheKey('explore_featured', filters);
    
    final pagedResult = await executeWithCache(
      cacheKey,
      () => api.searchAndDecode(
        'properties/featured',
        Property.fromJson,
        filters: filters,
        page: 1,
        pageSize: 15, // Smaller page size for featured content
        sortBy: 'rating',
        sortOrder: 'desc',
        authenticated: false,
      ),
      cacheTtl: const Duration(hours: 1), // Longer cache for featured properties
      errorMessage: 'Failed to load featured properties',
    );

    if (pagedResult != null) {
      _properties = pagedResult;
      debugPrint('ExploreProvider: Loaded ${pagedResult.items.length} featured properties');
    }
  }

  // ─── Filter and Validation Operations ───────────────────────────────────

  /// Get available filter options for property search
  ///
  /// Returns metadata about available filters including price ranges,
  /// available cities, property types, and amenities
  Future<Map<String, dynamic>> getFilterOptions() async {
    final cacheKey = 'filter_options';
    
    return await executeWithCache(
      cacheKey,
      () async {
        try {
          debugPrint('ExploreProvider: Fetching filter options');
          
          final response = await api.get(
            'properties/filters/options',
            authenticated: false,
          );
          
          final data = json.decode(response.body) as Map<String, dynamic>;
          return _processFilterOptions(data);
        } catch (e) {
          debugPrint('ExploreProvider: Error fetching filter options - $e, using defaults');
          return _getDefaultFilterOptions();
        }
      },
      cacheTtl: const Duration(hours: 6), // Cache filter options for 6 hours
      errorMessage: 'Using default filter options',
    ) ?? _getDefaultFilterOptions();
  }

  /// Validate and sanitize search filters before applying them
  ///
  /// [filters] - Map of filter key-value pairs to validate
  ///
  /// Returns a map with validation results and sanitized values
  Map<String, dynamic> validateSearchFilters(Map<String, dynamic> filters) {
    final validatedFilters = <String, dynamic>{};
    final errors = <String>[];

    // Validate price range
    if (filters.containsKey('minPrice') && filters.containsKey('maxPrice')) {
      final minPrice = _parseDouble(filters['minPrice']);
      final maxPrice = _parseDouble(filters['maxPrice']);
      
      if (minPrice != null && maxPrice != null && minPrice > maxPrice) {
        errors.add('Minimum price cannot be greater than maximum price');
      } else {
        if (minPrice != null && minPrice >= 0) validatedFilters['minPrice'] = minPrice;
        if (maxPrice != null && maxPrice >= 0) validatedFilters['maxPrice'] = maxPrice;
      }
    } else {
      if (filters.containsKey('minPrice')) {
        final minPrice = _parseDouble(filters['minPrice']);
        if (minPrice != null && minPrice >= 0) validatedFilters['minPrice'] = minPrice;
      }
      if (filters.containsKey('maxPrice')) {
        final maxPrice = _parseDouble(filters['maxPrice']);
        if (maxPrice != null && maxPrice >= 0) validatedFilters['maxPrice'] = maxPrice;
      }
    }

    // Validate city name
    if (filters.containsKey('city')) {
      final city = filters['city']?.toString().trim();
      if (city != null && city.isNotEmpty && city.length <= 100) {
        validatedFilters['city'] = city;
      } else if (city != null && city.length > 100) {
        errors.add('City name is too long');
      }
    }

    // Validate property type
    if (filters.containsKey('propertyType')) {
      final propertyType = filters['propertyType']?.toString();
      if (propertyType != null && _isValidPropertyType(propertyType)) {
        validatedFilters['propertyType'] = propertyType;
      } else if (propertyType != null) {
        errors.add('Invalid property type: $propertyType');
      }
    }

    // Validate rental type
    if (filters.containsKey('rentalType')) {
      final rentalType = filters['rentalType']?.toString();
      if (rentalType != null && _isValidRentalType(rentalType)) {
        validatedFilters['rentalType'] = rentalType;
      } else if (rentalType != null) {
        errors.add('Invalid rental type: $rentalType');
      }
    }

    // Validate sort options
    if (filters.containsKey('sortBy')) {
      final sortBy = filters['sortBy']?.toString();
      if (sortBy != null && _isValidSortField(sortBy)) {
        validatedFilters['sortBy'] = sortBy;
      }
    }

    if (filters.containsKey('sortDescending')) {
      final sortDesc = filters['sortDescending'];
      if (sortDesc is bool) {
        validatedFilters['sortDescending'] = sortDesc;
      }
    }

    return {
      'validatedFilters': validatedFilters,
      'errors': errors,
      'isValid': errors.isEmpty,
    };
  }

  /// Apply validated filters with enhanced error handling
  void applyValidatedFilters(Map<String, dynamic> filters) {
    final validation = validateSearchFilters(filters);
    
    if (!validation['isValid']) {
      final errors = validation['errors'] as List<String>;
      setError('Filter validation failed: ${errors.join(', ')}');
      return;
    }

    final validatedFilters = validation['validatedFilters'] as Map<String, dynamic>;
    
    _searchObject = PropertySearchObject(
      cityName: validatedFilters['city'],
      minPrice: validatedFilters['minPrice'],
      maxPrice: validatedFilters['maxPrice'],
      sortBy: validatedFilters['sortBy'],
      sortDescending: validatedFilters['sortDescending'],
    );
    
    // Clear existing results and cache for new filter criteria
    _properties = null;
    invalidateCache('explore_properties');
    
    fetchProperties();
    debugPrint('ExploreProvider: Applied validated filters - $validatedFilters');
  }

  // ─── Property Detail Operations ─────────────────────────────────────────

  /// Get detailed property information by ID
  ///
  /// [property] - Property object to store the detailed information
  /// [includeReviews] - Whether to include review summary
  Future<Property?> fetchPropertyDetails(
    int propertyId, {
    bool includeReviews = true,
  }) async {
    final cacheKey = 'property_details_$propertyId';
    
    return await executeWithCache(
      cacheKey,
      () async {
        debugPrint('ExploreProvider: Fetching property details for ID: $propertyId');
        
        final queryParams = includeReviews ? '?includeReviews=true' : '';
        final property = await api.getAndDecode(
          'properties/$propertyId$queryParams',
          Property.fromJson,
          authenticated: false,
        );
        
        return _enhancePropertyData(property);
      },
      cacheTtl: const Duration(minutes: 30),
      errorMessage: 'Failed to load property details',
    );
  }

  /// Check property availability for specific dates
  ///
  /// [propertyId] - The unique identifier of the property
  /// [startDate] - Check-in date
  /// [endDate] - Check-out date
  Future<Map<String, dynamic>?> checkPropertyAvailability(
    int propertyId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await executeWithState(() async {
      debugPrint('ExploreProvider: Checking availability for property $propertyId from ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');
      
      final response = await api.post(
        'properties/$propertyId/availability',
        {
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
        },
        authenticated: false,
      );
      
      return json.decode(response.body) as Map<String, dynamic>;
    });
  }

  // ─── Private Helper Methods ────────────────────────────────────────────

  /// Process filter options response and add mobile-specific enhancements
  Map<String, dynamic> _processFilterOptions(Map<String, dynamic> data) {
    return {
      ...data,
      'mobileOptimized': true,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  /// Get default filter options when API call fails
  Map<String, dynamic> _getDefaultFilterOptions() {
    return {
      'priceRanges': [
        {'label': 'Under 500 BAM', 'maxPrice': 500},
        {'label': '500 - 1000 BAM', 'minPrice': 500, 'maxPrice': 1000},
        {'label': '1000 - 2000 BAM', 'minPrice': 1000, 'maxPrice': 2000},
        {'label': 'Over 2000 BAM', 'minPrice': 2000},
      ],
      'propertyTypes': ['apartment', 'house', 'condo', 'townhouse', 'studio'],
      'rentalTypes': ['daily', 'monthly'],
      'sortOptions': [
        {'label': 'Price: Low to High', 'value': 'price', 'order': 'asc'},
        {'label': 'Price: High to Low', 'value': 'price', 'order': 'desc'},
        {'label': 'Rating: High to Low', 'value': 'rating', 'order': 'desc'},
        {'label': 'Newest First', 'value': 'dateAdded', 'order': 'desc'},
      ],
      'isDefault': true,
      'mobileOptimized': true,
    };
  }

  /// Enhance property data with computed fields and validations
  Property _enhancePropertyData(Property property) {
    // Additional data processing can be added here
    // For example: URL validation, data sanitization, computed fields
    debugPrint('ExploreProvider: Enhanced property data for ${property.name} (ID: ${property.propertyId})');
    return property;
  }

  /// Parse string to double with null safety
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Validate property type against known values
  bool _isValidPropertyType(String propertyType) {
    const validTypes = ['apartment', 'house', 'condo', 'townhouse', 'studio'];
    return validTypes.contains(propertyType.toLowerCase());
  }

  /// Validate rental type against known values
  bool _isValidRentalType(String rentalType) {
    const validTypes = ['daily', 'monthly'];
    return validTypes.contains(rentalType.toLowerCase());
  }

  /// Validate sort field against known values
  bool _isValidSortField(String sortBy) {
    const validFields = ['price', 'rating', 'dateAdded', 'name', 'distance'];
    return validFields.contains(sortBy.toLowerCase());
  }
}
