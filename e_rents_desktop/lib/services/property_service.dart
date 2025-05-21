import 'dart:convert';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:http/http.dart' as http;

class PropertyService extends ApiService {
  PropertyService(super.baseUrl, super.storageService);

  Future<List<Property>> getProperties({
    Map<String, String>? queryParams,
  }) async {
    String endpoint = '/properties';
    if (queryParams != null && queryParams.isNotEmpty) {
      endpoint += '?' + Uri(queryParameters: queryParams).query;
    }
    final response = await get(endpoint, authenticated: true);
    final List<dynamic> jsonResponse = json.decode(response.body);
    return jsonResponse.map((json) => Property.fromJson(json)).toList();
  }

  Future<Property> getPropertyById(String propertyId) async {
    final response = await get('/properties/$propertyId', authenticated: true);
    final Map<String, dynamic> jsonResponse = json.decode(response.body);
    return Property.fromJson(jsonResponse);
  }

  Future<Property> createProperty(Property property) async {
    // Ensure ID is not sent for creation if backend auto-generates it.
    // Property.toJson() might need adjustment or backend handles ignoring client-sent ID on POST.
    final response = await post(
      '/properties',
      property.toJson(),
      authenticated: true,
    );
    final Map<String, dynamic> jsonResponse = json.decode(response.body);
    return Property.fromJson(
      jsonResponse,
    ); // Expect backend to return the created property with its ID
  }

  Future<Property> updateProperty(
    String propertyId,
    Property propertyData,
  ) async {
    final response = await put(
      '/properties/$propertyId',
      propertyData.toJson(),
      authenticated: true,
    );
    final Map<String, dynamic> jsonResponse = json.decode(response.body);
    return Property.fromJson(jsonResponse);
  }

  Future<void> deleteProperty(String propertyId) async {
    await delete('/properties/$propertyId', authenticated: true);
  }
}
