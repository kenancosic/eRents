import 'package:flutter/foundation.dart';
import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/core/services/api_service.dart';
import 'package:e_rents_mobile/core/services/secure_storage_service.dart';
import 'dart:convert';

/// Provider for managing saved/favorite properties
/// Consolidates logic from SavedCollectionProvider, SavedRepository, and SavedService
/// Following the desktop refactoring pattern: View → Provider → ApiService
class SavedProvider extends ChangeNotifier {
  final ApiService _api;
  final SecureStorageService _storage;

  SavedProvider(this._api, this._storage);

  // ─── State ──────────────────────────────────────────────────────────────
  bool _isLoading = false;
  String? _error;
  List<Property> _items = [];
  List<Property> _filteredItems = [];
  String _searchQuery = '';
  Map<String, dynamic> _currentFilters = {};
  
  // Cache management
  DateTime? _lastCacheTime;
  static const Duration _cacheTtl = Duration(minutes: 15);
  static const String _savedPropertiesKey = 'saved_properties';

  // ─── Getters ────────────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Property> get items => _filteredItems;
  List<Property> get allItems => _items;
  String get searchQuery => _searchQuery;
  Map<String, dynamic> get currentFilters => Map.unmodifiable(_currentFilters);
  bool get hasData => _items.isNotEmpty;
  bool get isEmpty => _items.isEmpty;
  int get savedCount => _items.length;
  bool get hasSavedProperties => _items.isNotEmpty;

  // ─── Cache Management ───────────────────────────────────────────────────
  bool get _isCacheValid {
    if (_lastCacheTime == null) return false;
    return DateTime.now().difference(_lastCacheTime!) < _cacheTtl;
  }

  void _updateCache() {
    _lastCacheTime = DateTime.now();
  }

  void _clearCache() {
    _lastCacheTime = null;
  }

  // ─── Public API ─────────────────────────────────────────────────────────

  /// Load all saved properties
  Future<void> loadSavedProperties({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid && _items.isNotEmpty) {
      debugPrint('SavedProvider: Using cached saved properties');
      return;
    }

    await _execute(() async {
      debugPrint('SavedProvider: Loading saved properties');
      
      // First try to get from local storage for offline support
      List<Property> properties = [];
      
      try {
        final savedJson = await _storage.getData(_savedPropertiesKey);
        if (savedJson != null) {
          final List<dynamic> savedList = json.decode(savedJson);
          properties = savedList.map((json) => Property.fromJson(json)).toList();
          debugPrint('SavedProvider: Loaded ${properties.length} properties from local storage');
        }
      } catch (e) {
        debugPrint('SavedProvider: Failed to load from local storage: $e');
      }

      // If no local data or force refresh, try to fetch from API
      if (properties.isEmpty || forceRefresh) {
        try {
          final response = await _api.get('/user/saved-properties', authenticated: true);
          if (response.statusCode == 200) {
            final responseData = json.decode(response.body);
            final List<dynamic> savedList = responseData['data'] ?? [];
            properties = savedList.map((json) => Property.fromJson(json)).toList();
            
            // Cache locally
            await _cacheSavedProperties(properties);
            debugPrint('SavedProvider: Loaded ${properties.length} properties from API');
          }
        } catch (e) {
          debugPrint('SavedProvider: Failed to load from API: $e');
          if (properties.isEmpty) {
            throw Exception('Failed to load saved properties');
          }
        }
      }

      _items = properties;
      _applySearchAndFilters();
      _updateCache();
      
      debugPrint('SavedProvider: Loaded ${_items.length} saved properties');
    });
  }

  /// Refresh saved properties (force reload from API)
  Future<void> refreshSavedProperties() async {
    _clearCache();
    await loadSavedProperties(forceRefresh: true);
  }

  /// Check if a property is saved
  bool isPropertySaved(int propertyId) {
    return _items.any((property) => property.propertyId == propertyId);
  }

  /// Toggle saved status of a property
  Future<bool> toggleSavedStatus(Property property) async {
    bool newStatus = false;

    await _execute(() async {
      final isSaved = isPropertySaved(property.propertyId);

      if (isSaved) {
        // Remove from saved
        await _unsavePropertyInternal(property.propertyId);
        newStatus = false;
        debugPrint('SavedProvider: Removed property ${property.propertyId} from saved');
      } else {
        // Add to saved
        await _savePropertyInternal(property);
        newStatus = true;
        debugPrint('SavedProvider: Added property ${property.propertyId} to saved');
      }

      // Reload to get updated list
      await loadSavedProperties(forceRefresh: true);
    });

    return newStatus;
  }

  /// Save a property to favorites
  Future<void> saveProperty(Property property) async {
    if (!isPropertySaved(property.propertyId)) {
      await _execute(() async {
        await _savePropertyInternal(property);
        await loadSavedProperties(forceRefresh: true);
        debugPrint('SavedProvider: Saved property ${property.propertyId}');
      });
    }
  }

  /// Remove a property from saved list
  Future<bool> unsaveProperty(Property property) async {
    bool removed = false;
    await _execute(() async {
      removed = await _unsavePropertyInternal(property.propertyId);
      await loadSavedProperties(forceRefresh: true);
      debugPrint('SavedProvider: Unsaved property ${property.propertyId}');
    });
    return removed;
  }

  /// Clear all saved properties
  Future<void> clearSavedProperties() async {
    await _execute(() async {
      // Clear local storage
      await _storage.clearData(_savedPropertiesKey);

      // Clear on server
      await _api.delete('/user/saved-properties', authenticated: true);

      _items.clear();
      _applySearchAndFilters();
      _clearCache();
      
      debugPrint('SavedProvider: Cleared all saved properties');
    });
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

  /// Execute operation with loading state and error handling
  Future<void> _execute(Future<void> Function() operation) async {
    if (_isLoading) return;

    _setLoading(true);
    _clearError();

    try {
      await operation();
    } catch (e) {
      _setError(e.toString());
      debugPrint('SavedProvider: Error - $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

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
    await _api.post(
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
    await _api.delete('/user/saved-properties/$propertyId', authenticated: true);

    return currentSaved.length < initialLength; // True if something was removed
  }

  /// Cache saved properties locally
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
