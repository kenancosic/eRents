import 'dart:convert';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/renting_type.dart';
import 'package:e_rents_desktop/models/address_detail.dart';
import 'package:e_rents_desktop/models/geo_region.dart';
import 'package:e_rents_desktop/services/api_service.dart';

class PropertyService extends ApiService {
  PropertyService(super.baseUrl, super.storageService);

  Future<List<Property>> getProperties({
    Map<String, String>? queryParams,
  }) async {
    String endpoint = '/properties';
    if (queryParams != null && queryParams.isNotEmpty) {
      endpoint += '?${Uri(queryParameters: queryParams).query}';
    }
    final response = await get(endpoint, authenticated: true);
    final List<dynamic> jsonResponse = json.decode(response.body);
    return jsonResponse.map((json) => Property.fromJson(json)).toList();
  }

  Future<Property> getPropertyById(int propertyId) async {
    final response = await get('/properties/$propertyId', authenticated: true);
    final Map<String, dynamic> jsonResponse = json.decode(response.body);
    return Property.fromJson(jsonResponse);
  }

  Future<Property> createProperty(Property property) async {
    final createRequest = _propertyToInsertRequest(property);
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
    final updateRequest = _propertyToUpdateRequest(propertyData);
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
  Map<String, dynamic> _propertyToInsertRequest(Property property) {
    final request = {
      'name': property.title,
      'description': property.description,
      'price': property.price,
      'currency': property.currency,
      'bedrooms': property.bedrooms > 0 ? property.bedrooms : 1,
      'bathrooms': property.bathrooms > 0 ? property.bathrooms : 1,
      'area': property.area,
      'dailyRate': property.dailyRate,
      'minimumStayDays': property.minimumStayDays,
      // Convert enums to the format expected by backend
      'propertyTypeId': _propertyTypeToId(property.type),
      'rentingTypeId': _rentingTypeToId(property.rentingType),
      'status': _propertyStatusToString(property.status),
      // IMPROVED: Send amenityIds for better performance and type safety
      'amenityIds': property.amenityIds ?? [],
      // Extract image IDs from the images list
      'imageIds':
          property.images
              .map((img) => img.id)
              .where((id) => id != null)
              .cast<int>()
              .toList(),
    };

    // Only add address if it has meaningful data
    if (property.addressDetail != null) {
      final addressJson = _transformAddressForBackend(property.addressDetail!);
      if (addressJson != null) {
        request['addressDetail'] = addressJson;
      }
    }

    return request;
  }

  // Helper method to convert Property to PropertyUpdateRequest DTO
  Map<String, dynamic> _propertyToUpdateRequest(Property property) {
    final request = {
      'name': property.title,
      'description': property.description,
      'price': property.price,
      'currency': property.currency,
      'bedrooms': property.bedrooms > 0 ? property.bedrooms : 1,
      'bathrooms': property.bathrooms > 0 ? property.bathrooms : 1,
      'area': property.area,
      'dailyRate': property.dailyRate,
      'minimumStayDays': property.minimumStayDays,
      // Convert enums to the format expected by backend
      'propertyTypeId': _propertyTypeToId(property.type),
      'rentingTypeId': _rentingTypeToId(property.rentingType),
      'status': _propertyStatusToString(property.status),
      // IMPROVED: Send amenityIds for better performance and type safety
      'amenityIds': property.amenityIds ?? [],
      // Extract image IDs from the images list
      'imageIds':
          property.images
              .map((img) => img.id)
              .where((id) => id != null)
              .cast<int>()
              .toList(),
    };

    // Only add address if it has meaningful data
    if (property.addressDetail != null) {
      final addressJson = _transformAddressForBackend(property.addressDetail!);
      if (addressJson != null) {
        request['addressDetail'] = addressJson;
      }
    }

    return request;
  }

  // Transform address to match backend DTO structure
  Map<String, dynamic>? _transformAddressForBackend(AddressDetail address) {
    final streetLine1 = address.streetLine1.trim();

    if (streetLine1.isEmpty) {
      return null; // No meaningful address data
    }

    final addressJson = <String, dynamic>{
      'streetLine1': streetLine1, // Backend converts to camelCase automatically
      'latitude': address.latitude,
      'longitude': address.longitude,
    };

    // Add optional fields if they exist
    if (address.streetLine2?.isNotEmpty == true) {
      addressJson['streetLine2'] = address.streetLine2;
    }

    // Add geo region if it exists
    if (address.geoRegion != null) {
      final geoRegion = address.geoRegion!;
      addressJson['geoRegion'] = {
        'city': geoRegion.city,
        'country': geoRegion.country ?? 'Bosnia and Herzegovina',
      };

      // Add optional geo region fields
      if (geoRegion.state?.isNotEmpty == true) {
        (addressJson['geoRegion'] as Map<String, dynamic>)['state'] =
            geoRegion.state;
      }
      if (geoRegion.postalCode?.isNotEmpty == true) {
        (addressJson['geoRegion'] as Map<String, dynamic>)['postalCode'] =
            geoRegion.postalCode;
      }
    }

    print(
      'PropertyService: Transformed address for backend: ${json.encode(addressJson)}',
    );
    return addressJson;
  }

  // Property type to backend ID mapping
  int _propertyTypeToId(PropertyType type) {
    switch (type) {
      case PropertyType.apartment:
        return 1;
      case PropertyType.house:
        return 2;
      case PropertyType.condo:
        return 3;
      case PropertyType.townhouse:
        return 4;
      case PropertyType.studio:
        return 5;
      default:
        return 1; // Default to apartment
    }
  }

  // Renting type to backend ID mapping
  int _rentingTypeToId(RentingType type) {
    switch (type) {
      case RentingType.monthly:
        return 1;
      case RentingType.daily:
        return 2;
      default:
        return 1; // Default to monthly
    }
  }

  // Property status to backend string mapping
  String _propertyStatusToString(PropertyStatus status) {
    switch (status) {
      case PropertyStatus.available:
        return 'Available';
      case PropertyStatus.rented:
        return 'Rented';
      case PropertyStatus.maintenance:
        return 'Maintenance';
      case PropertyStatus.unavailable:
        return 'Unavailable';
      default:
        return 'Available';
    }
  }
}
