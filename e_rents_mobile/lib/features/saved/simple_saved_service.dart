import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/core/services/api_service.dart';
import 'package:e_rents_mobile/core/services/secure_storage_service.dart';

/// Simplified saved properties service for tenant operations
/// Handles saving/unsaving properties and managing favorites list
class SimpleSavedService {
  final ApiService _apiService;
  final SecureStorageService _storageService;

  SimpleSavedService(this._apiService, this._storageService);

  /// Get all saved properties for the current tenant
  Future<List<Property>> getSavedProperties() async {
    try {
      final response = await _apiService.get('api/Properties/saved');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Property.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error loading saved properties: $e');
      return [];
    }
  }

  /// Save a property to favorites
  Future<bool> saveProperty(int propertyId) async {
    try {
      final response = await _apiService.post('api/Properties/$propertyId/save', {});
      if (response.statusCode == 200 || response.statusCode == 201) {
        await _updateLocalSavedStatus(propertyId, true);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error saving property: $e');
      return false;
    }
  }

  /// Remove property from favorites
  Future<bool> unsaveProperty(int propertyId) async {
    try {
      final response = await _apiService.delete('api/Properties/$propertyId/save');
      if (response.statusCode == 200 || response.statusCode == 204) {
        await _updateLocalSavedStatus(propertyId, false);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error unsaving property: $e');
      return false;
    }
  }

  /// Check if a property is saved
  Future<bool> isPropertySaved(int propertyId) async {
    try {
      final response = await _apiService.get('api/Properties/$propertyId/is-saved');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['isSaved'] as bool? ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking saved status: $e');
      return false;
    }
  }

  /// Get locally cached saved property IDs for offline support
  Future<List<int>> getLocalSavedPropertyIds() async {
    try {
      final savedIdsJson = await _storageService.getData('saved_property_ids');
      if (savedIdsJson != null) {
        final List<dynamic> savedIds = json.decode(savedIdsJson);
        return savedIds.cast<int>();
      }
      return [];
    } catch (e) {
      debugPrint('Error loading local saved properties: $e');
      return [];
    }
  }

  /// Update local cache of saved property status
  Future<void> _updateLocalSavedStatus(int propertyId, bool isSaved) async {
    try {
      final savedIds = await getLocalSavedPropertyIds();
      if (isSaved && !savedIds.contains(propertyId)) {
        savedIds.add(propertyId);
      } else if (!isSaved) {
        savedIds.remove(propertyId);
      }
      
      await _storageService.storeData('saved_property_ids', json.encode(savedIds));
    } catch (e) {
      debugPrint('Error updating local saved status: $e');
    }
  }

  /// Clear all saved properties
  Future<bool> clearAllSaved() async {
    try {
      final response = await _apiService.delete('api/Properties/saved/clear');
      if (response.statusCode == 200 || response.statusCode == 204) {
        await _storageService.clearData('saved_property_ids');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error clearing saved properties: $e');
      return false;
    }
  }
}