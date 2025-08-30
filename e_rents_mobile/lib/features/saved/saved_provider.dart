import 'package:flutter/foundation.dart';
import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/core/services/secure_storage_service.dart';
import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/base/api_service_extensions.dart';
import 'dart:convert';

/// Provider for managing saved/favorite properties
/// Refactored to use new standardized BaseProvider without caching
/// Maintains local storage for offline support
class SavedProvider extends BaseProvider {
  final SecureStorageService _storage;

  SavedProvider(super.api, this._storage) : super();

  // ─── State ──────────────────────────────────────────────────────────────
  List<Property> _items = [];
  List<Property> _filteredItems = [];
  String _searchQuery = '';
  Map<String, dynamic> _currentFilters = {};
  
  static const String _savedPropertiesKey = 'saved_properties';

  // ─── Getters ────────────────────────────────────────────────────────────
  List<Property> get items => _filteredItems;
  List<Property> get allItems => _items;
  String get searchQuery => _searchQuery;
  Map<String, dynamic> get currentFilters => Map.unmodifiable(_currentFilters);
  @override
  bool get hasData => _items.isNotEmpty;
  @override
  bool get isEmpty => _items.isEmpty;
  int get savedCount => _items.length;
  bool get hasSavedProperties => _items.isNotEmpty;

  // ─── Public API ─────────────────────────────────────────────────────────

  /// Load all saved properties
  Future<void> loadSavedProperties({bool forceRefresh = false}) async {
    // If not forcing refresh and we already have data, skip
    if (!forceRefresh && _items.isNotEmpty) {
      return;
    }

    final properties = await executeWithState(() async {
      // First try local storage for offline support
      try {
        final savedJson = await _storage.getData(_savedPropertiesKey);
        if (savedJson != null) {
          final List<dynamic> savedList = json.decode(savedJson);
          return savedList.map((json) => Property.fromJson(json)).toList();
        }
      } catch (e) {
        debugPrint('SavedProvider: Failed to load from local storage: $e');
      }

      // Fallback to API
      final savedList = await api.getListAndDecode(
        '/user/saved-properties',
        Property.fromJson,
        authenticated: true,
      );
      
      // Cache locally for offline support
      await _cacheSavedProperties(savedList);
      return savedList;
    });

    if (properties != null) {
      _items = properties;
      _applySearchAndFilters();
    }
  }

  /// Refresh saved properties (force reload from API)
  Future<void> refreshSavedProperties() async {
    final properties = await executeWithState(() async {
      final savedList = await api.getListAndDecode(
        '/user/saved-properties',
        Property.fromJson,
        authenticated: true,
      );
      await _cacheSavedProperties(savedList);
      return savedList;
    });
    
    if (properties != null) {
      _items = properties;
      _applySearchAndFilters();
    }
  }

  /// Check if a property is saved
  bool isPropertySaved(int propertyId) {
    return _items.any((property) => property.propertyId == propertyId);
  }

  /// Toggle saved status of a property
  Future<bool> toggleSavedStatus(Property property) async {
    bool newStatus = false;

    final success = await executeWithStateForSuccess(() async {
      final isSaved = isPropertySaved(property.propertyId);

      if (isSaved) {
        final wasRemoved = await _unsavePropertyInternal(property.propertyId);
        if (wasRemoved) {
          _items.removeWhere((p) => p.propertyId == property.propertyId);
          _applySearchAndFilters();
        }
        newStatus = false;
      } else {
        await _savePropertyInternal(property);
        if (!_items.any((p) => p.propertyId == property.propertyId)) {
          _items.add(property);
          _applySearchAndFilters();
        }
        newStatus = true;
      }

      debugPrint(
        'SavedProvider: Toggled ${property.propertyId} to ${newStatus ? 'saved' : 'unsaved'}',
      );
    }, errorMessage: 'Failed to toggle property saved status');

    return success && newStatus;
  }

  /// Save a property to favorites
  Future<void> saveProperty(Property property) async {
    await executeWithStateForSuccess(() async {
      await _savePropertyInternal(property);
      
      // Update local state optimistically
      if (!_items.any((p) => p.propertyId == property.propertyId)) {
        _items.add(property);
        _applySearchAndFilters();
      }
    }, errorMessage: 'Failed to save property');
  }

  /// Remove a property from saved list
  Future<void> unsaveProperty(Property property) async {
    await executeWithStateForSuccess(() async {
      final wasRemoved = await _unsavePropertyInternal(property.propertyId);
      
      // Update local state optimistically
      if (wasRemoved) {
        _items.removeWhere((p) => p.propertyId == property.propertyId);
        _applySearchAndFilters();
      }
    }, errorMessage: 'Failed to remove property');
  }

  /// Clear all saved properties
  Future<void> clearSavedProperties() async {
    await executeWithStateForSuccess(() async {
      // Clear on server
      await api.delete('/user/saved-properties', authenticated: true);
      
      // Clear local storage
      await _storage.clearData(_savedPropertiesKey);
      
      // Clear local state
      _items.clear();
      _applySearchAndFilters();
    }, errorMessage: 'Failed to clear saved properties');
  }

  /// Search saved properties
  void searchItems(String query) {
    _searchQuery = query.toLowerCase();
    _applySearchAndFilters();
    notifyListeners();
    debugPrint('SavedProvider: Applied search query: "$query"');
  }

  /// Apply filters to saved properties
  void applyFilters(Map<String, dynamic> filters) {
    _currentFilters = Map.from(filters);
    _applySearchAndFilters();
    notifyListeners();
    debugPrint('SavedProvider: Applied filters: $filters');
  }

  /// Clear search and filters
  void clearSearchAndFilters() {
    _searchQuery = '';
    _currentFilters.clear();
    _applySearchAndFilters();
    notifyListeners();
    debugPrint('SavedProvider: Cleared search and filters');
  }

  /// Get saved properties by type
  List<Property> getPropertiesByType(String typeName) {
    return _items
        .where((property) => property.propertyType?.name == typeName)
        .toList();
  }

  /// Get saved properties in price range
  List<Property> getPropertiesInPriceRange(double minPrice, double maxPrice) {
    return _items
        .where((property) =>
            property.price >= minPrice && property.price <= maxPrice)
        .toList();
  }

  /// Find property by ID
  Property? findById(String id) {
    try {
      return _items.firstWhere((item) => item.propertyId.toString() == id);
    } catch (e) {
      return null;
    }
  }

  /// Get property at index (from filtered list)
  Property? getItemAt(int index) {
    if (index >= 0 && index < _filteredItems.length) {
      return _filteredItems[index];
    }
    return null;
  }

  /// Sort properties
  void sortItems(int Function(Property, Property) compare) {
    _filteredItems.sort(compare);
    notifyListeners();
    debugPrint('SavedProvider: Applied custom sort');
  }

  // ─── Internal Helpers ───────────────────────────────────────────────────

  /// Apply search and filters to the property list
  void _applySearchAndFilters() {
    List<Property> result = List.from(_items);

    // Apply search
    if (_searchQuery.isNotEmpty) {
      result = result.where((item) => _matchesSearch(item, _searchQuery)).toList();
    }

    // Apply filters
    if (_currentFilters.isNotEmpty) {
      result = result.where((item) => _matchesFilters(item, _currentFilters)).toList();
    }

    _filteredItems = result;
  }

  /// Check if property matches search query
  bool _matchesSearch(Property item, String query) {
    return item.name.toLowerCase().contains(query) ||
        (item.description?.toLowerCase().contains(query) ?? false) ||
        (item.address?.city?.toLowerCase().contains(query) ?? false);
  }

  /// Check if property matches current filters
  bool _matchesFilters(Property item, Map<String, dynamic> filters) {
    // Property type filter
    if (filters.containsKey('propertyType')) {
      final filterType = filters['propertyType'];
      if (filterType != null && item.propertyType?.name != filterType) {
        return false;
      }
    }

    // Price range filter
    if (filters.containsKey('minPrice')) {
      final minPrice = filters['minPrice'] as double?;
      if (minPrice != null && item.price < minPrice) {
        return false;
      }
    }

    if (filters.containsKey('maxPrice')) {
      final maxPrice = filters['maxPrice'] as double?;
      if (maxPrice != null && item.price > maxPrice) {
        return false;
      }
    }

    // Status filter
    if (filters.containsKey('status')) {
      final filterStatus = filters['status'];
      if (filterStatus != null && item.status.name != filterStatus) {
        return false;
      }
    }

    return true;
  }

  /// Internal method to save a property
  Future<void> _savePropertyInternal(Property property) async {
    // Update local storage first for instant feedback
    final currentSaved = List<Property>.from(_items);
    if (!currentSaved.any((p) => p.propertyId == property.propertyId)) {
      currentSaved.add(property);
      await _cacheSavedProperties(currentSaved);
    }

    // Then update on server
    await api.post(
        '/user/saved-properties',
        {
          'propertyId': property.propertyId,
        },
        authenticated: true);
  }

  /// Internal method to unsave a property
  Future<bool> _unsavePropertyInternal(int propertyId) async {
    // Update local storage first
    final currentSaved = List<Property>.from(_items);
    final initialLength = currentSaved.length;
    currentSaved.removeWhere((p) => p.propertyId == propertyId);
    await _cacheSavedProperties(currentSaved);

    // Then update on server
    await api.delete('/user/saved-properties/$propertyId', authenticated: true);

    return currentSaved.length < initialLength; // True if something was removed
  }

  /// Cache saved properties locally for offline support
  Future<void> _cacheSavedProperties(List<Property> properties) async {
    final jsonList = properties.map((p) => p.toJson()).toList();
    await _storage.storeData(_savedPropertiesKey, json.encode(jsonList));
  }

  @override
  void dispose() {
    _items.clear();
    _filteredItems.clear();
    super.dispose();
  }
}
