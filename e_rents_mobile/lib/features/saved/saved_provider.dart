import 'package:flutter/foundation.dart';
import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/base/api_service_extensions.dart';
import 'package:e_rents_mobile/core/models/property_card_model.dart';
import 'package:e_rents_mobile/core/enums/property_enums.dart';
import 'package:e_rents_mobile/core/models/address.dart';

/// Provider for managing saved/favorite properties
/// Refactored to use new standardized BaseProvider without complex caching
/// Simplified to use direct API calls with BaseProvider pattern
class SavedProvider extends BaseProvider {
  /// Initialize the SavedProvider with required ApiService
  SavedProvider(super.api);

  // ─── State ──────────────────────────────────────────────────────────────
  final Set<int> _savedIds = <int>{};
  List<PropertyCardModel> _items = [];
  List<PropertyCardModel> _filteredItems = [];
  String _searchQuery = '';
  Map<String, dynamic> _currentFilters = {};

  // ─── Getters ────────────────────────────────────────────────────────────
  List<PropertyCardModel> get items => _filteredItems;
  List<PropertyCardModel> get allItems => _items;
  String get searchQuery => _searchQuery;
  Map<String, dynamic> get currentFilters => Map.unmodifiable(_currentFilters);
  @override
  bool get hasData => _items.isNotEmpty;
  @override
  bool get isEmpty => _items.isEmpty;
  int get savedCount => _savedIds.length;
  bool get hasSavedProperties => _savedIds.isNotEmpty;

  // ─── Public API ─────────────────────────────────────────────────────────

  /// Load all saved properties from API and map to PropertyCardModel
  Future<void> loadSavedProperties({bool forceRefresh = false}) async {
    if (!forceRefresh && _items.isNotEmpty) return;

    final list = await executeWithState(() async {
      return await api.getListAndDecode(
        '/profile/saved-properties',
        (json) => PropertyCardModel(
          propertyId: (json['propertyId'] ?? json['PropertyId']) as int,
          name: (json['name'] ?? json['Name'] ?? '').toString(),
          price: ((json['price'] ?? json['Price']) as num?)?.toDouble() ?? 0,
          currency: (json['currency'] ?? json['Currency'] ?? 'USD').toString(),
          averageRating: ((json['averageRating'] ?? json['AverageRating']) as num?)?.toDouble(),
          coverImageId: (json['coverImageId'] ?? json['CoverImageId'] ?? 0) as int,
          address: Address(
            city: (json['city'] ?? json['City'])?.toString(),
            country: (json['country'] ?? json['Country'])?.toString(),
          ),
          rentalType: PropertyRentalType.monthly,
        ),
        authenticated: true,
      );
    });

    if (list != null) {
      _items = list;
      _savedIds
        ..clear()
        ..addAll(list.map((e) => e.propertyId));
      _applySearchAndFilters();
    }
  }

  /// Refresh saved properties (force reload from API)
  Future<void> refreshSavedProperties() async {
    await loadSavedProperties(forceRefresh: true);
  }

  /// Check if a property is saved
  bool isPropertySaved(int propertyId) => _savedIds.contains(propertyId);

  /// Toggle saved status of a property
  Future<bool> toggleSavedStatus(int propertyId) async {
    bool newStatus = false;

    final success = await executeWithStateForSuccess(() async {
      final isSaved = isPropertySaved(propertyId);
      if (isSaved) {
        final wasRemoved = await _unsaveProperty(propertyId);
        if (wasRemoved) {
          _savedIds.remove(propertyId);
          // Also remove from list on Saved screen
          _items.removeWhere((e) => e.propertyId == propertyId);
          _applySearchAndFilters();
        }
        newStatus = false;
      } else {
        await _saveProperty(propertyId);
        _savedIds.add(propertyId);
        // Do not add to _items here unless we have full data; rely on next refresh
        newStatus = true;
      }

      debugPrint(
        'SavedProvider: Toggled $propertyId to ${newStatus ? 'saved' : 'unsaved'}',
      );
    }, errorMessage: 'Failed to toggle property saved status');

    return success && newStatus;
  }

  /// Save a property to favorites
  Future<void> saveProperty(int propertyId) async {
    await executeWithStateForSuccess(() async {
      await _saveProperty(propertyId);
      _savedIds.add(propertyId);
    }, errorMessage: 'Failed to save property');
  }

  /// Remove a property from saved list
  Future<void> unsaveProperty(int propertyId) async {
    await executeWithStateForSuccess(() async {
      final wasRemoved = await _unsaveProperty(propertyId);
      if (wasRemoved) {
        _savedIds.remove(propertyId);
        _items.removeWhere((e) => e.propertyId == propertyId);
        _applySearchAndFilters();
      }
    }, errorMessage: 'Failed to remove property');
  }

  /// Clear all saved properties
  Future<void> clearSavedProperties() async {
    await executeWithStateForSuccess(() async {
      // Backend has no clear-all endpoint; iterate and delete each
      final ids = List<int>.from(_savedIds);
      for (final id in ids) {
        await _unsaveProperty(id);
      }
      _savedIds.clear();
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
  List<PropertyCardModel> getPropertiesByType(String typeName) {
    return _items.where((p) => true).toList(); // Placeholder if we later add type
  }

  /// Get saved properties in price range
  List<PropertyCardModel> getPropertiesInPriceRange(double minPrice, double maxPrice) {
    return _items.where((p) => p.price >= minPrice && p.price <= maxPrice).toList();
  }

  /// Find property by ID
  PropertyCardModel? findById(String id) {
    try {
      return _items.firstWhere((item) => item.propertyId.toString() == id);
    } catch (e) {
      return null;
    }
  }

  /// Get property at index (from filtered list)
  PropertyCardModel? getItemAt(int index) {
    if (index >= 0 && index < _filteredItems.length) {
      return _filteredItems[index];
    }
    return null;
  }

  /// Sort properties
  void sortItems(int Function(PropertyCardModel, PropertyCardModel) compare) {
    _filteredItems.sort(compare);
    notifyListeners();
    debugPrint('SavedProvider: Applied custom sort');
  }

  // ─── Internal Helpers ───────────────────────────────────────────────────

  /// Apply search and filters to the property list
  void _applySearchAndFilters() {
    List<PropertyCardModel> result = List.from(_items);

    if (_searchQuery.isNotEmpty) {
      result = result.where((item) => _matchesSearch(item, _searchQuery)).toList();
    }

    if (_currentFilters.isNotEmpty) {
      result = result.where((item) => _matchesFilters(item, _currentFilters)).toList();
    }

    _filteredItems = result;
  }

  /// Check if property matches search query
  bool _matchesSearch(PropertyCardModel item, String query) {
    return item.name.toLowerCase().contains(query) ||
        (item.address?.city?.toLowerCase().contains(query) ?? false);
  }

  /// Check if property matches current filters
  bool _matchesFilters(PropertyCardModel item, Map<String, dynamic> filters) {
    // Property type filter
    if (filters.containsKey('propertyType')) {
      // PropertyCardModel currently does not expose type; keep placeholder
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

    return true;
  }

  /// Internal method to save a property by id
  Future<void> _saveProperty(int propertyId) async {
    await api.post(
      '/profile/saved-properties',
      {
        'propertyId': propertyId,
      },
      authenticated: true,
    );
  }

  /// Internal method to unsave a property
  Future<bool> _unsaveProperty(int propertyId) async {
    await api.delete('/profile/saved-properties/$propertyId', authenticated: true);
    return true;
  }

  @override
  void dispose() {
    _items.clear();
    _filteredItems.clear();
    _savedIds.clear();
    super.dispose();
  }
}
