import '../base/base.dart';
import '../services/property_service.dart';
import '../models/property.dart';
import '../models/paged_result.dart';

/// Comprehensive Property Repository Implementation
///
/// Provides caching, error handling, and data access for properties
/// following Clean Architecture principles and the base repository pattern.
///
/// Features:
/// - Frontend-only caching with TTL strategies (10 minutes default)
/// - Property-specific business logic
/// - Universal System pagination support
/// - Advanced search and filtering capabilities
/// - Image and amenity management
/// - Statistics and analytics support
/// - Smart cache invalidation
class PropertyRepository extends BaseRepository<Property, PropertyService> {
  PropertyRepository({required super.service, required super.cacheManager});

  @override
  String get resourceName => 'properties';

  @override
  Duration get defaultCacheTtl => const Duration(minutes: 10);

  // ========================================
  // BASE REPOSITORY IMPLEMENTATION
  // ========================================

  @override
  Future<List<Property>> fetchAllFromService([
    Map<String, dynamic>? params,
  ]) async {
    // Convert Map<String, dynamic> to Map<String, String> for PropertyService
    Map<String, String>? queryParams;
    if (params != null) {
      queryParams = params.map((key, value) => MapEntry(key, value.toString()));
    }
    return await service.getProperties(queryParams: queryParams);
  }

  @override
  Future<Property> fetchByIdFromService(String id) async {
    return await service.getPropertyById(int.parse(id));
  }

  @override
  Future<Property> createInService(Property item) async {
    return await service.createProperty(item);
  }

  @override
  Future<Property> updateInService(String id, Property item) async {
    return await service.updateProperty(int.parse(id), item);
  }

  @override
  Future<void> deleteInService(String id) async {
    await service.deleteProperty(int.parse(id));
  }

  @override
  Future<bool> existsInService(String id) async {
    try {
      await service.getPropertyById(int.parse(id));
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<int> countInService([Map<String, dynamic>? params]) async {
    final items = await fetchAllFromService(params);
    return items.length;
  }

  @override
  String? extractIdFromItem(Property item) => item.propertyId.toString();

  // ========================================
  // PROPERTY-SPECIFIC BUSINESS LOGIC
  // ========================================

  /// Get available properties (cached with shorter TTL)
  Future<List<Property>> getAvailableProperties() async {
    const cacheKey = 'available_properties';

    if (enableCaching) {
      final cached = await cacheManager.get<List<Property>>(cacheKey);
      if (cached != null) return cached;
    }

    final properties = await service.getAvailableProperties();

    if (enableCaching) {
      await cacheManager.set(
        cacheKey,
        properties,
        duration: const Duration(minutes: 5), // Shorter TTL for availability
      );
    }

    return properties;
  }

  /// Get properties by rental type (cached)
  Future<List<Property>> getPropertiesByRentalType(String rentalType) async {
    final cacheKey = 'properties_by_rental_type_$rentalType';

    if (enableCaching) {
      final cached = await cacheManager.get<List<Property>>(cacheKey);
      if (cached != null) return cached;
    }

    final properties = await service.getPropertiesByRentalType(rentalType);

    if (enableCaching) {
      await cacheManager.set(cacheKey, properties, duration: defaultCacheTtl);
    }

    return properties;
  }

  /// Get properties by owner ID (cached)
  Future<List<Property>> getPropertiesByOwner(int ownerId) async {
    final cacheKey = 'properties_by_owner_$ownerId';

    if (enableCaching) {
      final cached = await cacheManager.get<List<Property>>(cacheKey);
      if (cached != null) return cached;
    }

    final properties = await service.getPropertiesByOwner(ownerId);

    if (enableCaching) {
      await cacheManager.set(cacheKey, properties, duration: defaultCacheTtl);
    }

    return properties;
  }

  /// Calculate occupancy rate from cached data
  Future<double> getOccupancyRate() async {
    const cacheKey = 'occupancy_rate';

    if (enableCaching) {
      final cached = await cacheManager.get<double>(cacheKey);
      if (cached != null) return cached;
    }

    final properties = await getAll();
    if (properties.isEmpty) return 0.0;

    final occupiedCount = properties.where((p) => p.isRented).length;
    final rate = occupiedCount / properties.length;

    if (enableCaching) {
      await cacheManager.set(
        cacheKey,
        rate,
        duration: const Duration(minutes: 15), // Longer TTL for statistics
      );
    }

    return rate;
  }

  // ========================================
  // UNIVERSAL SYSTEM PAGINATION
  // ========================================

  /// Get paginated properties using Universal System
  Future<PagedResult<Property>> getPagedProperties(
    Map<String, dynamic> params,
  ) async {
    try {
      final cacheKey = _buildSpecialCacheKey('paged', params);

      // Try cache first (shorter TTL for paginated data)
      if (enableCaching) {
        final cached = await cacheManager.get<PagedResult<Property>>(cacheKey);
        if (cached != null) return cached;
      }

      // Use Universal System pagination from service
      final pagedData = await service.getPagedProperties(params);

      // Parse Universal System PagedList<PropertyResponse>
      final List<dynamic> items = pagedData['items'] ?? [];
      final properties = items.map((json) => Property.fromJson(json)).toList();

      final pagedResult = PagedResult<Property>(
        items: properties,
        totalCount: pagedData['totalCount'] ?? 0,
        page: (pagedData['page'] ?? 1) - 1, // Convert to 0-based for frontend
        pageSize: pagedData['pageSize'] ?? 25,
      );

      // Cache the result (shorter TTL for paginated data)
      if (enableCaching) {
        await cacheManager.set(
          cacheKey,
          pagedResult,
          duration: const Duration(minutes: 2),
        );
      }

      return pagedResult;
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  // ========================================
  // ADVANCED SEARCH & FILTERING
  // ========================================

  /// Advanced property search with caching
  Future<List<Property>> searchProperties({
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
    bool noPaging = false, // Add pagination control
  }) async {
    final searchParams = <String, dynamic>{
      if (name != null) 'name': name,
      if (ownerId != null) 'ownerId': ownerId,
      if (description != null) 'description': description,
      if (status != null) 'status': status,
      if (currency != null) 'currency': currency,
      if (propertyTypeId != null) 'propertyTypeId': propertyTypeId,
      if (rentingTypeId != null) 'rentingTypeId': rentingTypeId,
      if (bedrooms != null) 'bedrooms': bedrooms,
      if (bathrooms != null) 'bathrooms': bathrooms,
      if (minimumStayDays != null) 'minimumStayDays': minimumStayDays,
      if (minPrice != null) 'minPrice': minPrice,
      if (maxPrice != null) 'maxPrice': maxPrice,
      if (minArea != null) 'minArea': minArea,
      if (maxArea != null) 'maxArea': maxArea,
      if (availableFrom != null)
        'availableFrom': availableFrom.toIso8601String(),
      if (availableTo != null) 'availableTo': availableTo.toIso8601String(),
      if (cityName != null) 'cityName': cityName,
      if (stateName != null) 'stateName': stateName,
      if (countryName != null) 'countryName': countryName,
      if (amenityIds != null && amenityIds.isNotEmpty) 'amenityIds': amenityIds,
      if (minRating != null) 'minRating': minRating,
      if (maxRating != null) 'maxRating': maxRating,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (radius != null) 'radius': radius,
    };

    final cacheKey = _buildSpecialCacheKey('search', searchParams);

    if (enableCaching) {
      final cached = await cacheManager.get<List<Property>>(cacheKey);
      if (cached != null) return cached;
    }

    final results = await service.searchProperties(
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
      noPaging: noPaging,
    );

    if (enableCaching) {
      await cacheManager.set(
        cacheKey,
        results,
        duration: const Duration(minutes: 5), // Shorter TTL for search results
      );
    }

    return results;
  }

  // ========================================
  // CACHE & PRIVATE HELPER METHODS
  // ========================================

  /// Build cache key for special operations
  String _buildSpecialCacheKey(
    String operation, [
    Map<String, dynamic>? params,
  ]) {
    final buffer = StringBuffer();
    buffer.write('${resourceName}_$operation');

    if (params != null && params.isNotEmpty) {
      final sortedParams = Map.fromEntries(
        params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
      );

      for (final entry in sortedParams.entries) {
        buffer.write('_${entry.key}:${entry.value}');
      }
    }

    return buffer.toString();
  }
}
