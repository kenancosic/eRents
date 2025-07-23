/// Query parameters and pagination structures for server-side data fetching
///
/// This file contains the core data structures used for communicating
/// with the backend Universal System for paginated, filtered, and sorted data.
library;



/// Query parameters for server-side data fetching
class TableQuery {
  final int page;
  final int pageSize;
  final String? searchTerm;
  final Map<String, dynamic> filters;
  final String? sortBy;
  final bool sortDescending;

  const TableQuery({
    required this.page,
    required this.pageSize,
    this.searchTerm,
    this.filters = const {},
    this.sortBy,
    this.sortDescending = false,
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{
      'page': page + 1, // Backend expects 1-based indexing
      'pageSize': pageSize,
    };

    if (searchTerm?.isNotEmpty == true) {
      params['search'] = searchTerm;
    }

    if (sortBy?.isNotEmpty == true) {
      params['sortBy'] = sortBy;
      params['sortDesc'] = sortDescending;
    }

    // Add filter parameters
    filters.forEach((key, value) {
      if (value != null) {
        params[key] = value;
      }
    });

    return params;
  }

  TableQuery copyWith({
    int? page,
    int? pageSize,
    String? searchTerm,
    Map<String, dynamic>? filters,
    String? sortBy,
    bool? sortDescending,
  }) {
    return TableQuery(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      searchTerm: searchTerm ?? this.searchTerm,
      filters: filters ?? this.filters,
      sortBy: sortBy ?? this.sortBy,
      sortDescending: sortDescending ?? this.sortDescending,
    );
  }
}
