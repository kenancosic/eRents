class PropertySearchObject {
  final String? cityName;
  final double? minPrice;
  final double? maxPrice;
  final String? sortBy;
  final bool? sortDescending;
  int page;

  PropertySearchObject({
    this.cityName,
    this.minPrice,
    this.maxPrice,
    this.sortBy,
    this.sortDescending,
    this.page = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      if (cityName != null) 'city': cityName,
      if (minPrice != null) 'minPrice': minPrice,
      if (maxPrice != null) 'maxPrice': maxPrice,
      if (sortBy != null) 'sortBy': sortBy,
      if (sortDescending != null) 'sortDescending': sortDescending,
      'page': page.toString(),
    };
  }

  Map<String, String> toQueryParameters() {
    return {
      if (cityName != null) 'city': cityName!,
      if (minPrice != null) 'minPrice': minPrice!.toString(),
      if (maxPrice != null) 'maxPrice': maxPrice!.toString(),
      if (sortBy != null) 'sortBy': sortBy!,
      if (sortDescending != null) 'sortDescending': sortDescending!.toString(),
      'page': page.toString(),
    };
  }

  PropertySearchObject copyWith({
    String? cityName,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    bool? sortDescending,
    int? page,
  }) {
    return PropertySearchObject(
      cityName: cityName ?? this.cityName,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      sortBy: sortBy ?? this.sortBy,
      sortDescending: sortDescending ?? this.sortDescending,
      page: page ?? this.page,
    );
  }

  @override
  String toString() {
    return 'PropertySearchObject(cityName: $cityName, minPrice: $minPrice, maxPrice: $maxPrice, sortBy: $sortBy, sortDescending: $sortDescending, page: $page)';
  }
}
