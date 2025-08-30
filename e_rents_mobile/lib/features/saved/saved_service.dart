import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/core/services/api_service.dart';
import 'package:e_rents_mobile/core/services/secure_storage_service.dart';
import 'dart:convert';

/// Service for managing saved/favorite properties
class SavedService {
  final ApiService _apiService;
  final SecureStorageService _storageService;

  static const String _savedPropertiesKey = 'saved_properties';

  SavedService(this._apiService, this._storageService);

  /// Get all saved properties
  Future<List<Property>> getSavedProperties() async {
    try {
      // First try to get from local storage for offline support
      final savedJson = await _storageService.getData(_savedPropertiesKey);
      if (savedJson != null) {
        final List<dynamic> savedList = json.decode(savedJson);
        return savedList.map((json) => Property.fromJson(json)).toList();
      }

      // If no local data, try to fetch from API
      final response =
          await _apiService.get('/user/saved-properties', authenticated: true);
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> savedList = responseData['data'] ?? [];
        final properties =
            savedList.map((json) => Property.fromJson(json)).toList();

        // Cache locally
        await _cacheSavedProperties(properties);
        return properties;
      }

      return [];
    } catch (e) {
      // Return empty list if no saved properties or error
      return [];
    }
  }

  /// Save a property to favorites
  Future<void> saveProperty(Property property) async {
    try {
      // Update local storage first for instant feedback
      final currentSaved = await getSavedProperties();
      if (!currentSaved.any((p) => p.propertyId == property.propertyId)) {
        currentSaved.add(property);
        await _cacheSavedProperties(currentSaved);
      }

      // Then update on server
      await _apiService.post(
          '/user/saved-properties',
          {
            'propertyId': property.propertyId,
          },
          authenticated: true);
    } catch (e) {
      // If server update fails, revert local change
      final currentSaved = await getSavedProperties();
      currentSaved.removeWhere((p) => p.propertyId == property.propertyId);
      await _cacheSavedProperties(currentSaved);
      rethrow;
    }
  }

  /// Remove a property from favorites
  Future<bool> unsaveProperty(int propertyId) async {
    try {
      // Update local storage first
      final currentSaved = await getSavedProperties();
      final initialLength = currentSaved.length;
      currentSaved.removeWhere((p) => p.propertyId == propertyId);
      await _cacheSavedProperties(currentSaved);

      // Then update on server
      await _apiService.delete('/user/saved-properties/$propertyId',
          authenticated: true);

      return currentSaved.length <
          initialLength; // True if something was removed
    } catch (e) {
      // If server update fails, revert local change
      rethrow;
    }
  }

  /// Clear all saved properties
  Future<void> clearSavedProperties() async {
    try {
      // Clear local storage
      await _storageService.clearData(_savedPropertiesKey);

      // Clear on server
      await _apiService.delete('/user/saved-properties', authenticated: true);
    } catch (e) {
      rethrow;
    }
  }

  /// Check if a property is saved
  Future<bool> isPropertySaved(int propertyId) async {
    final savedProperties = await getSavedProperties();
    return savedProperties.any((p) => p.propertyId == propertyId);
  }

  /// Cache saved properties locally
  Future<void> _cacheSavedProperties(List<Property> properties) async {
    final jsonList = properties.map((p) => p.toJson()).toList();
    await _storageService.storeData(_savedPropertiesKey, json.encode(jsonList));
  }
}
