import 'package:flutter/material.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/services/mock_data_service.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'dart:convert';

class PropertyProvider extends ChangeNotifier {
  final ApiService _apiService;
  List<Property> _properties = [];
  bool _isLoading = false;
  String? _error;
  bool _useMockData = true; // Flag to toggle between mock and real data

  PropertyProvider(this._apiService);

  List<Property> get properties => _properties;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchProperties() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_useMockData) {
        // Simulate network delay
        await Future.delayed(const Duration(seconds: 1));
        _properties = MockDataService.getMockProperties();
      } else {
        final response = await _apiService.get('/properties');
        _properties =
            (json.decode(response.body) as List)
                .map((json) => Property.fromJson(json))
                .toList();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addProperty(Property property) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_useMockData) {
        // Simulate network delay
        await Future.delayed(const Duration(seconds: 1));
        _properties.add(property);
      } else {
        final response = await _apiService.post(
          '/properties',
          property.toJson(),
        );
        _properties.add(Property.fromJson(json.decode(response.body)));
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProperty(Property property) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_useMockData) {
        // Simulate network delay
        await Future.delayed(const Duration(seconds: 1));
        final index = _properties.indexWhere((p) => p.id == property.id);
        if (index != -1) {
          _properties[index] = property;
        }
      } else {
        await _apiService.put('/properties/${property.id}', property.toJson());
        final index = _properties.indexWhere((p) => p.id == property.id);
        if (index != -1) {
          _properties[index] = property;
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteProperty(String id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_useMockData) {
        // Simulate network delay
        await Future.delayed(const Duration(seconds: 1));
        _properties.removeWhere((property) => property.id == id);
      } else {
        await _apiService.delete('/properties/$id');
        _properties.removeWhere((property) => property.id == id);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
