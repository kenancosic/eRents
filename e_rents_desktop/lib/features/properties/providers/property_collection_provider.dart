import 'package:flutter/foundation.dart';
import '../../../base/base.dart';
import '../../../models/property.dart';
import '../../../models/renting_type.dart';

/// Comprehensive Property Collection Provider
///
/// Provides collection-level operations for properties with:
/// - Frontend caching (10 minutes default TTL)
/// - Advanced search and filtering capabilities
/// - Universal System pagination support
/// - Statistics and analytics
/// - Property type and rental type filtering
/// - Owner-specific property management
/// - Smart cache invalidation
class PropertyCollectionProvider extends CollectionProvider<Property> {
  PropertyCollectionProvider(PropertyRepository super.repository);

  @override
  String _getItemId(Property item) => item.propertyId.toString();

  /// Get the property repository with proper typing
  PropertyRepository get propertyRepository => repository as PropertyRepository;

  // ========================================
  // PROPERTY-SPECIFIC FILTERS & SEARCHES
  // ========================================

  /// Filter properties by availability status
  Future<void> loadAvailableProperties() async {
    await executeAsync(() async {
      final properties = await propertyRepository.getAvailableProperties();
      clear();
      for (final property in properties) {
        await addItem(property);
      }
    });
  }

  /// Filter properties by rental type
  Future<void> loadPropertiesByRentalType(String rentalType) async {
    await executeAsync(() async {
      final properties = await propertyRepository.getPropertiesByRentalType(
        rentalType,
      );
      clear();
      for (final property in properties) {
        await addItem(property);
      }
    });
  }

  /// Load properties owned by specific user
  Future<void> loadPropertiesByOwner(int ownerId) async {
    await executeAsync(() async {
      final properties = await propertyRepository.getPropertiesByOwner(ownerId);
      clear();
      for (final property in properties) {
        await addItem(property);
      }
    });
  }

  /// Load popular properties for analytics
  Future<void> loadPopularProperties({int limit = 10}) async {
    await executeAsync(() async {
      final properties = await propertyRepository.getPopularProperties(
        limit: limit,
      );
      clear();
      for (final property in properties) {
        await addItem(property);
      }
    });
  }

  /// Load property recommendations for a user
  Future<void> loadPropertyRecommendations(int userId) async {
    await executeAsync(() async {
      final recommendations = await propertyRepository
          .getPropertyRecommendations(userId);
      clear();
      for (final property in recommendations) {
        await addItem(property);
      }
    });
  }

  // ========================================
  // ADVANCED SEARCH FUNCTIONALITY
  // ========================================

  /// Perform comprehensive property search
  Future<void> searchProperties({
    String? name,
    int? ownerId,
    String? description,
    String? status,
    String? currency,
    int? propertyTypeId,
    int? rentingTypeId,
    int? bedrooms,
    int? bathrooms,
    int? minimumStayDays,
    double? minPrice,
    double? maxPrice,
    double? minArea,
    double? maxArea,
    DateTime? availableFrom,
    DateTime? availableTo,
    String? cityName,
    String? stateName,
    String? countryName,
    List<int>? amenityIds,
    double? minRating,
    double? maxRating,
    double? latitude,
    double? longitude,
    double? radius,
  }) async {
    await executeAsync(() async {
      final results = await propertyRepository.searchProperties(
        name: name,
        ownerId: ownerId,
        description: description,
        status: status,
        currency: currency,
        propertyTypeId: propertyTypeId,
        rentingTypeId: rentingTypeId,
        bedrooms: bedrooms,
        bathrooms: bathrooms,
        minimumStayDays: minimumStayDays,
        minPrice: minPrice,
        maxPrice: maxPrice,
        minArea: minArea,
        maxArea: maxArea,
        availableFrom: availableFrom,
        availableTo: availableTo,
        cityName: cityName,
        stateName: stateName,
        countryName: countryName,
        amenityIds: amenityIds,
        minRating: minRating,
        maxRating: maxRating,
        latitude: latitude,
        longitude: longitude,
        radius: radius,
      );
      clear();
      for (final property in results) {
        await addItem(property);
      }
    });
  }

  /// Search properties by price range
  Future<void> searchByPriceRange(double minPrice, double maxPrice) async {
    await searchProperties(minPrice: minPrice, maxPrice: maxPrice);
  }

  /// Search properties by location
  Future<void> searchByLocation({
    String? cityName,
    String? stateName,
    String? countryName,
    double? latitude,
    double? longitude,
    double? radius,
  }) async {
    await searchProperties(
      cityName: cityName,
      stateName: stateName,
      countryName: countryName,
      latitude: latitude,
      longitude: longitude,
      radius: radius,
    );
  }

  /// Search properties by amenities
  Future<void> searchByAmenities(List<int> amenityIds) async {
    await searchProperties(amenityIds: amenityIds);
  }

  /// Search properties by bedrooms and bathrooms
  Future<void> searchByRoomCount(int? bedrooms, int? bathrooms) async {
    await searchProperties(bedrooms: bedrooms, bathrooms: bathrooms);
  }

  // ========================================
  // UNIVERSAL SYSTEM PAGINATION
  // ========================================

  /// Current page for pagination (0-based)
  int _currentPage = 0;

  /// Page size for pagination
  int _pageSize = 25;

  /// Total count of items available
  int _totalCount = 0;

  /// Whether there are more pages available
  bool _hasNextPage = false;

  /// Whether there is a previous page available
  bool _hasPreviousPage = false;

  /// Current pagination parameters
  Map<String, dynamic> _currentParams = {};

  // Pagination getters
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  @override
  int get totalCount => _totalCount;
  bool get hasNextPage => _hasNextPage;
  bool get hasPreviousPage => _hasPreviousPage;
  int get totalPages => _totalCount > 0 ? (_totalCount / _pageSize).ceil() : 0;

  /// Load paginated properties
  Future<void> loadPaginatedProperties({
    int page = 0,
    int pageSize = 25,
    Map<String, dynamic>? params,
  }) async {
    await executeAsync(() async {
      final paginationParams = <String, dynamic>{
        'page': page + 1, // Convert to 1-based for backend
        'pageSize': pageSize,
        ...?params,
      };

      final pagedResult = await propertyRepository.getPagedProperties(
        paginationParams,
      );

      // Update pagination state
      _currentPage = page;
      _pageSize = pageSize;
      _totalCount = pagedResult.totalCount;
      _hasNextPage = pagedResult.hasNextPage;
      _hasPreviousPage = pagedResult.hasPreviousPage;
      _currentParams = paginationParams;

      // Clear and update items directly from paged result
      clear();
      for (final property in pagedResult.items) {
        await addItem(property);
      }
    });
  }

  /// Load next page
  Future<void> loadNextPage() async {
    if (!hasNextPage) return;
    await loadPaginatedProperties(
      page: _currentPage + 1,
      pageSize: _pageSize,
      params: _currentParams,
    );
  }

  /// Load previous page
  Future<void> loadPreviousPage() async {
    if (!hasPreviousPage) return;
    await loadPaginatedProperties(
      page: _currentPage - 1,
      pageSize: _pageSize,
      params: _currentParams,
    );
  }

  /// Go to specific page
  Future<void> goToPage(int page) async {
    if (page < 0 || page >= totalPages) return;
    await loadPaginatedProperties(
      page: page,
      pageSize: _pageSize,
      params: _currentParams,
    );
  }

  /// Refresh current page
  Future<void> refreshCurrentPage() async {
    await loadPaginatedProperties(
      page: _currentPage,
      pageSize: _pageSize,
      params: _currentParams,
    );
  }

  // ========================================
  // STATISTICS & ANALYTICS
  // ========================================

  /// Calculate occupancy rate
  Future<double> getOccupancyRate() async {
    return await propertyRepository.getOccupancyRate();
  }

  /// Get count of available properties
  int get availablePropertiesCount {
    return items.where((p) => p.isAvailable).length;
  }

  /// Get count of rented properties
  int get rentedPropertiesCount {
    return items.where((p) => p.isRented).length;
  }

  /// Get count of properties under maintenance
  int get maintenancePropertiesCount {
    return items.where((p) => p.inMaintenance).length;
  }

  /// Get average property price
  double get averagePrice {
    if (items.isEmpty) return 0.0;
    final totalPrice = items.fold<double>(
      0.0,
      (sum, property) => sum + property.price,
    );
    return totalPrice / items.length;
  }

  /// Get properties grouped by type
  Map<String, List<Property>> get propertiesByType {
    final grouped = <String, List<Property>>{};
    for (final property in items) {
      final typeName = property.type.displayName;
      grouped.putIfAbsent(typeName, () => []).add(property);
    }
    return grouped;
  }

  /// Get properties grouped by rental type
  Map<String, List<Property>> get propertiesByRentalType {
    final grouped = <String, List<Property>>{};
    for (final property in items) {
      final rentalTypeName = property.rentingType.displayName;
      grouped.putIfAbsent(rentalTypeName, () => []).add(property);
    }
    return grouped;
  }

  // ========================================
  // AMENITY MANAGEMENT
  // ========================================

  /// List of all available amenities
  List<Map<String, dynamic>> _amenities = [];
  bool _areAmenitiesLoading = false;
  AppError? _amenitiesError;

  List<Map<String, dynamic>> get amenities => _amenities;
  bool get areAmenitiesLoading => _areAmenitiesLoading;
  AppError? get amenitiesError => _amenitiesError;

  /// Load all available amenities
  Future<void> loadAmenities() async {
    await executeAsync(() async {
      _areAmenitiesLoading = true;
      _amenitiesError = null;
      safeNotifyListeners();

      try {
        _amenities = await propertyRepository.getAmenities();
        _amenitiesError = null;
      } catch (e, stackTrace) {
        _amenitiesError = AppError.fromException(e, stackTrace);
        rethrow; // Re-throw to be handled by executeAsync
      } finally {
        _areAmenitiesLoading = false;
        safeNotifyListeners();
      }
    });
  }

  /// Add new amenity
  Future<Map<String, dynamic>?> addAmenity(String amenityName) async {
    return await executeAsync(() async {
      try {
        final result = await propertyRepository.addAmenity(amenityName);
        await loadAmenities(); // Refresh amenities list
        return result;
      } catch (e, stackTrace) {
        _amenitiesError = AppError.fromException(e, stackTrace);
        safeNotifyListeners();
        return null;
      }
    });
  }

  // ========================================
  // FILTER HELPERS
  // ========================================

  /// Filter current items by property type
  List<Property> filterByPropertyType(PropertyType propertyType) {
    return items.where((p) => p.type == propertyType).toList();
  }

  /// Filter current items by rental type
  List<Property> filterByRentalType(RentingType rentalType) {
    return items.where((p) => p.rentingType == rentalType).toList();
  }

  /// Filter current items by status
  List<Property> filterByStatus(PropertyStatus status) {
    return items.where((p) => p.propertyStatus == status).toList();
  }

  /// Filter current items by price range
  List<Property> filterByPriceRange(double minPrice, double maxPrice) {
    return items
        .where((p) => p.price >= minPrice && p.price <= maxPrice)
        .toList();
  }

  /// Filter current items by bedroom count
  List<Property> filterByBedrooms(int bedrooms) {
    return items.where((p) => p.bedrooms == bedrooms).toList();
  }

  /// Filter current items by minimum bedroom count
  List<Property> filterByMinBedrooms(int minBedrooms) {
    return items.where((p) => p.bedrooms >= minBedrooms).toList();
  }

  /// Sort current items by price (ascending)
  List<Property> sortByPriceAscending() {
    final sorted = List<Property>.from(items);
    sorted.sort((a, b) => a.price.compareTo(b.price));
    return sorted;
  }

  /// Sort current items by price (descending)
  List<Property> sortByPriceDescending() {
    final sorted = List<Property>.from(items);
    sorted.sort((a, b) => b.price.compareTo(a.price));
    return sorted;
  }

  /// Sort current items by date added (newest first)
  List<Property> sortByDateAddedDescending() {
    final sorted = List<Property>.from(items);
    sorted.sort((a, b) {
      final dateA = a.dateAdded ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateB = b.dateAdded ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dateB.compareTo(dateA);
    });
    return sorted;
  }

  // ========================================
  // CACHE MANAGEMENT
  // ========================================

  /// Clear all property-related caches
  Future<void> clearAllCaches() async {
    await repository.clearCache();
  }

  /// Refresh current data by clearing cache and reloading
  Future<void> refreshData() async {
    await clearCacheAndRefresh();
  }
}
