import 'package:flutter/foundation.dart';
import 'app_error.dart';
import 'provider_state.dart';
import 'repository.dart';

/// Base provider for managing single entity details
abstract class DetailProvider<T> extends ChangeNotifier {
  /// The repository for data access
  final Repository<T> repository;

  /// The current item
  T? _item;

  /// Current state of the provider
  ProviderState _state = ProviderState.idle;

  /// Current error if any
  AppError? _error;

  /// Whether the provider has been initialized with an ID
  bool _initialized = false;

  /// Whether data is being refreshed
  bool _isRefreshing = false;

  /// Current item ID being loaded/displayed
  String? _currentId;

  DetailProvider(this.repository);

  // Public getters

  /// Get the current item
  T? get item => _item;

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
  bool get hasData => _item != null;

  /// Check if provider is empty
  bool get isEmpty => _item == null;

  /// Get current item ID
  String? get currentId => _currentId;

  // Public methods

  /// Load an item by ID
  Future<void> loadItem(String id) async {
    // Don't reload if we're already loading the same item
    if (_state.isLoading && _currentId == id) return;

    await _execute(() async {
      _currentId = id;
      _item = await repository.getById(id);
      _initialized = true;
    });
  }

  /// Refresh the current item
  Future<void> refreshItem() async {
    if (_currentId == null) {
      throw AppError(
        type: ErrorType.validation,
        message: 'Cannot refresh item: no item ID set',
      );
    }

    if (_isRefreshing) return; // Prevent concurrent refreshing

    _isRefreshing = true;
    _setState(ProviderState.refreshing);

    try {
      _item = await repository.refreshItem(_currentId!);
      _clearError();
      _setState(ProviderState.success);
    } catch (e, stackTrace) {
      _setError(AppError.fromException(e, stackTrace));
    } finally {
      _isRefreshing = false;
    }
  }

  /// Update the current item
  Future<void> updateItem(T updatedItem) async {
    if (_currentId == null) {
      throw AppError(
        type: ErrorType.validation,
        message: 'Cannot update item: no item ID set',
      );
    }

    if (_state.isLoading) return;

    await _execute(() async {
      _item = await repository.update(_currentId!, updatedItem);
    });
  }

  /// Delete the current item
  Future<void> deleteItem() async {
    if (_currentId == null) {
      throw AppError(
        type: ErrorType.validation,
        message: 'Cannot delete item: no item ID set',
      );
    }

    if (_state.isLoading) return;

    await _execute(() async {
      await repository.delete(_currentId!);
      _item = null;
      _currentId = null;
      _initialized = false;
    });
  }

  /// Set an item directly (useful when navigating from a list)
  void setItem(T item, String id) {
    _item = item;
    _currentId = id;
    _initialized = true;
    _clearError();
    _setState(ProviderState.success);
  }

  /// Clear the current item and reset state
  void clear() {
    _item = null;
    _currentId = null;
    _initialized = false;
    _clearError();
    _setState(ProviderState.idle);
  }

  /// Clear cache for the current item and refresh
  Future<void> clearCacheAndRefresh() async {
    if (_currentId == null) return;

    await repository.clearCache();
    await refreshItem();
  }

  /// Check if the current item exists in the repository
  Future<bool> exists() async {
    if (_currentId == null) return false;

    try {
      return await repository.exists(_currentId!);
    } catch (e) {
      return false;
    }
  }

  /// Reload the item from the repository (bypasses cache)
  Future<void> forceReload() async {
    if (_currentId == null) return;

    await repository.clearCache();
    await loadItem(_currentId!);
  }

  // Protected/Private methods

  /// Execute an operation with proper state management
  Future<void> _execute(Future<void> Function() action) async {
    try {
      _setState(ProviderState.loading);
      _clearError();

      await action();

      _setState(ProviderState.success);
    } catch (e, stackTrace) {
      _setError(AppError.fromException(e, stackTrace));
    }
  }

  /// Set the provider state
  void _setState(ProviderState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  /// Set an error and update state
  void _setError(AppError error) {
    _error = error;
    _state = ProviderState.error;
    notifyListeners();
  }

  /// Clear the current error
  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _item = null;
    super.dispose();
  }
}
