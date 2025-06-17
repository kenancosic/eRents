import 'dart:convert';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/address.dart';
import 'package:e_rents_desktop/models/renting_type.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/services/lookup_service.dart';
import 'package:e_rents_desktop/base/app_error.dart';

/// Property Service - Clean Architecture Implementation
///
/// This service handles all Property-related operations with:
/// - Clean separation of concerns
/// - Proper error handling
/// - DTO transformation
/// - Amenity and image management
/// - Statistics and availability checking
/// - Universal System pagination support
class PropertyService extends ApiService {
  final LookupService _lookupService;

  PropertyService(super.baseUrl, super.storageService, this._lookupService);

  String get endpoint => '/properties';

  // ========================================
  // CORE CRUD OPERATIONS
  // ========================================

  /// Get all properties with optional filtering
  /// Uses Universal System with pagination by default for better performance
  Future<List<Property>> getProperties({
    Map<String, String>? queryParams,
    bool noPaging = false,
  }) async {
    try {
      final params = <String, dynamic>{
        'IncludeImages': 'true',
        'IncludeAmenities': 'true',
        'IncludeOwner': 'true',
        'IncludePropertyType': 'true',
        'IncludeRentingType': 'true',
        ...?queryParams,
      };

      // Only add noPaging if explicitly requested
      if (noPaging) {
        params['noPaging'] = 'true';
      }

      final response = await get(_buildEndpoint(params), authenticated: true);
      final responseData = json.decode(response.body);

      // Handle Universal System response format
      List<dynamic> itemsJson;
      if (responseData is Map && responseData.containsKey('items')) {
        itemsJson = responseData['items'] as List<dynamic>;
      } else if (responseData is List) {
        itemsJson = responseData;
      } else {
        itemsJson = [];
      }

      return itemsJson.map((json) => Property.fromJson(json)).toList();
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Get ALL properties without pagination (use sparingly)
  Future<List<Property>> getAllProperties({
    Map<String, String>? queryParams,
  }) async {
    return await getProperties(queryParams: queryParams, noPaging: true);
  }

  /// Get paginated properties for Universal System table support
  Future<Map<String, dynamic>> getPagedProperties(
    Map<String, dynamic> params,
  ) async {
    try {
      final response = await get(_buildEndpoint(params), authenticated: true);
      return json.decode(response.body);
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Get single property by ID with full relationships
  Future<Property> getPropertyById(int propertyId) async {
    try {
      final params = {
        'IncludeImages': 'true',
        'IncludeAmenities': 'true',
        'IncludeOwner': 'true',
        'IncludePropertyType': 'true',
        'IncludeRentingType': 'true',
        'IncludeReviews': 'true',
      };

      final response = await get(
        '$endpoint/$propertyId?${_buildQueryString(params)}',
        authenticated: true,
      );
      final jsonResponse = json.decode(response.body);
      return Property.fromJson(jsonResponse);
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Create new property
  Future<Property> createProperty(Property property) async {
    try {
      final createRequest = await _buildInsertRequest(property);

      final response = await post(endpoint, createRequest, authenticated: true);
      final jsonResponse = json.decode(response.body);
      return Property.fromJson(jsonResponse);
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Update existing property
  Future<Property> updateProperty(int propertyId, Property property) async {
    try {
      final updateRequest = await _buildUpdateRequest(property);

      final response = await put(
        '$endpoint/$propertyId',
        updateRequest,
        authenticated: true,
      );
      final jsonResponse = json.decode(response.body);
      return Property.fromJson(jsonResponse);
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Delete property
  Future<void> deleteProperty(int propertyId) async {
    try {
      await delete('$endpoint/$propertyId', authenticated: true);
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  // ========================================
  // PROPERTY SEARCH & FILTERING
  // ========================================

  /// Perform comprehensive property search
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
    try {
      final searchParams = <String, String>{
        'IncludeImages': 'true',
        'IncludeAmenities': 'true',
        'IncludeOwner': 'true',
        'IncludePropertyType': 'true',
        'IncludeRentingType': 'true',
      };

      // Only disable pagination if explicitly requested
      if (noPaging) {
        searchParams['noPaging'] = 'true';
      }

      // Add search parameters
      if (name != null) searchParams['name'] = name;
      if (ownerId != null) searchParams['ownerId'] = ownerId.toString();
      if (description != null) searchParams['description'] = description;
      if (status != null) searchParams['status'] = status;
      if (currency != null) searchParams['currency'] = currency;
      if (propertyTypeId != null)
        searchParams['propertyTypeId'] = propertyTypeId.toString();
      if (rentingTypeId != null)
        searchParams['rentingTypeId'] = rentingTypeId.toString();
      if (bedrooms != null) searchParams['bedrooms'] = bedrooms.toString();
      if (bathrooms != null) searchParams['bathrooms'] = bathrooms.toString();
      if (minimumStayDays != null)
        searchParams['minimumStayDays'] = minimumStayDays.toString();
      if (minPrice != null) searchParams['minPrice'] = minPrice.toString();
      if (maxPrice != null) searchParams['maxPrice'] = maxPrice.toString();
      if (minArea != null) searchParams['minArea'] = minArea.toString();
      if (maxArea != null) searchParams['maxArea'] = maxArea.toString();
      if (availableFrom != null)
        searchParams['availableFrom'] = availableFrom.toIso8601String();
      if (availableTo != null)
        searchParams['availableTo'] = availableTo.toIso8601String();
      if (cityName != null) searchParams['cityName'] = cityName;
      if (stateName != null) searchParams['stateName'] = stateName;
      if (countryName != null) searchParams['countryName'] = countryName;
      if (amenityIds != null && amenityIds.isNotEmpty) {
        searchParams['amenityIds'] = amenityIds.join(',');
      }
      if (minRating != null) searchParams['minRating'] = minRating.toString();
      if (maxRating != null) searchParams['maxRating'] = maxRating.toString();
      if (latitude != null) searchParams['latitude'] = latitude.toString();
      if (longitude != null) searchParams['longitude'] = longitude.toString();
      if (radius != null) searchParams['radius'] = radius.toString();

      return await getProperties(queryParams: searchParams, noPaging: noPaging);
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Get available properties
  Future<List<Property>> getAvailableProperties() async {
    return await searchProperties(status: 'Available');
  }

  /// Get properties by rental type
  Future<List<Property>> getPropertiesByRentalType(String rentalType) async {
    // Map rental type name to enum and get ID
    RentingType? rentingTypeEnum;
    switch (rentalType.toLowerCase()) {
      case 'daily':
        rentingTypeEnum = RentingType.daily;
        break;
      case 'monthly':
        rentingTypeEnum = RentingType.monthly;
        break;
    }

    if (rentingTypeEnum != null) {
      final rentingTypeId = await _lookupService.getRentingTypeId(
        rentingTypeEnum,
      );
      return await searchProperties(rentingTypeId: rentingTypeId);
    }

    return await searchProperties();
  }

  /// Get properties by owner
  Future<List<Property>> getPropertiesByOwner(int ownerId) async {
    return await searchProperties(ownerId: ownerId);
  }

  // ========================================
  // AMENITY MANAGEMENT
  // ========================================

  /// Get all amenities
  Future<List<Map<String, dynamic>>> getAmenities() async {
    try {
      final response = await get('/amenities', authenticated: true);
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Add new amenity
  Future<Map<String, dynamic>> addAmenity(String amenityName) async {
    try {
      final response = await post('/amenities', {
        'amenityName': amenityName,
      }, authenticated: true);
      return json.decode(response.body);
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Update property amenities
  Future<void> updatePropertyAmenities(
    int propertyId,
    List<int> amenityIds,
  ) async {
    try {
      await put('$endpoint/$propertyId/amenities', {
        'amenityIds': amenityIds,
      }, authenticated: true);
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  // ========================================
  // IMAGE MANAGEMENT
  // ========================================

  /// Upload property image
  Future<Map<String, dynamic>> uploadPropertyImage(
    int propertyId,
    Map<String, dynamic> imageRequest,
  ) async {
    try {
      final response = await post(
        '$endpoint/$propertyId/images',
        imageRequest,
        authenticated: true,
      );
      return json.decode(response.body);
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Update property images
  Future<void> updatePropertyImages(int propertyId, List<int> imageIds) async {
    try {
      await put('$endpoint/$propertyId/images', {
        'imageIds': imageIds,
      }, authenticated: true);
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  // ========================================
  // AVAILABILITY & BUSINESS LOGIC
  // ========================================

  /// Check property availability
  Future<Map<String, dynamic>> getPropertyAvailability(
    int propertyId,
    DateTime? start,
    DateTime? end,
  ) async {
    try {
      final params = <String, String>{};
      if (start != null) params['start'] = start.toIso8601String();
      if (end != null) params['end'] = end.toIso8601String();

      final queryString =
          params.isNotEmpty ? '?${_buildQueryString(params)}' : '';
      final response = await get(
        '$endpoint/$propertyId/availability$queryString',
        authenticated: true,
      );
      return json.decode(response.body);
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Update property status
  Future<void> updatePropertyStatus(int propertyId, String status) async {
    try {
      await put('$endpoint/$propertyId/status', {
        'status': status,
      }, authenticated: true);
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  // ========================================
  // STATISTICS & ANALYTICS
  // ========================================

  /// Get popular properties
  Future<List<Property>> getPopularProperties({int limit = 10}) async {
    try {
      final response = await get(
        '$endpoint/popular?limit=$limit',
        authenticated: true,
      );
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Property.fromJson(json)).toList();
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Get property recommendations for user
  Future<List<Property>> getPropertyRecommendations(int userId) async {
    try {
      final response = await get(
        '$endpoint/recommend?userId=$userId',
        authenticated: true,
      );
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Property.fromJson(json)).toList();
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  // ========================================
  // PRIVATE HELPER METHODS
  // ========================================

  /// Build PropertyInsertRequest DTO
  Future<Map<String, dynamic>> _buildInsertRequest(Property property) async {
    return {
      'name': property.name,
      'description': property.description,
      'price': property.price,
      'currency': property.currency,
      'bedrooms': property.bedrooms > 0 ? property.bedrooms : 1,
      'bathrooms': property.bathrooms > 0 ? property.bathrooms : 1,
      'area': property.area,
      'minimumStayDays': property.minimumStayDays,
      'requiresApproval': property.requiresApproval,
      'propertyTypeId':
          property.propertyTypeId ??
          await _lookupService.getPropertyTypeId(property.type),
      'rentingTypeId':
          property.rentingTypeId ??
          await _lookupService.getRentingTypeId(property.rentingType),
      'status': property.status ?? 'Available',
      'amenityIds': property.amenityIds,
      'imageIds': property.imageIds,
      if (property.address != null)
        'address': _transformAddressForBackend(property.address!),
    };
  }

  /// Build PropertyUpdateRequest DTO
  Future<Map<String, dynamic>> _buildUpdateRequest(Property property) async {
    final request = await _buildInsertRequest(
      property,
    ); // Same structure for updates
    print(
      'PropertyService: Built update request for property ${property.propertyId} with imageIds: ${request['imageIds']}',
    );
    return request;
  }

  /// Transform address for backend compatibility
  Map<String, dynamic>? _transformAddressForBackend(Address address) {
    if (address.isEmpty) return null;
    return address.toJson();
  }

  /// Build endpoint URL with query parameters
  String _buildEndpoint(Map<String, dynamic> params) {
    final queryString = _buildQueryString(params);
    return queryString.isNotEmpty ? '$endpoint?$queryString' : endpoint;
  }

  /// Build query string from parameters
  String _buildQueryString(Map<String, dynamic> params) {
    if (params.isEmpty) return '';
    return params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');
  }
}
