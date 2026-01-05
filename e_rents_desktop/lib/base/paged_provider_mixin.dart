import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/models/paged_result.dart';
import 'package:e_rents_desktop/base/api_service_extensions.dart';

/// Mixin providing common pagination, sorting, and filtering functionality
/// for providers that need paginated list views.
/// 
/// This consolidates the ~50 lines of pagination boilerplate that was
/// duplicated across PropertyProvider, MaintenanceProvider, TenantsProvider,
/// and RentsProvider.
/// 
/// Usage:
/// ```dart
/// class MyProvider extends BaseProvider with PagedProviderMixin<MyModel> {
///   MyProvider(super.api);
///   
///   @override
///   String get basePath => '/mymodels';
///   
///   @override
///   MyModel Function(Map<String, dynamic>) get fromJson => MyModel.fromJson;
/// }
/// ```
mixin PagedProviderMixin<T> on BaseProvider {
  // ─── Abstract Properties ───────────────────────────────────────────────────
  
  /// The base API path for this resource (e.g., '/Properties')
  String get basePath;
  
  /// JSON deserialization factory
  T Function(Map<String, dynamic>) get fromJson;

  // ─── State ─────────────────────────────────────────────────────────────────
  
  final List<T> _pagedItems = <T>[];
  PagedResult<T>? _pagedResult;
  Map<String, dynamic> _pagedFilters = {};
  String? _pagedSortBy;
  bool _pagedAscending = true;
  int _currentPage = 1;
  int _currentPageSize = 20;

  // ─── Getters ───────────────────────────────────────────────────────────────
  
  /// All items loaded (non-paged)
  List<T> get pagedItems => List.unmodifiable(_pagedItems);
  
  /// Paged result with metadata
  PagedResult<T>? get pagedResult => _pagedResult;
  
  /// Current filters
  Map<String, dynamic> get pagedFilters => Map.unmodifiable(_pagedFilters);
  
  /// Current sort column
  String? get sortBy => _pagedSortBy;
  
  /// Sort direction
  bool get sortAscending => _pagedAscending;
  
  /// Current page number
  int get page => _currentPage;
  
  /// Current page size
  int get pageSize => _currentPageSize;
  
  /// Last query parameters as a record
  ({int page, int pageSize, String? sortBy, bool ascending}) get lastQuery =>
      (page: _currentPage, pageSize: _currentPageSize, sortBy: _pagedSortBy, ascending: _pagedAscending);

  // ─── List Methods ──────────────────────────────────────────────────────────

  /// Fetch all items (non-paged) with optional filters and sorting
  Future<List<T>?> fetchListItems({
    Map<String, dynamic>? filters,
    String? sortBy,
    bool? ascending,
  }) async {
    return executeWithState(() async {
      final params = <String, dynamic>{
        ..._pagedFilters,
        if (filters != null) ...filters,
        if (sortBy != null) 'sortBy': sortBy,
        if (ascending != null) 'ascending': ascending,
      };
      
      final queryString = params.isNotEmpty 
          ? '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}' 
          : '';
      
      final items = await api.getListAndDecode<T>(
        '$basePath$queryString',
        fromJson,
        authenticated: true,
      );
      
      _pagedItems
        ..clear()
        ..addAll(items);
      
      return items;
    });
  }

  /// Fetch paginated results
  Future<PagedResult<T>?> fetchPagedItems({
    int? page,
    int? pageSize,
    String? sortBy,
    bool? ascending,
    Map<String, dynamic>? filters,
  }) async {
    return await executeWithState<PagedResult<T>>(() async {
      _currentPage = page ?? _currentPage;
      _currentPageSize = pageSize ?? _currentPageSize;
      if (sortBy != null) _pagedSortBy = sortBy;
      if (ascending != null) _pagedAscending = ascending;

      final params = <String, dynamic>{
        ..._pagedFilters,
        if (filters != null) ...filters,
        'page': _currentPage,
        'pageSize': _currentPageSize,
        if (_pagedSortBy != null) 'sortBy': _pagedSortBy,
        'ascending': _pagedAscending,
      };

      final queryString = '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
      
      final result = await api.getPagedAndDecode<T>(
        '$basePath$queryString',
        fromJson,
        authenticated: true,
      );
      
      _pagedResult = result;
      _pagedItems
        ..clear()
        ..addAll(result.items);
      
      return result;
    });
  }

  // ─── Filter Methods ────────────────────────────────────────────────────────

  /// Apply filters from query parameters (e.g., from URL)
  void applyFiltersFromParams(Map<String, dynamic> qp) {
    _pagedSortBy = (qp['sortBy'] as String?) ?? _pagedSortBy;
    
    // Handle both 'ascending' and 'sortDirection' patterns
    if (qp.containsKey('ascending')) {
      _pagedAscending = (qp['ascending'] as bool?) ?? _pagedAscending;
    } else if (qp.containsKey('sortDirection')) {
      final sd = qp['sortDirection'] as String?;
      if (sd != null) {
        _pagedAscending = sd.toLowerCase() != 'desc';
      }
    }
    
    _currentPage = (qp['page'] as int?) ?? _currentPage;
    _currentPageSize = (qp['pageSize'] as int?) ?? _currentPageSize;
    
    // Extract custom filters (everything except pagination params)
    final knownParams = {'sortBy', 'ascending', 'sortDirection', 'page', 'pageSize'};
    _pagedFilters = Map<String, dynamic>.fromEntries(
      qp.entries.where((e) => !knownParams.contains(e.key))
    );
    
    notifyListeners();
  }

  /// Set filters directly
  void setPagedFilters(Map<String, dynamic> filters) {
    _pagedFilters = Map<String, dynamic>.from(filters);
    notifyListeners();
  }

  /// Clear all filters
  void clearPagedFilters() {
    _pagedFilters = {};
    _currentPage = 1;
    notifyListeners();
  }

  /// Set sorting
  void setPagedSort(String? sortBy, {bool ascending = true}) {
    _pagedSortBy = sortBy;
    _pagedAscending = ascending;
    notifyListeners();
  }

  /// Set page and page size
  void setPagedPage(int page, {int? pageSize}) {
    _currentPage = page;
    if (pageSize != null) _currentPageSize = pageSize;
    notifyListeners();
  }

  /// Calculate total pages from result
  int _calculateTotalPages() {
    if (_pagedResult == null || _currentPageSize == 0) return 1;
    return (_pagedResult!.totalCount / _currentPageSize).ceil();
  }

  /// Go to next page (returns false if already at last page)
  bool nextPage() {
    final totalPagesCount = _calculateTotalPages();
    if (_currentPage < totalPagesCount) {
      _currentPage++;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Go to previous page (returns false if already at first page)
  bool previousPage() {
    if (_currentPage > 1) {
      _currentPage--;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Check if there's a next page
  bool get hasNextPage => _currentPage < _calculateTotalPages();
  
  /// Check if there's a previous page
  bool get hasPreviousPage => _currentPage > 1;
  
  /// Total pages
  int get totalPages => _calculateTotalPages();
  
  /// Total items count
  int get totalItemsCount => _pagedResult?.totalCount ?? _pagedItems.length;
}
