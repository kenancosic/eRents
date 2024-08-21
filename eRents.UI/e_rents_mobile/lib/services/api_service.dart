import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/property.dart';

class ApiService {
  final String _baseUrl = 'https://localhost:7193/api'; // Replace with your actual API base URL

  // Fetch properties with pagination
  Future<List<Property>> getProperties({int page = 1}) async {
    final url = Uri.parse('$_baseUrl/properties?page=$page');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Property.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load properties');
    }
  }
}
