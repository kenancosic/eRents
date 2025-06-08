import 'dart:convert';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/address.dart';
import 'package:e_rents_desktop/models/renting_type.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/services/lookup_service.dart';

class PropertyService extends ApiService {
  final LookupService _lookupService;

  PropertyService(super.baseUrl, super.storageService, this._lookupService);

  Future<List<Property>> getProperties({
    Map<String, String>? queryParams,
  }) async {
    String endpoint = '/properties';
    if (queryParams != null && queryParams.isNotEmpty) {
      endpoint += '?${Uri(queryParameters: queryParams).query}';
    }
    final response = await get(endpoint, authenticated: true);
    final Map<String, dynamic> jsonResponse = json.decode(response.body);

    // Handle paginated response from Universal System
    List<dynamic> itemsJson;
    if (jsonResponse.containsKey('items')) {
      // Paginated response
      itemsJson = jsonResponse['items'] as List<dynamic>;
    } else {
      // Direct list response (fallback for non-paginated)
      itemsJson = jsonResponse as List<dynamic>;
    }

    return itemsJson.map((json) => Property.fromJson(json)).toList();
  }

  Future<Property> getPropertyById(int propertyId) async {
    final response = await get('/properties/$propertyId', authenticated: true);
    final Map<String, dynamic> jsonResponse = json.decode(response.body);
    return Property.fromJson(jsonResponse);
  }

  Future<Property> createProperty(Property property) async {
    final createRequest = await _propertyToInsertRequest(property);
    print(
      'PropertyService: Creating property with data: ${json.encode(createRequest)}',
    );

    final response = await post(
      '/properties',
      createRequest,
      authenticated: true,
    );
    final Map<String, dynamic> jsonResponse = json.decode(response.body);
    return Property.fromJson(jsonResponse);
  }

  Future<Property> updateProperty(int propertyId, Property propertyData) async {
    final updateRequest = await _propertyToUpdateRequest(propertyData);
    print(
      'PropertyService: Updating property $propertyId with data: ${json.encode(updateRequest)}',
    );

    final response = await put(
      '/properties/$propertyId',
      updateRequest,
      authenticated: true,
    );
    final Map<String, dynamic> jsonResponse = json.decode(response.body);
    return Property.fromJson(jsonResponse);
  }

  Future<void> deleteProperty(int propertyId) async {
    await delete('/properties/$propertyId', authenticated: true);
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
