import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/core/services/api_service.dart';

class PropertyService {
  final ApiService _apiService;

  PropertyService(this._apiService);

  /// Get property by ID
  Future<Property?> getPropertyById(int propertyId) async {
    try {
      final response = await _apiService.get(
        '/Properties/$propertyId',
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return Property.fromJson(data);
      } else if (response.statusCode == 404) {
        debugPrint('PropertyService: Property $propertyId not found');
        return null;
      } else {
        debugPrint(
            'PropertyService: Failed to load property: ${response.statusCode} ${response.body}');
        throw Exception('Failed to load property: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('PropertyService.getPropertyById: $e');
      if (e is Exception) rethrow;
      throw Exception('An error occurred while fetching property: $e');
    }
  }

  /// Get all properties with optional filtering parameters
  Future<List<Property>> getProperties([Map<String, dynamic>? params]) async {
    try {
      String endpoint = '/Properties';

      // Add query parameters if provided
      if (params != null && params.isNotEmpty) {
        final queryParams = params.entries
            .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
            .join('&');
        endpoint += '?$queryParams';
      }

      final response = await _apiService.get(endpoint, authenticated: true);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Property.fromJson(json)).toList();
      } else {
        debugPrint(
            'PropertyService: Failed to load properties: ${response.statusCode} ${response.body}');
        throw Exception(
            'Failed to load properties: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('PropertyService.getProperties: $e');
      if (e is Exception) rethrow;
      throw Exception('An error occurred while fetching properties: $e');
    }
  }

  /// Create new property
  Future<Property> createProperty(Property property) async {
    try {
      final response = await _apiService.post(
        '/Properties',
        property.toJson(),
        authenticated: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return Property.fromJson(data);
      } else {
        debugPrint(
            'PropertyService: Failed to create property: ${response.statusCode} ${response.body}');
        throw Exception(
            'Failed to create property: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('PropertyService.createProperty: $e');
      if (e is Exception) rethrow;
      throw Exception('An error occurred while creating property: $e');
    }
  }

  /// Update existing property
  Future<Property> updateProperty(int propertyId, Property property) async {
    try {
      final response = await _apiService.put(
        '/Properties/$propertyId',
        property.toJson(),
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return Property.fromJson(data);
      } else {
        debugPrint(
            'PropertyService: Failed to update property: ${response.statusCode} ${response.body}');
        throw Exception(
            'Failed to update property: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('PropertyService.updateProperty: $e');
      if (e is Exception) rethrow;
      throw Exception('An error occurred while updating property: $e');
    }
  }

  /// Delete property
  Future<bool> deleteProperty(int propertyId) async {
    try {
      final response = await _apiService.delete(
        '/Properties/$propertyId',
        authenticated: true,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        debugPrint(
            'PropertyService: Failed to delete property: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('PropertyService.deleteProperty: $e');
      return false;
    }
  }

  /// Search properties with advanced filtering
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
    String? city,
    String? country,
  }) async {
    final searchParams = <String, dynamic>{};

    // Add non-null parameters for backend universal filtering
    if (name != null) searchParams['name'] = name;
    if (ownerId != null) searchParams['ownerId'] = ownerId;
    if (description != null) searchParams['description'] = description;
    if (status != null) searchParams['status'] = status;
    if (currency != null) searchParams['currency'] = currency;
    if (propertyTypeId != null) searchParams['propertyTypeId'] = propertyTypeId;
    if (rentingTypeId != null) searchParams['rentingTypeId'] = rentingTypeId;
    if (bedrooms != null) searchParams['bedrooms'] = bedrooms;
    if (bathrooms != null) searchParams['bathrooms'] = bathrooms;
    if (minimumStayDays != null)
      searchParams['minimumStayDays'] = minimumStayDays;
    if (minPrice != null) searchParams['minPrice'] = minPrice;
    if (maxPrice != null) searchParams['maxPrice'] = maxPrice;
    if (minArea != null) searchParams['minArea'] = minArea;
    if (maxArea != null) searchParams['maxArea'] = maxArea;
    if (city != null) searchParams['city'] = city;
    if (country != null) searchParams['country'] = country;

    return await getProperties(searchParams);
  }

  /// Get properties by owner
  Future<List<Property>> getPropertiesByOwner(int ownerId) async {
    return await getProperties({'ownerId': ownerId});
  }

  /// Get available properties
  Future<List<Property>> getAvailableProperties() async {
    return await getProperties({'status': 'available'});
  }

  /// Get properties by type
  Future<List<Property>> getPropertiesByType(int propertyTypeId) async {
    return await getProperties({'propertyTypeId': propertyTypeId});
  }

  /// Get properties in price range
  Future<List<Property>> getPropertiesInPriceRange(
      double minPrice, double maxPrice) async {
    return await getProperties({'minPrice': minPrice, 'maxPrice': maxPrice});
  }
}
