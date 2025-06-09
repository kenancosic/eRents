import 'package:flutter/foundation.dart';
import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/base/base_repository.dart';

/// Detail provider for managing single item details
/// Following the desktop app pattern for consistent detail management
abstract class DetailProvider<T> extends BaseProvider {
  final BaseRepository<T, dynamic> repository;

  T? _item;
  String? _currentId;
  bool _hasLoaded = false;

  DetailProvider(this.repository);

  // Getters
  T? get item => _item;
  String? get currentId => _currentId;
  @override
  bool get hasData => _item != null;
  bool get hasLoaded => _hasLoaded;

  /// Load item by ID
  Future<void> loadItem(String id, {bool forceRefresh = false}) async {
    if (_currentId == id && _item != null && !forceRefresh) {
      debugPrint('${repository.resourceName}: Item $id already loaded');
      return;
    }

    await execute(() async {
      debugPrint('${repository.resourceName}: Loading item with ID: $id');

      _currentId = id;
      _item = await repository.getById(id, forceRefresh: forceRefresh);
      _hasLoaded = true;

      if (_item != null) {
        debugPrint('${repository.resourceName}: Loaded item with ID $id');
        onItemLoaded(_item!);
      } else {
        debugPrint('${repository.resourceName}: Item with ID $id not found');
      }
    });
  }

  /// Refresh current item
  Future<void> refreshItem() async {
    if (_currentId != null) {
      await loadItem(_currentId!, forceRefresh: true);
    }
  }

  /// Update current item
  Future<void> updateItem(T updatedItem) async {
    if (_currentId == null) {
      throw StateError('No item loaded to update');
    }

    await execute(() async {
      debugPrint('${repository.resourceName}: Updating current item');

      final result = await repository.update(_currentId!, updatedItem);
      _item = result;

      debugPrint('${repository.resourceName}: Updated item successfully');
      onItemUpdated(result);
    });
  }

  /// Delete current item
  Future<bool> deleteItem() async {
    if (_currentId == null) {
      throw StateError('No item loaded to delete');
    }

    bool success = false;
    await execute(() async {
      debugPrint('${repository.resourceName}: Deleting current item');

      success = await repository.delete(_currentId!);

      if (success) {
        final deletedItem = _item;
        _item = null;
        _currentId = null;
        _hasLoaded = false;

        debugPrint('${repository.resourceName}: Deleted item successfully');
        if (deletedItem != null) {
          onItemDeleted(deletedItem);
        }
      }
    });

    return success;
  }

  /// Clear current item
  void clearItem() {
    _item = null;
    _currentId = null;
    _hasLoaded = false;
    clearError();
    notifyListeners();

    debugPrint('${repository.resourceName}: Cleared current item');
  }

  /// Check if the specified ID is currently loaded
  bool isItemLoaded(String id) {
    return _currentId == id && _item != null;
  }

  /// Get specific property from current item
  /// Useful for UI binding when item might be null
  R? getItemProperty<R>(R? Function(T) selector) {
    if (_item == null) return null;
    return selector(_item!);
  }

  /// Update specific property of current item (optimistic update)
  /// This updates the local item immediately while the server update is pending
  void updateItemProperty(T Function(T) updater) {
    if (_item != null) {
      _item = updater(_item!);
      notifyListeners();
    }
  }

  // Lifecycle hooks - can be overridden by concrete providers

  /// Called when item is successfully loaded
  void onItemLoaded(T item) {
    // Default implementation - no action
  }

  /// Called when item is successfully updated
  void onItemUpdated(T item) {
    // Default implementation - no action
  }

  /// Called when item is successfully deleted
  void onItemDeleted(T item) {
    // Default implementation - no action
  }

  @override
  void dispose() {
    _item = null;
    _currentId = null;
    super.dispose();
  }
}
