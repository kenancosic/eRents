import 'dart:async';
import 'package:flutter/foundation.dart';
import 'app_error.dart';
import 'provider_state.dart';
import 'repository.dart';
import 'lifecycle_mixin.dart';

/// Base provider for managing collections of items
abstract class CollectionProvider<T> extends ChangeNotifier
    with LifecycleMixin {
  /// The repository for data access
  final Repository<T> repository;

  /// Internal list of items
  List<T> _items = [];

  /// Current state of the provider
  ProviderState _state = ProviderState.idle;

  /// Current error if any
  AppError? _error;

  /// Whether the provider has been initialized
  bool _initialized = false;

  /// Whether data is being refreshed (for pull-to-refresh)
  bool _isRefreshing = false;

  /// Current filter parameters
  Map<String, dynamic>? _currentParams;

  /// Total count of items (if supported by the repository)
  int? _totalCount;

  // Pagination state
  int _currentPage = 0;
  bool _hasNextPage = false;
  bool _hasPreviousPage = false;
  int _pageSize = 25; // Default page size

  CollectionProvider(this.repository);

  // Public getters

  /// Get the current list of items (immutable)
  List<T> get items => List.unmodifiable(_items);

  /// Get the current state
  ProviderState get state => _state;

  /// Get the current error
  AppError? get error => _error;

  /// Check if provider has been initialized
  bool get initialized => _initialized;

  /// Check if provider is in any loading state
  bool get isLoading => _state.isLoading;

  /// Check if provider is refreshing
  bool get isRefreshing => _isRefreshing;

  /// Check if provider has error
  bool get hasError => _state.isError;

  /// Check if provider is idle
  bool get isIdle => _state.isIdle;

  /// Check if provider has data
  bool get hasData => _items.isNotEmpty;

  /// Check if provider is empty
  bool get isEmpty => _items.isEmpty;

  /// Get the number of items
  int get length => _items.length;

  /// Get total count if available
  int? get totalCount => _totalCount;

  // Pagination getters
  int get currentPage => _currentPage;
  bool get hasNextPage => _hasNextPage;
  bool get hasPreviousPage => _hasPreviousPage;
  int get pageSize => _pageSize;
  int get totalPages =>
      (_totalCount != null && _totalCount! > 0 && _pageSize > 0)
          ? (_totalCount! / _pageSize).ceil()
          : 0;

  /// Get current filter parameters
  Map<String, dynamic>? get currentParams =>
      _currentParams != null ? Map.unmodifiable(_currentParams!) : null;

  // Public methods

  /// Fetch items from repository
  Future<void> fetchItems([Map<String, dynamic>? params]) async {
    if (_state.isLoading) return; // Prevent concurrent loading

    await _execute(() async {
      _currentParams = params;
      final fetchedItems = await repository.getAll(params);
      _items = fetchedItems;
      _initialized = true;
    });
  }

  /// Fetches paginated items from the repository.
  /// This is the new primary method for loading data for tables/lists.
  Future<void> fetchPaginated({
    int page = 0,
    int? pageSize,
    Map<String, dynamic>? params,
  }) async {
    if (_state.isLoading) return;

    await _execute(() async {
      _currentParams = params;
      _pageSize = pageSize ?? _pageSize;
      await _fetchPaginatedData(page: page);
      _initialized = true;
    });
  }

  /// Load the next page of data.
  Future<void> loadNextPage() async {
    if (!_hasNextPage || _state.isLoading) return;
    await _execute(() async {
      await _fetchPaginatedData(page: _currentPage + 1);
    });
  }

  /// Load the previous page of data.
  Future<void> loadPreviousPage() async {
    if (!_hasPreviousPage || _state.isLoading) return;
    await _execute(() async {
      await _fetchPaginatedData(page: _currentPage - 1);
    });
  }

  /// Jump to a specific page.
  Future<void> goToPage(int page) async {
    if (page < 0 ||
        (totalPages > 0 && page >= totalPages) ||
        _state.isLoading) {
      return;
    }
    await _execute(() async {
      await _fetchPaginatedData(page: page);
    });
  }

  /// Refresh items (for pull-to-refresh)
  Future<void> refreshItems([Map<String, dynamic>? params]) async {
    if (_isRefreshing) return; // Prevent concurrent refreshing

    _isRefreshing = true;
    _setState(ProviderState.refreshing);

    try {
      _currentParams = params ?? _currentParams;
      // If we are using pagination, refresh the current page, otherwise fetch all.
      if (_totalCount != null) {
        await _fetchPaginatedData(page: _currentPage, force: true);
      } else {
        final fetchedItems = await repository.getAll(_currentParams);
        _items = fetchedItems;
      }

      _clearError();
      _setState(ProviderState.success);
    } catch (e, stackTrace) {
      _setError(AppError.fromException(e, stackTrace));
    } finally {
      _isRefreshing = false;
    }
  }

  /// Add a new item
  Future<void> addItem(T item) async {
    if (_state.isLoading) return;

    await _execute(() async {
      final createdItem = await repository.create(item);
      _items.add(createdItem);

      // Update total count if we have it
      if (_totalCount != null) {
        _totalCount = _totalCount! + 1;
      }
    });
  }

  /// Update an existing item
  Future<void> updateItem(String id, T item) async {
    if (_state.isLoading) return;

    await _execute(() async {
      final updatedItem = await repository.update(id, item);
      final index = _findItemIndex(id);

      if (index != -1) {
        _items[index] = updatedItem;
      } else {
        debugPrint(
          'CollectionProvider: Item with id $id updated in repository but not found in local list. Local list not modified.',
        );
      }
    });
  }

  /// Remove an item
  Future<void> removeItem(String id) async {
    if (_state.isLoading) return;

    await _execute(() async {
      await repository.delete(id);
      _items.removeWhere((item) => _getItemId(item) == id);

      // Update total count if we have it
      if (_totalCount != null) {
        _totalCount = _totalCount! - 1;
      }
    });
  }

  /// Get an item by ID from the current list
  T? getItemById(String id) {
    try {
      return _items.firstWhere((item) => _getItemId(item) == id);
    } catch (e) {
      return null;
    }
  }

  /// Check if an item exists in the current list
  bool containsItem(String id) {
    return getItemById(id) != null;
  }

  /// Load total count
  Future<void> loadCount([Map<String, dynamic>? params]) async {
    try {
      _totalCount = await repository.count(params ?? _currentParams);
      safeNotifyListeners();
    } catch (e) {
      // Count is optional, don't fail the whole operation
      debugPrint('Failed to load count: $e');
    }
  }

  /// Clear all items and reset state
  void clear() {
    _items.clear();
    _currentParams = null;
    _totalCount = null;
    _initialized = false;
    _currentPage = 0;
    _hasNextPage = false;
    _hasPreviousPage = false;
    _clearError();
    _setState(ProviderState.idle);
  }

  /// Clear cache and refresh data
  Future<void> clearCacheAndRefresh() async {
    await repository.clearCache();
    await refreshItems(_currentParams);
  }

  /// Filter items locally (doesn't affect repository calls)
  List<T> filterItems(bool Function(T) predicate) {
    return _items.where(predicate).toList();
  }

  /// Sort items locally (doesn't affect the original list)
  List<T> sortItems(int Function(T, T) compare) {
    final sortedList = List<T>.from(_items);
    sortedList.sort(compare);
    return sortedList;
  }

  /// Apply local operations (filter + sort) without affecting original list
  List<T> processItems({bool Function(T)? filter, int Function(T, T)? sort}) {
    List<T> result = List<T>.from(_items);

    if (filter != null) {
      result = result.where(filter).toList();
    }

    if (sort != null) {
      result.sort(sort);
    }

    return result;
  }

  /// Ensures the provider is initialized and fetches items if needed.
  /// Call this after creating the provider.
  Future<void> initializeAndFetchIfNeeded([
    Map<String, dynamic>? params,
  ]) async {
    // Only attempt to initialize and fetch if truly idle and never initialized OR explicitly empty.
    // The _initialized flag (set within fetchItems) helps prevent re-fetching
    // if the provider is reused and already loaded data previously.
    if (!_initialized || (_state == ProviderState.idle && _items.isEmpty)) {
      // fetchItems is now safe to call directly as its internal notifyListeners calls are deferred.
      fetchPaginated(
        params: params ?? _currentParams,
      ); // Use paginated fetch by default
    }
  }

  // Protected getters and methods

  // Private methods

  /// Execute an operation with proper state management
  Future<void> _execute(Future<void> Function() action) async {
    try {
      _setState(ProviderState.loading);
      _clearError();

      // Use LifecycleMixin's executeAsync for proper lifecycle management
      await executeAsync(action);

      _setState(ProviderState.success);
    } catch (e, stackTrace) {
      _setError(AppError.fromException(e, stackTrace));
    }
  }

  /// Set the provider state
  void _setState(ProviderState newState) {
    if (_state == newState) return;

    _state = newState;
    safeNotifyListeners();
  }

  /// Set an error and update state
  void _setError(AppError error) {
    _error = error;
    _state = ProviderState.error;
    safeNotifyListeners();
  }

  /// Clear the current error
  void _clearError() {
    if (_error == null) return;

    _error = null;
    safeNotifyListeners();
  }

  /// Find the index of an item by ID
  int _findItemIndex(String id) {
    for (int i = 0; i < _items.length; i++) {
      if (_getItemId(_items[i]) == id) {
        return i;
      }
    }
    return -1;
  }

  /// Internal helper to fetch and update paginated data.
  Future<void> _fetchPaginatedData({
    required int page,
    bool force = false,
  }) async {
    // Construct params for repository call
    final paginatedParams = {
      'pageNumber':
          page, // Backend might expect 0-based or 1-based. Assuming 0-based for now.
      'pageSize': _pageSize,
      ...?_currentParams,
    };

    final pagedResult = await repository.getPaged(paginatedParams);

    // This is the correct way to update the internal list for reads
    _items = pagedResult.items;

    // Update pagination state from the result
    _currentPage = pagedResult.page;
    _totalCount = pagedResult.totalCount;
    _hasNextPage = pagedResult.hasNextPage;
    _hasPreviousPage = pagedResult.hasPreviousPage;
  }

  // Abstract methods that concrete providers must implement

  /// Extract the ID from an item
  String _getItemId(T item);

  @override
  void dispose() {
    _items.clear();
    super.dispose();
  }
}
