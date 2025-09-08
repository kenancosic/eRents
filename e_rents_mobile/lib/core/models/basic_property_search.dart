/// Basic property search model for simple search scenarios
/// Aligned with backend BasicPropertySearch class
class BasicPropertySearch {
  final String? name;
  final double? minPrice;
  final double? maxPrice;
  final int? propertyTypeId;
  final String? cityName;
  final int? rooms;
  final String? searchText;
  final String? status;
  
  // Pagination
  int page;
  final int pageSize;
  
  // Sorting
  final String? sortBy;
  final bool? sortDescending;

  BasicPropertySearch({
    this.name,
    this.minPrice,
    this.maxPrice,
    this.propertyTypeId,
    this.cityName,
    this.rooms,
    this.searchText,
    this.status,
    this.page = 1,
    this.pageSize = 10,
    this.sortBy,
    this.sortDescending,
  });

  /// Convert to query parameters for API calls
  Map<String, String> toQueryParameters() {
    final params = <String, String>{};
    
    if (name != null) params['name'] = name!;
    if (minPrice != null) params['minPrice'] = minPrice!.toString();
    if (maxPrice != null) params['maxPrice'] = maxPrice!.toString();
    if (propertyTypeId != null) params['propertyTypeId'] = propertyTypeId!.toString();
    if (cityName != null) params['cityName'] = cityName!;
    if (rooms != null) params['rooms'] = rooms!.toString();
    if (searchText != null) params['searchText'] = searchText!;
    if (status != null) params['status'] = status!;
    if (sortBy != null) params['sortBy'] = sortBy!;
    if (sortDescending != null) params['sortDescending'] = sortDescending!.toString();
    
    params['page'] = page.toString();
    params['pageSize'] = pageSize.toString();
    
    return params;
  }

  /// Create a copy with updated values
  BasicPropertySearch copyWith({
    String? name,
    double? minPrice,
    double? maxPrice,
    int? propertyTypeId,
    String? cityName,
    int? rooms,
    String? searchText,
    String? status,
    int? page,
    int? pageSize,
    String? sortBy,
    bool? sortDescending,
  }) {
    return BasicPropertySearch(
      name: name ?? this.name,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      propertyTypeId: propertyTypeId ?? this.propertyTypeId,
      cityName: cityName ?? this.cityName,
      rooms: rooms ?? this.rooms,
      searchText: searchText ?? this.searchText,
      status: status ?? this.status,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      sortBy: sortBy ?? this.sortBy,
      sortDescending: sortDescending ?? this.sortDescending,
    );
  }

  /// Check if search has any active filters
  bool get hasActiveFilters {
    return name != null ||
           minPrice != null ||
           maxPrice != null ||
           propertyTypeId != null ||
           cityName != null ||
           rooms != null ||
           searchText != null ||
           status != null;
  }

  /// Validate price range
  bool get isValidPriceRange {
    if (minPrice == null || maxPrice == null) return true;
    return minPrice! <= maxPrice!;
  }

  @override
  String toString() {
    return 'BasicPropertySearch(name: $name, cityName: $cityName, minPrice: $minPrice, maxPrice: $maxPrice, page: $page)';
  }
}