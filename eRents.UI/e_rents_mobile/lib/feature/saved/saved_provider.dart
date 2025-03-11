// lib/feature/saved/saved_provider.dart
import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/core/base/base_provider.dart';

class SavedProvider extends BaseProvider {
  List<Property> _savedProperties = [];

  List<Property> get savedProperties => _savedProperties;

  // Check if a property is saved
  bool isPropertySaved(int propertyId) {
    return _savedProperties
        .any((property) => property.propertyId == propertyId);
  }

  // Toggle saved status
  Future<void> toggleSavedStatus(Property property) async {
    setState(ViewState.Busy);

    try {
      if (isPropertySaved(property.propertyId)) {
        _savedProperties
            .removeWhere((p) => p.propertyId == property.propertyId);
      } else {
        _savedProperties.add(property);
      }

      // In a real app, you would save this to persistent storage or API
      // await _savedService.updateSavedProperties(_savedProperties);

      setState(ViewState.Idle);
    } catch (e) {
      setError(e.toString());
    }
  }

  // Load saved properties
  Future<void> loadSavedProperties() async {
    setState(ViewState.Busy);

    try {
      // In a real app, you would fetch this from storage or API
      // _savedProperties = await _savedService.getSavedProperties();

      // For now, we'll keep the current list
      setState(ViewState.Idle);
    } catch (e) {
      setError(e.toString());
    }
  }

  // Clear all saved properties
  Future<void> clearSavedProperties() async {
    setState(ViewState.Busy);

    try {
      _savedProperties.clear();

      // In a real app, you would update this in storage or API
      // await _savedService.clearSavedProperties();

      setState(ViewState.Idle);
    } catch (e) {
      setError(e.toString());
    }
  }
}
