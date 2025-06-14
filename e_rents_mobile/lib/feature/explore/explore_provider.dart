import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/core/models/paged_list.dart';
import 'package:e_rents_mobile/core/models/property_search_object.dart';
import 'package:e_rents_mobile/core/services/property_service.dart';

class ExploreProvider extends BaseProvider {
  final PropertyService _propertyService;
  PagedList<Property>? _properties;
  PropertySearchObject _searchObject = PropertySearchObject();

  PagedList<Property>? get properties => _properties;
  PropertySearchObject get searchObject => _searchObject;

  ExploreProvider(this._propertyService);

  Future<void> fetchProperties({bool loadMore = false}) async {
    if (isLoading) return;

    if (loadMore) {
      if (_properties == null || !_properties!.hasNextPage) return;
      _searchObject.page++;
    } else {
      _searchObject.page = 1;
    }

    await execute(() async {
      final newProperties =
          await _propertyService.searchProperties(_searchObject);

      if (_properties != null && loadMore) {
        _properties = PagedList(
          items: [..._properties!.items, ...newProperties.items],
          page: newProperties.page,
          pageSize: newProperties.pageSize,
          totalCount: newProperties.totalCount,
        );
      } else {
        _properties = newProperties;
      }
    });
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
