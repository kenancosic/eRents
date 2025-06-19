import 'dart:convert';
import 'dart:typed_data';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/address.dart';
import 'package:e_rents_desktop/models/renting_type.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/services/lookup_service.dart';
import 'package:e_rents_desktop/base/app_error.dart';
import 'package:http/http.dart' as http;

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

  /// ✅ Creates a new property with optional images in a single transactional request.
  Future<Property> createProperty(
    Property property, {
    List<Uint8List>? newImageData,
    List<String>? newImageFileNames,
  }) async {
    try {
      final fields = await _buildPropertyFields(property);
      final files = _buildImageFiles(newImageData, newImageFileNames);

      final response = await multipartRequest(
        endpoint,
        'POST',
        fields: fields,
        files: files,
      );

      return Property.fromJson(json.decode(response.body));
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// ✅ Updates an existing property with optional new and/or existing images in a single transactional request.
  Future<Property> updateProperty(
    int propertyId,
    Property property, {
    List<int>? existingImageIds,
    List<Uint8List>? newImageData,
    List<String>? newImageFileNames,
  }) async {
    try {
      final fields = await _buildPropertyFields(property);

      // Add existing image IDs for the update
      if (existingImageIds != null) {
        for (int i = 0; i < existingImageIds.length; i++) {
          fields['ExistingImageIds[$i]'] = existingImageIds[i].toString();
        }
      }

      final files = _buildImageFiles(newImageData, newImageFileNames);

      final response = await multipartRequest(
        '$endpoint/$propertyId',
        'PUT',
        fields: fields,
        files: files,
      );

      return Property.fromJson(json.decode(response.body));
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
  // PRIVATE HELPER METHODS
  // ========================================

  /// Helper to build the list of MultipartFile objects from image data.
  List<http.MultipartFile> _buildImageFiles(
    List<Uint8List>? imageData,
    List<String>? imageFileNames,
  ) {
    final files = <http.MultipartFile>[];
    if (imageData != null && imageData.isNotEmpty) {
      for (int i = 0; i < imageData.length; i++) {
        final fileName =
            (imageFileNames != null && i < imageFileNames.length)
                ? imageFileNames[i]
                : 'image_$i.jpg';

        files.add(
          http.MultipartFile.fromBytes(
            'NewImages',
            imageData[i],
            filename: fileName,
          ),
        );
      }
    }
    return files;
  }

  /// Builds a map of property fields for the multipart request.
  Future<Map<String, String>> _buildPropertyFields(Property property) async {
    final fields = <String, String>{};

    // Add basic property fields
    if (property.name.isNotEmpty) fields['Name'] = property.name;
    fields['Price'] = property.price.toString();
    fields['Currency'] = property.currency;

    if (property.description.isNotEmpty) {
      fields['Description'] = property.description;
    }

    fields['Bedrooms'] = property.bedrooms.toString();
    fields['Bathrooms'] = property.bathrooms.toString();

    if (property.area > 0) {
      fields['Area'] = property.area.toString();
    }

    if (property.minimumStayDays != null && property.minimumStayDays! > 0) {
      fields['MinimumStayDays'] = property.minimumStayDays.toString();
    }

    if (property.status != null && property.status!.isNotEmpty) {
      fields['Status'] = property.status!;
    }

    // Add lookup IDs
    if (property.propertyTypeId != null) {
      fields['PropertyTypeId'] = property.propertyTypeId.toString();
    } else {
      final propertyTypeId = await _lookupService.getPropertyTypeId(
        property.type,
      );
      fields['PropertyTypeId'] = propertyTypeId.toString();
    }

    if (property.rentingTypeId != null) {
      fields['RentingTypeId'] = property.rentingTypeId.toString();
    } else {
      final rentingTypeId = await _lookupService.getRentingTypeId(
        property.rentingType,
      );
      fields['RentingTypeId'] = rentingTypeId.toString();
    }

    // Add address if present
    if (property.address != null && !property.address!.isEmpty) {
      final address = property.address!;
      if (address.streetLine1?.isNotEmpty == true) {
        fields['Address.StreetLine1'] = address.streetLine1!;
      }
      if (address.streetLine2?.isNotEmpty == true) {
        fields['Address.StreetLine2'] = address.streetLine2!;
      }
      if (address.city?.isNotEmpty == true) {
        fields['Address.City'] = address.city!;
      }
      if (address.state?.isNotEmpty == true) {
        fields['Address.State'] = address.state!;
      }
      if (address.country?.isNotEmpty == true) {
        fields['Address.Country'] = address.country!;
      }
      if (address.postalCode?.isNotEmpty == true) {
        fields['Address.PostalCode'] = address.postalCode!;
      }
      if (address.latitude != null) {
        fields['Address.Latitude'] = address.latitude.toString();
      }
      if (address.longitude != null) {
        fields['Address.Longitude'] = address.longitude.toString();
      }
    }

    // Add amenity IDs
    if (property.amenityIds.isNotEmpty) {
      for (int i = 0; i < property.amenityIds.length; i++) {
        fields['AmenityIds[$i]'] = property.amenityIds[i].toString();
      }
    }

    // NOTE: ExistingImageIds are handled in the updateProperty method directly.
    return fields;
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
