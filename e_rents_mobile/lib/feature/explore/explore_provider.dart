import 'package:e_rents_mobile/core/models/paged_list.dart';
import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/core/models/property_search_object.dart';
import 'dart:convert';
import 'package:e_rents_mobile/core/services/api_service.dart';
import 'package:flutter/material.dart';

class ExploreProvider extends ChangeNotifier {
  final ApiService _api;
  ExploreProvider(this._api);

  // --- State ---
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  PagedList<Property>? _properties;
  PagedList<Property>? get properties => _properties;

  PropertySearchObject _searchObject = PropertySearchObject();
  PropertySearchObject get searchObject => _searchObject;

  // --- Public API ---
  Future<void> fetchProperties({bool loadMore = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    if (!loadMore) {
      // If it's a refresh, notify to show loading indicator immediately
      notifyListeners();
    }

    if (loadMore) {
      if (_properties == null || !_properties!.hasNextPage) {
        _isLoading = false;
        notifyListeners();
        return;
      }
      _searchObject.page++;
    } else {
      _searchObject.page = 1;
    }

    try {
            final queryParams = _searchObject.toQueryParameters();
      final uri = Uri(path: 'properties/search', queryParameters: queryParams);

      final response = await _api.get(uri.toString());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final pagedResult = PagedList<Property>.fromJson(
            data, (json) => Property.fromJson(json as Map<String, dynamic>));

        if (_properties != null && loadMore) {
          _properties = PagedList(
            items: [..._properties!.items, ...pagedResult.items],
            page: pagedResult.page,
            pageSize: pagedResult.pageSize,
            totalCount: pagedResult.totalCount,
          );
        } else {
          _properties = pagedResult;
        }
      } else {
        _error = 'Failed to load properties. Status code: ${response.statusCode}';
      }
    } catch (e) {
      _error = "Failed to fetch properties: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void applyFilters(Map<String, dynamic> filters) {
    _searchObject = PropertySearchObject(
      cityName: filters['city'],
      minPrice: filters['minPrice'],
      maxPrice: filters['maxPrice'],
      sortBy: filters['sortBy'],
      sortDescending: filters['sortDescending'],
    );
    fetchProperties();
  }

  void search(String query) {
    _searchObject = PropertySearchObject(cityName: query);
    fetchProperties();
  }
}
