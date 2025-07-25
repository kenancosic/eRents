/// A generic class for representing a paginated list of items.
class PagedResult<T> {
  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;

  PagedResult({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  // Empty constructor for initialization
  PagedResult.empty()
      : items = [],
        totalCount = 0,
        page = 1,
        pageSize = 10;

  factory PagedResult.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    return PagedResult<T>(
      items: (json['items'] as List).map(fromJsonT).toList(),
      totalCount: json['totalCount'] ?? 0,
      page: json['page'] ?? 1,
      pageSize: json['pageSize'] ?? 10,
    );
  }

  bool get hasNextPage => (page * pageSize) < totalCount;
  bool get hasPreviousPage => page > 1;
  int get totalPages => (totalCount / pageSize).ceil();
}
