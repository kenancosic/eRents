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

  BaseProvider([this._apiService]);

  // State management
  ViewState get state => _state;
  String? get errorMessage => _errorMessage;
  List<T> get items => items_;

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
    _state = viewState;
    notifyListeners();
  }

  void setError(String? message) {
    _errorMessage = message;
    setState(ViewState.Error);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // CRUD operations (if API service is provided)
  Future<void> execute(Function action) async {
    try {
      setState(ViewState.Busy);
      clearError();
      await action();
      setState(ViewState.Idle);
    } catch (e) {
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
    if (_apiService == null) return;

    await execute(() async {
      if (_useMockData) {
        await Future.delayed(const Duration(seconds: 1));
        items_ = getMockItems();
      } else {
        final response = await _apiService.get(endpoint);
        items_ =
            (json.decode(response.body) as List)
                .map((json) => fromJson(json))
                .toList();
      }
    });
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
