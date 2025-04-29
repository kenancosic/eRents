import 'dart:convert';

import 'package:e_rents_mobile/core/models/filter_model.dart';
import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/core/services/api_service.dart';

class HomeService {
  final ApiService apiService;

  HomeService(this.apiService);

  Future<List<Property>> fetchProperties({int page = 1}) async {
    final response = await apiService.get('/properties?page=$page', authenticated: true);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Property.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load properties');
    }
  }
  
   Future<List<Property>> getProperties(FilterModel filter) async {
    final response = await apiService.get('/properties/search', authenticated: true);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Property.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load properties');
    }
  }
}
