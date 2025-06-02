import 'package:flutter/material.dart';

/// View state enum for backward compatibility
enum ViewState { idle, busy, error }

/// Temporary base provider for backward compatibility
/// This will be replaced in Phase 2 with the new provider architecture
abstract class BaseProvider<T> extends ChangeNotifier {
  ViewState _state = ViewState.idle;
  String? _errorMessage;
  List<T> _items = [];
  T? _selectedItem;

  // State getters
  ViewState get state => _state;
  String? get errorMessage => _errorMessage;
  List<T> get items => _items;
  T? get selectedItem => _selectedItem;
  bool get isBusy => _state == ViewState.busy;
  bool get isIdle => _state == ViewState.idle;
  bool get hasError => _state == ViewState.error;

  // State setters
  void setState(ViewState newState) {
    _state = newState;
    notifyListeners();
  }

  void setError(String message) {
    _errorMessage = message;
    _state = ViewState.error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_state == ViewState.error) {
      _state = ViewState.idle;
    }
    notifyListeners();
  }

  void setItems(List<T> newItems) {
    _items = newItems;
    notifyListeners();
  }

  void setSelectedItem(T? item) {
    _selectedItem = item;
    notifyListeners();
  }

  // Abstract methods for backward compatibility
  Future<void> fetchItems([Map<String, dynamic>? params]) async {}
  Future<void> fetchItemById(String id) async {}
  Future<void> createItem(T item) async {}
  Future<void> updateItem(String id, T item) async {}
  Future<void> deleteItem(String id) async {}
  Future<void> refreshItems() async {}

  // Utility methods
  void addItem(T item) {
    _items.add(item);
    notifyListeners();
  }

  void removeItem(T item) {
    _items.remove(item);
    notifyListeners();
  }

  void updateItemInList(T oldItem, T newItem) {
    final index = _items.indexOf(oldItem);
    if (index != -1) {
      _items[index] = newItem;
      notifyListeners();
    }
  }
}
