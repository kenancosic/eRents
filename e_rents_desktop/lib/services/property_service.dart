import 'dart:convert';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/address.dart';
import 'package:e_rents_desktop/models/renting_type.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/services/lookup_service.dart';

/// ✅ UNIVERSAL SYSTEM PROPERTY SERVICE - Full Universal System Integration
///
/// This service provides property management using Universal System:
/// - Universal System pagination as default
/// - Non-paginated requests using noPaging=true parameter
/// - CRUD operations with dynamic lookup integration
/// - Landlord-specific property access and filtering
class PropertyService extends ApiService {
  final LookupService _lookupService;

  PropertyService(super.baseUrl, super.storageService, this._lookupService);

  String get endpoint => '/properties';

  /// ✅ UNIVERSAL SYSTEM: Get paginated properties with full filtering support
  /// DEFAULT METHOD - Uses pagination by default
  /// Matches: GET /properties?page=1&pageSize=10&sortBy=Price&sortDesc=false
  Future<Map<String, dynamic>> getPagedProperties(
    Map<String, dynamic> params,
  ) async {
    try {
      // Build query string from params
      String queryString = '';
      if (params.isNotEmpty) {
        queryString =
            '?' + params.entries.map((e) => '${e.key}=${e.value}').join('&');
      }

      final response = await get('$endpoint$queryString', authenticated: true);
      return json.decode(response.body);
    } catch (e) {
      throw Exception('Failed to fetch paginated properties: $e');
    }
  }

  /// ✅ UNIVERSAL SYSTEM: Get all properties without pagination
  /// Uses noPaging=true for cases where all data is needed
  Future<List<Property>> getProperties({
    Map<String, String>? queryParams,
  }) async {
    try {
      // Convert to Map<String, dynamic> and add noPaging
      final params = <String, dynamic>{'noPaging': 'true'};
      if (queryParams != null) {
        params.addAll(queryParams);
      }

      String queryString = '';
      if (params.isNotEmpty) {
        queryString =
            '?' + params.entries.map((e) => '${e.key}=${e.value}').join('&');
      }

      final response = await get('$endpoint$queryString', authenticated: true);
      final responseData = json.decode(response.body);

      // Handle Universal System response format
      List<dynamic> itemsJson;
      if (responseData is Map && responseData.containsKey('items')) {
        // Universal System response with noPaging=true
        itemsJson = responseData['items'] as List<dynamic>;
      } else if (responseData is List) {
        // Direct list response (fallback)
        itemsJson = responseData;
      } else {
        itemsJson = [];
      }

      return itemsJson.map((json) => Property.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch properties: $e');
    }
  }

  /// ✅ UNIVERSAL SYSTEM: Get property count
  /// Uses Universal System count or extracts from paged response
  Future<int> getPropertyCount([Map<String, dynamic>? params]) async {
    try {
      final queryParams = <String, dynamic>{
        'pageSize': 1, // Minimal page size, we only need count
        ...?params,
      };

      String queryString = '';
      if (queryParams.isNotEmpty) {
        queryString =
            '?' +
            queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
      }

      final response = await get('$endpoint$queryString', authenticated: true);
      final responseData = json.decode(response.body);
      return responseData['totalCount'] ?? 0;
    } catch (e) {
      throw Exception('Failed to get property count: $e');
    }
  }

  /// ✅ CRUD: Get single property by ID
  /// Matches: GET /properties/{id}
  Future<Property> getPropertyById(int propertyId) async {
    final response = await get('$endpoint/$propertyId', authenticated: true);
    final Map<String, dynamic> jsonResponse = json.decode(response.body);
    return Property.fromJson(jsonResponse);
  }

  /// ✅ CRUD: Create property
  /// Matches: POST /properties
  Future<Property> createProperty(Property property) async {
    final createRequest = await _propertyToInsertRequest(property);
    print(
      'PropertyService: Creating property with data: ${json.encode(createRequest)}',
    );

    final response = await post(endpoint, createRequest, authenticated: true);
    final Map<String, dynamic> jsonResponse = json.decode(response.body);
    return Property.fromJson(jsonResponse);
  }

  /// ✅ CRUD: Update property
  /// Matches: PUT /properties/{id}
  Future<Property> updateProperty(int propertyId, Property propertyData) async {
    final updateRequest = await _propertyToUpdateRequest(propertyData);
    print(
      'PropertyService: Updating property $propertyId with data: ${json.encode(updateRequest)}',
    );

    final response = await put(
      '$endpoint/$propertyId',
      updateRequest,
      authenticated: true,
    );
    final Map<String, dynamic> jsonResponse = json.decode(response.body);
    return Property.fromJson(jsonResponse);
  }

  /// ✅ CRUD: Delete property
  /// Matches: DELETE /properties/{id}
  Future<void> deleteProperty(int propertyId) async {
    await delete('$endpoint/$propertyId', authenticated: true);
  }

  // Helper method to convert Property to PropertyInsertRequest DTO
  Future<Map<String, dynamic>> _propertyToInsertRequest(
    Property property,
  ) async {
    final request = {
      'name': property.name,
      'description': property.description,
      'price': property.price,
      'currency': property.currency,
      'bedrooms': property.bedrooms > 0 ? property.bedrooms : 1,
      'bathrooms': property.bathrooms > 0 ? property.bathrooms : 1,
      'area': property.area,
      'dailyRate': property.dailyRate,
      'minimumStayDays': property.minimumStayDays,
      // ✅ IMPROVED: Use LookupService for dynamic ID mapping
      'propertyTypeId': await _lookupService.getPropertyTypeId(property.type),
      'rentingTypeId': await _lookupService.getRentingTypeId(
        property.rentingType,
      ),
      'status': await _getPropertyStatusString(property.status),
      // IMPROVED: Send amenityIds for better performance and type safety
      'amenityIds': property.amenityIds ?? [],
      // Extract image IDs from the images list
      'imageIds': property.imageIds,
    };

    // Only add address if it has meaningful data
    if (property.address != null) {
      final addressJson = _transformAddressForBackend(property.address!);
      if (addressJson != null) {
        request['address'] = addressJson;
      }
    }

    return request;
  }

  // Helper method to convert Property to PropertyUpdateRequest DTO
  Future<Map<String, dynamic>> _propertyToUpdateRequest(
    Property property,
  ) async {
    final request = {
      'name': property.name,
      'description': property.description,
      'price': property.price,
      'currency': property.currency,
      'bedrooms': property.bedrooms > 0 ? property.bedrooms : 1,
      'bathrooms': property.bathrooms > 0 ? property.bathrooms : 1,
      'area': property.area,
      'dailyRate': property.dailyRate,
      'minimumStayDays': property.minimumStayDays,
      // ✅ IMPROVED: Use LookupService for dynamic ID mapping
      'propertyTypeId': await _lookupService.getPropertyTypeId(property.type),
      'rentingTypeId': await _lookupService.getRentingTypeId(
        property.rentingType,
      ),
      'status': await _getPropertyStatusString(property.status),
      // IMPROVED: Send amenityIds for better performance and type safety
      'amenityIds': property.amenityIds ?? [],
      // Extract image IDs from the images list
      'imageIds': property.imageIds,
    };

    // Only add address if it has meaningful data
    if (property.address != null) {
      final addressJson = _transformAddressForBackend(property.address!);
      if (addressJson != null) {
        request['address'] = addressJson;
      }
    }

    return request;
  }

  // Transform address to match backend DTO structure
  Map<String, dynamic>? _transformAddressForBackend(Address address) {
    // Check if address has meaningful data
    if (address.isEmpty) {
      return null;
    }

    // Use the unified Address structure that aligns with backend AddressRequest
    final addressJson = address.toJson();

    print(
      'PropertyService: Transformed address for backend: ${json.encode(addressJson)}',
    );
    return addressJson;
  }

  // ✅ REPLACED: Use LookupService for dynamic mapping instead of hardcoded values
  // Property status to backend string mapping (using lookup service internally)
  Future<String> _getPropertyStatusString(PropertyStatus status) async {
    final lookupData = await _lookupService.getAllLookupData();
    final id = await _lookupService.getPropertyStatusId(status);
    final item = lookupData.getPropertyStatusById(id);
    return item?.name ?? 'Available'; // fallback to Available if not found
  }
}
