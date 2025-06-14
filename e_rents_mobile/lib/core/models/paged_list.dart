class PagedList<T> {
  final List<T> items;
  final int page;
  final int pageSize;
  final int totalCount;

  PagedList({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
  });

  bool get hasNextPage => page * pageSize < totalCount;
  bool get hasPreviousPage => page > 1;

  factory PagedList.fromJson(
      Map<String, dynamic> json, T Function(dynamic) fromJsonT) {
    return PagedList<T>(
      items: (json['items'] as List).map(fromJsonT).toList(),
      page: json['page'],
      pageSize: json['pageSize'],
      totalCount: json['totalCount'],
    );
  }
}
