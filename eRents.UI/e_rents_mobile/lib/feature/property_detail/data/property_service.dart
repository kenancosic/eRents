import 'package:e_rents_mobile/core/models/property.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PropertyService {
  final String _baseUrl = 'https://your-api-url.com/api';

  Future<Property> getPropertyById(int id) async {
    final response = await http.get(Uri.parse('$_baseUrl/properties/$id'));
    if (response.statusCode == 200) {
      return Property.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load property');
    }
  }

  Future<List<Property>> getProperties() async {
    final response = await http.get(Uri.parse('$_baseUrl/properties'));
    if (response.statusCode == 200) {
      Iterable list = json.decode(response.body);
      return list.map((model) => Property.fromJson(model)).toList();
    } else {
      throw Exception('Failed to load properties');
    }
  }
}
