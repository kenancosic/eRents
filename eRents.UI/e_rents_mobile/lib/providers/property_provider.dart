import 'package:flutter/material.dart';
import 'package:e_rents_mobile/models/property.dart';
import 'package:e_rents_mobile/providers/base_provider.dart';

class PropertyProvider extends BaseProvider<Property> {
  PropertyProvider() : super("api/properties");

  // Properties for state management
  bool _isLoading = false;
  String? _error;
  List<Property> _items = [];

  // Getters for state
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Property> get items => _items;

  @override
  Property fromJson(data) {
    return Property.fromJson(data);
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setError(String? value) {
    _error = value;
    notifyListeners();
  }

  void setItems(List<Property> value) {
    _items = value;
    notifyListeners();
  }

  Future<void> fetchProperties({int? page, int? pageSize}) async {
    setLoading(true);
    setError(null);
    try {
      var properties = await get(page: page, pageSize: pageSize);
      setItems(properties);
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<Property?> fetchPropertyById(int id) async {
    setLoading(true);
    setError(null);
    try {
      var property = await getById(id);
      return property;
    } catch (e) {
      setError(e.toString());
      return null;
    } finally {
      setLoading(false);
    }
  }

  Future<Property?> createProperty(Property property) async {
    setLoading(true);
    setError(null);
    try {
      var createdProperty = await insert(property);
      return createdProperty;
    } catch (e) {
      setError(e.toString());
      return null;
    } finally {
      setLoading(false);
    }
  }

  Future<Property?> updateProperty(int id, Property property) async {
    setLoading(true);
    setError(null);
    try {
      var updatedProperty = await update(id, property);
      return updatedProperty;
    } catch (e) {
      setError(e.toString());
      return null;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> deleteProperty(int id) async {
    setLoading(true);
    setError(null);
    try {
      var success = await delete(id);
      return success;
    } catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }
}
