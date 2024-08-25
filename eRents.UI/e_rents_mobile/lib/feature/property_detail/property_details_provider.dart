import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/feature/property_detail/data/property_service.dart';
import 'package:flutter/material.dart';


class PropertyDetailProvider with ChangeNotifier {
  Property? _property;
  bool _isLoading = false;
  String? _errorMessage;

  Property? get property => _property;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchPropertyDetail(int propertyId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _property = await PropertyService().getPropertyById(propertyId);
    } catch (e) {
      _errorMessage = 'Failed to load property details';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearPropertyDetail() {
    _property = null;
    _errorMessage = null;
    notifyListeners();
  }
}
