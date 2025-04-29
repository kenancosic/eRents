class FilterModel {
  String? city;
  double? minPrice;
  double? maxPrice;
  String? sortBy;
  bool sortDescending = false;

  Map<String, dynamic> toQueryParams() {
    return {
      'city': city,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'sortBy': sortBy,
      'sortDescending': sortDescending,
    };
  }
}
