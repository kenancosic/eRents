import 'package:flutter/material.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'dart:convert';

enum ViewState { Idle, Busy, Error }

abstract class BaseProvider<T> extends ChangeNotifier {
  final ApiService? _apiService;
  List<T> items_ = []; // Protected field
  ViewState _state = ViewState.Idle;
  String? _errorMessage;
  bool _useMockData = false; // Default to false for production
  bool _isDisposed = false;

  BaseProvider([this._apiService]);

  // State management
  ViewState get state => _state;
  String? get errorMessage => _errorMessage;
  List<T> get items => items_;

  // Dispose override to track disposal state
  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  // Enable/disable mock data
  void enableMockData() {
    _useMockData = true;
    notifyListeners();
  }

  void disableMockData() {
    _useMockData = false;
    notifyListeners();
  }

  void setState(ViewState viewState) {
    if (_isDisposed) return;
    _state = viewState;
    notifyListeners();
  }

  void setError(String? message) {
    if (_isDisposed) return;
    _errorMessage = message;
    setState(ViewState.Error);
  }

  void clearError() {
    if (_isDisposed) return;
    _errorMessage = null;
    notifyListeners();
  }

  // CRUD operations (if API service is provided)
  Future<void> execute(Function action) async {
    if (_isDisposed) return;

    try {
      setState(ViewState.Busy);
      clearError();
      await action();

      // Check again after the async operation
      if (_isDisposed) return;
      setState(ViewState.Idle);
    } catch (e) {
      if (_isDisposed) return;
      setError(e.toString());
    }
  }

  // Abstract methods to be implemented by child classes
  T fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson(T item);
  String get endpoint;
  List<T> getMockItems();

  // Common CRUD operations
  Future<void> fetchItems() async {
    debugPrint(
      'BaseProvider.fetchItems: starting fetch, useMockData=$_useMockData',
    );

    // Even without an API service, we should still provide mock data in mock mode
    await execute(() async {
      if (_isDisposed) {
        debugPrint('BaseProvider.fetchItems: provider is disposed, aborting');
        return;
      } // Extra check before async operations

      if (_useMockData) {
        debugPrint('BaseProvider.fetchItems: Getting mock data');
        await Future.delayed(const Duration(seconds: 1));
        if (_isDisposed) {
          debugPrint(
            'BaseProvider.fetchItems: provider is disposed after delay, aborting',
          );
          return;
        } // Check again after delay

        final mockItems = getMockItems();
        debugPrint(
          'BaseProvider.fetchItems: Got ${mockItems.length} mock items',
        );
        items_ = mockItems;
      } else if (_apiService != null) {
        debugPrint(
          'BaseProvider.fetchItems: Fetching from API endpoint $endpoint',
        );
        final response = await _apiService.get(endpoint);

        if (_isDisposed) {
          debugPrint(
            'BaseProvider.fetchItems: provider is disposed after API call, aborting',
          );
          return;
        } // Check again after API call

        final decodedItems =
            (json.decode(response.body) as List)
                .map((json) => fromJson(json))
                .toList();
        debugPrint(
          'BaseProvider.fetchItems: Got ${decodedItems.length} items from API',
        );
        items_ = decodedItems;
      } else {
        // If we have no API service and not in mock mode, still provide mock data
        // This prevents the UI from being stuck in a loading state
        debugPrint(
          'BaseProvider.fetchItems: No API service available, defaulting to mock data',
        );
        if (_isDisposed) return;
        final mockItems = getMockItems();
        debugPrint(
          'BaseProvider.fetchItems: Got ${mockItems.length} mock items (fallback)',
        );
        items_ = mockItems;
      }
    });

    debugPrint(
      'BaseProvider.fetchItems: completed with ${items_.length} items',
    );
  }

  Future<void> addItem(T item) async {
    if (_apiService == null) return;

    await execute(() async {
      if (_useMockData) {
        await Future.delayed(const Duration(seconds: 1));
        items_.add(item);
      } else {
        final response = await _apiService.post(endpoint, toJson(item));
        items_.add(fromJson(json.decode(response.body)));
      }
    });
  }

  Future<void> updateItem(T item) async {
    if (_apiService == null) return;

    await execute(() async {
      if (_useMockData) {
        await Future.delayed(const Duration(seconds: 1));
        final index = items_.indexWhere(
          (i) => _getItemId(i) == _getItemId(item),
        );
        if (index != -1) {
          items_[index] = item;
        }
      } else {
        await _apiService.put('$endpoint/${_getItemId(item)}', toJson(item));
        final index = items_.indexWhere(
          (i) => _getItemId(i) == _getItemId(item),
        );
        if (index != -1) {
          items_[index] = item;
        }
      }
    });
  }

  Future<void> deleteItem(String id) async {
    if (_apiService == null) return;

    await execute(() async {
      if (_useMockData) {
        await Future.delayed(const Duration(seconds: 1));
        items_.removeWhere((item) => _getItemId(item) == id);
      } else {
        await _apiService.delete('$endpoint/$id');
        items_.removeWhere((item) => _getItemId(item) == id);
      }
    });
  }

  // Helper method to get item ID
  String _getItemId(T item) {
    final dynamic dynamicItem = item;
    if (dynamicItem.id != null) {
      return dynamicItem.id.toString();
    }
    throw Exception('Item must have an id property');
  }
}
