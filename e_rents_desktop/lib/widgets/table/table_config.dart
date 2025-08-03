import 'package:flutter/material.dart';

class TableColumnConfig<T> {
  final String key;
  final String label;
  final Widget Function(T item) cellBuilder;
  final FlexColumnWidth? width;

  const TableColumnConfig({
    required this.key,
    required this.label,
    required this.cellBuilder,
    this.width,
  });
}

class TableQuery {
  final int page;
  final int pageSize;
  final String? searchTerm;
  final Map<String, dynamic> filters;
  final String? sortBy;
  final bool sortDescending;

  TableQuery({
    this.page = 1,
    this.pageSize = 25,
    this.searchTerm,
    this.filters = const {},
    this.sortBy,
    this.sortDescending = false,
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    
    if (page > 1) params['page'] = page;
    if (pageSize != 25) params['pageSize'] = pageSize;
    if (searchTerm != null && searchTerm!.isNotEmpty) params['searchTerm'] = searchTerm;
    if (sortBy != null && sortBy!.isNotEmpty) params['sortBy'] = sortBy;
    if (sortDescending) params['sortDescending'] = sortDescending;
    
    // Add filters
    filters.forEach((key, value) {
      if (value != null) {
        params[key] = value;
      }
    });
    
    return params;
  }
}
