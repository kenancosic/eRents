import 'package:flutter/foundation.dart';
import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/base/base_repository.dart';

/// Collection provider for managing lists of items with search, filtering, and pagination
/// Following the desktop app pattern for consistent collection management
abstract class CollectionProvider<T> extends BaseProvider {
  final BaseRepository<T, dynamic> repository;

  List<T> _items = [];
  List<T> _filteredItems = [];
  String _searchQuery = '';
  Map<String, dynamic> _currentFilters = {};
  bool _hasLoaded = false;

  CollectionProvider(this.repository);

  // Getters
  List<T> get items => _filteredItems;
  List<T> get allItems => _items;
  String get searchQuery => _searchQuery;
  Map<String, dynamic> get currentFilters => Map.unmodifiable(_currentFilters);
  @override
  bool get hasData => _items.isNotEmpty;
  bool get isEmpty => _items.isEmpty;
  bool get hasLoaded => _hasLoaded;

  /// Load items with optional parameters
  Future<void> loadItems([Map<String, dynamic>? params]) async {
    await execute(() async {
      debugPrint(
          '${repository.resourceName}: Loading items with params: $params');

      _items = await repository.getAll(params);
      _hasLoaded = true;

      // Apply current search and filters
      _applySearchAndFilters();

      debugPrint('${repository.resourceName}: Loaded ${_items.length} items');
    });
  }

  /// Refresh items (force reload from service)
  Future<void> refreshItems([Map<String, dynamic>? params]) async {
    await execute(() async {
      debugPrint('${repository.resourceName}: Refreshing items');

      _items = await repository.getAll(params, true); // Force refresh
      _hasLoaded = true;

      // Apply current search and filters
      _applySearchAndFilters();

      debugPrint(
          '${repository.resourceName}: Refreshed ${_items.length} items');
    });
  }

  /// Add new item
  Future<void> addItem(T item) async {
    await execute(() async {
      debugPrint('${repository.resourceName}: Adding new item');

      final createdItem = await repository.create(item);
      _items.add(createdItem);

      // Apply current search and filters
      _applySearchAndFilters();

      debugPrint('${repository.resourceName}: Added item successfully');
    });
  }

  /// Update existing item
  Future<void> updateItem(String id, T item) async {
    await execute(() async {
      debugPrint('${repository.resourceName}: Updating item with ID $id');

      final updatedItem = await repository.update(id, item);

      // Find and replace the item in the list
      final index = _items.indexWhere((i) => repository.getItemId(i) == id);
      if (index != -1) {
        _items[index] = updatedItem;
      }

      // Apply current search and filters
      _applySearchAndFilters();

      debugPrint('${repository.resourceName}: Updated item successfully');
    });
  }

  /// Remove item
  Future<void> removeItem(String id) async {
    await execute(() async {
      debugPrint('${repository.resourceName}: Removing item with ID $id');

      final success = await repository.delete(id);

      if (success) {
        _items.removeWhere((item) => repository.getItemId(item) == id);

        // Apply current search and filters
        _applySearchAndFilters();

        debugPrint('${repository.resourceName}: Removed item successfully');
      }
    });
  }

  /// Search items
  void searchItems(String query) {
    _searchQuery = query.toLowerCase();
    _applySearchAndFilters();
    notifyListeners();

    debugPrint('${repository.resourceName}: Applied search query: "$query"');
  }

  /// Apply filters
  void applyFilters(Map<String, dynamic> filters) {
    _currentFilters = Map.from(filters);
    _applySearchAndFilters();
    notifyListeners();

    debugPrint('${repository.resourceName}: Applied filters: $filters');
  }

  /// Clear search and filters
  void clearSearchAndFilters() {
    _searchQuery = '';
    _currentFilters.clear();
    _applySearchAndFilters();
    notifyListeners();

    debugPrint('${repository.resourceName}: Cleared search and filters');
  }

  /// Apply search and filters to the item list
  void _applySearchAndFilters() {
    List<T> result = List.from(_items);

    // Apply search
    if (_searchQuery.isNotEmpty) {
      result =
          result.where((item) => matchesSearch(item, _searchQuery)).toList();
    }

    // Apply filters
    if (_currentFilters.isNotEmpty) {
      result = result
          .where((item) => matchesFilters(item, _currentFilters))
          .toList();
    }

    _filteredItems = result;
  }

  /// Find item by ID
  T? findById(String id) {
    try {
      return _items.firstWhere((item) => repository.getItemId(item) == id);
    } catch (e) {
      return null;
    }
  }

  /// Get item at index (from filtered list)
  T? getItemAt(int index) {
    if (index >= 0 && index < _filteredItems.length) {
      return _filteredItems[index];
    }
    return null;
  }

  /// Sort items
  void sortItems(int Function(T, T) compare) {
    _filteredItems.sort(compare);
    notifyListeners();

    debugPrint('${repository.resourceName}: Applied custom sort');
  }

  // Abstract methods to be implemented by concrete providers

  /// Check if item matches search query
  bool matchesSearch(T item, String query);

  /// Check if item matches current filters
  bool matchesFilters(T item, Map<String, dynamic> filters) {
    // Default implementation - no filtering
    return true;
  }

  /// Called when items are loaded - for custom post-processing
  void onItemsLoaded(List<T> items) {
    // Default implementation - no processing
  }

  @override
  void dispose() {
    _items.clear();
    _filteredItems.clear();
    super.dispose();
  }
}
