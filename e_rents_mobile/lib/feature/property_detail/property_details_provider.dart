import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/core/models/review.dart';
import 'package:e_rents_mobile/feature/property_detail/property_service.dart';
import 'package:flutter/material.dart';

class PropertyDetailProvider with ChangeNotifier {
  Property? _property;
  bool _isLoading = false;
  String? _errorMessage;

  Property? get property => _property;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  set property(Property? value) {
    _property = value;
    notifyListeners();
  }

  Future<void> fetchPropertyDetail(int propertyId) async {
    if (_property != null && _property!.propertyId == propertyId) {
      return; // Already have the correct property loaded
    }

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

  void addReview(Review review) {
    // In a real app, you would send this to the server
    // For now, we'll just add it to the UI
    notifyListeners();

    // You would need to have a list of reviews in this provider
    // or pass the new review back to the PropertyDetailScreen
  }
}
