import 'package:flutter/material.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/services/mock_data_service.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'dart:convert';
import 'package:e_rents_desktop/base/base_provider.dart';

class PropertyProvider extends BaseProvider<Property> {
  final ApiService _apiService;
  bool _isLoading = false;
  String? _error;
  final bool _useMockData = true; // Flag to toggle between mock and real data

  PropertyProvider(this._apiService) : super(_apiService) {
    // Enable mock data for development
    enableMockData();
  }

  @override
  String get endpoint => '/properties';

  @override
  Property fromJson(Map<String, dynamic> json) => Property.fromJson(json);

  @override
  Map<String, dynamic> toJson(Property item) => item.toJson();

  @override
  List<Property> getMockItems() => MockDataService.getMockProperties();

  List<Property> get properties => items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Add method to update properties list for reordering
  void updateProperties(List<Property> newProperties) {
    items_ = newProperties;
    notifyListeners();
  }

  // Fetch properties using the base provider's fetch method
  Future<void> fetchProperties() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await fetchItems();
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

      await addItem(property);
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

      await updateItem(property);
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

      await deleteItem(id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Additional property-specific methods
  List<Property> getPropertiesByStatus(String status) {
    return items.where((property) => property.status == status).toList();
  }

  List<Property> getPropertiesByType(String type) {
    return items.where((property) => property.type == type).toList();
  }

  List<Property> getAvailableProperties() {
    return items.where((property) => property.status == 'Available').toList();
  }

  List<Property> getOccupiedProperties() {
    return items.where((property) => property.status == 'Occupied').toList();
  }
}
