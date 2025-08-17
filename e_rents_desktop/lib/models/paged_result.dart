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

  factory PagedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    return PagedResult<T>(
      items: (json['items'] as List<dynamic>)
          .map((item) => fromJsonT(item))
          .toList(),
      totalCount: json['totalCount'] as int? ?? 0,
      page: json['page'] as int? ?? 0,
      pageSize: json['pageSize'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson(Object Function(T value) toJsonT) => {
        'items': items.map((item) => toJsonT(item)).toList(),
        'totalCount': totalCount,
        'page': page,
        'pageSize': pageSize,
      };

  factory PagedResult.empty() => PagedResult<T>(
        items: [],
        totalCount: 0,
        page: 0,
        pageSize: 0,
      );
}