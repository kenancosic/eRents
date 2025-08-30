import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/base/api_service_extensions.dart';
import 'package:e_rents_desktop/models/enums/maintenance_issue_status.dart';
import 'package:e_rents_desktop/models/paged_result.dart';
import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/services/api_service.dart';

/// MaintenanceProvider standardizes CRUD, pagination, sorting and error handling
/// on top of BaseProvider + ApiServiceExtensions.
/// 
/// Public surface (new API):
/// - fetchList, fetchPaged
/// - getById, create, update, remove
/// - refresh, select, applyFilters, clearFilters
/// - getters: items, paged, selected, filters, sortBy, ascending, page, pageSize
/// 
/// Backward-compatible shims preserved for current screens:
/// - loadPagedIssues({ Map<String, dynamic>? params })
/// - save(MaintenanceIssue issue)  // create or update based on id
/// - getById(String id)
/// - updateIssueStatus(String id, MaintenanceIssueStatus status, { String? resolutionNotes, double? cost })
class MaintenanceProvider extends BaseProvider {
  // State
  final List<MaintenanceIssue> _items = <MaintenanceIssue>[];
  PagedResult<MaintenanceIssue>? _paged;
  MaintenanceIssue? _selected;

  Map<String, dynamic> _filters = {};
  String? _sortBy;
  bool _ascending = true;
  int _page = 1;
  int _pageSize = 20;

  // Property and tenant data for dropdowns
  final List<Property> _properties = <Property>[];
  final List<User> _tenants = <User>[];
  bool _propertiesLoaded = false;
  bool _tenantsLoaded = false;

  // Config
  static const String _basePath = 'maintenanceissues';
  static const String _propertiesPath = 'properties';
  static const String _usersPath = 'users';

  MaintenanceProvider(super.api);

  // Getters
  List<MaintenanceIssue> get items => List.unmodifiable(_items);
  PagedResult<MaintenanceIssue>? get paged => _paged;
  MaintenanceIssue? get selectedIssue => _selected;

  // Property and tenant getters
  List<Property> get properties => List.unmodifiable(_properties);
  List<User> get tenants => List.unmodifiable(_tenants);
  bool get propertiesLoaded => _propertiesLoaded;
  bool get tenantsLoaded => _tenantsLoaded;

  // Back-compat shims expected by existing screens
  List<MaintenanceIssue> get issues => items;
  ApiService get apiService => api;

  Map<String, dynamic> get filters => Map.unmodifiable(_filters);
  String? get sortBy => _sortBy;
  bool get ascending => _ascending;
  int get page => _page;
  int get pageSize => _pageSize;

  /// Builds a snapshot of the last used query to support refresh
  Map<String, dynamic> get lastQuery => <String, dynamic>{
        'filters': Map<String, dynamic>.from(_filters),
        'sortBy': _sortBy,
        'ascending': _ascending,
        'page': _page,
        'pageSize': _pageSize,
      };

  

  // Core methods

  Future<void> fetchList({
    Map<String, dynamic>? filters,
    String? sortBy,
    bool ascending = true,
  }) async {
    await executeWithState<void>(() async {
      _filters = filters ?? {};
      _sortBy = sortBy;
      _ascending = ascending;

      final Map<String, dynamic> query = {
        ..._filters,
        if (_sortBy != null) 'sortBy': _sortBy,
        // Backend screen uses sortDescending param; honor both
        'sortDescending': !ascending,
        'sortDirection': ascending ? 'asc' : 'desc',
      };

      final list = await api.getListAndDecode<MaintenanceIssue>(
        '$_basePath${api.buildQueryString(query)}',
        MaintenanceIssue.fromJson,
      );

      _items
        ..clear()
        ..addAll(list);
      // Invalidate paged, since this is a non-paged fetch
      _paged = null;
      notifyListeners();
    });
  }

  Future<PagedResult<MaintenanceIssue>?> fetchPaged({
    int page = 1,
    int pageSize = 20,
    Map<String, dynamic>? filters,
    String? sortBy,
    bool ascending = true,
  }) async {
    return executeWithState<PagedResult<MaintenanceIssue>>(() async {
      // Normalize filters
      final normalized = Map<String, dynamic>.from(filters ?? {});

      // Convert enum-like query values to PascalCase expected by backend binders
      String toPascal(String s) => s.isEmpty
          ? s
          : s
              .replaceAll('_', ' ')
              .split(RegExp(r"[\s_]"))
              .where((p) => p.isNotEmpty)
              .map((p) => p[0].toUpperCase() + p.substring(1))
              .join();

      Map<String, dynamic> pascalize(Map<String, dynamic> src) {
        final m = Map<String, dynamic>.from(src);
        if (m['priorityMin'] is String) m['priorityMin'] = toPascal(m['priorityMin']);
        if (m['priorityMax'] is String) m['priorityMax'] = toPascal(m['priorityMax']);
        if (m['statuses'] is List) {
          m['statuses'] = (m['statuses'] as List)
              .where((e) => e != null)
              .map((e) => toPascal(e.toString()))
              .toList();
        }
        return m..removeWhere((k, v) => v == null || (v is List && v.isEmpty));
      }

      _filters = pascalize(normalized);
      _sortBy = sortBy;
      _ascending = ascending;
      _page = page;
      _pageSize = pageSize;

      final Map<String, dynamic> query = {
        ..._filters,
        'page': _page,
        'pageSize': _pageSize,
        if (_sortBy != null) 'sortBy': _sortBy,
        'sortDescending': !ascending,
        'sortDirection': ascending ? 'asc' : 'desc',
      };

      final result = await api.getPagedAndDecode<MaintenanceIssue>(
        '$_basePath${api.buildQueryString(query)}',
        MaintenanceIssue.fromJson,
      );

      _paged = result;
      _items
        ..clear()
        ..addAll(result.items);
      notifyListeners();
      return result;
    });
  }

  Future<void> getById(dynamic id) async {
    await executeWithState<void>(() async {
      final MaintenanceIssue issue = await api.getAndDecode<MaintenanceIssue>(
        '$_basePath/$id',
        MaintenanceIssue.fromJson,
      );

      _selected = issue;

      // Update list cache if present
      final int index = _items.indexWhere(
          (e) => e.maintenanceIssueId == issue.maintenanceIssueId);
      if (index >= 0) {
        _items[index] = issue;
      } else {
        _items.add(issue);
      }

      // Update paged cache if present
      if (_paged != null) {
        final List<MaintenanceIssue> updated = List<MaintenanceIssue>.from(_paged!.items);
        final int pIndex = updated.indexWhere(
            (e) => e.maintenanceIssueId == issue.maintenanceIssueId);
        if (pIndex >= 0) {
          updated[pIndex] = issue;
        } else {
          updated.add(issue);
        }
        _paged = PagedResult<MaintenanceIssue>(
          items: updated,
          page: _paged!.page,
          pageSize: _paged!.pageSize,
          totalCount: _paged!.totalCount,
        );
      }

      notifyListeners();
    });
  }

  Future<MaintenanceIssue?> create(MaintenanceIssue dto) async {
    return executeWithRetry<MaintenanceIssue>(() async {
      final created = await api.postAndDecode<MaintenanceIssue>(
        _basePath,
        _encodeBody(dto),
        MaintenanceIssue.fromJson,
      );

      // Optimistically append
      _items.add(created);

      if (_paged != null) {
        final List<MaintenanceIssue> updated = List<MaintenanceIssue>.from(_paged!.items)..add(created);
        _paged = PagedResult<MaintenanceIssue>(
          items: updated,
          page: _paged!.page,
          pageSize: _paged!.pageSize,
          totalCount: _paged!.totalCount + 1,
        );
      }

      _selected = created;
      notifyListeners();
      return created;
    }, isUpdate: true);
  }

  Future<MaintenanceIssue?> update(MaintenanceIssue dto) async {
    return executeWithRetry<MaintenanceIssue>(() async {
      final id = dto.maintenanceIssueId;
      final updated = await api.putAndDecode<MaintenanceIssue>(
        '$_basePath/$id',
        _encodeBody(dto),
        MaintenanceIssue.fromJson,
      );

      // Update in items
      final int idx =
          _items.indexWhere((e) => e.maintenanceIssueId == updated.maintenanceIssueId);
      if (idx >= 0) {
        _items[idx] = updated;
      }

      // Update in paged
      if (_paged != null) {
        final List<MaintenanceIssue> updatedList =
            List<MaintenanceIssue>.from(_paged!.items);
        final int pIndex = updatedList.indexWhere(
            (e) => e.maintenanceIssueId == updated.maintenanceIssueId);
        if (pIndex >= 0) {
          updatedList[pIndex] = updated;
          _paged = PagedResult<MaintenanceIssue>(
            items: updatedList,
            page: _paged!.page,
            pageSize: _paged!.pageSize,
            totalCount: _paged!.totalCount,
          );
        }
      }

      if (_selected?.maintenanceIssueId == updated.maintenanceIssueId) {
        _selected = updated;
      }

      notifyListeners();
      return updated;
    }, isUpdate: true);
  }

  Future<bool> remove(dynamic id) async {
    return executeWithStateForSuccess(() async {
      final success = await api.deleteAndConfirm('$_basePath/$id');
      if (!success) {
        throw Exception('Delete failed');
      }

      _items.removeWhere((e) => e.maintenanceIssueId == id);

      if (_paged != null) {
        final List<MaintenanceIssue> updated =
            List<MaintenanceIssue>.from(_paged!.items)
              ..removeWhere((e) => e.maintenanceIssueId == id);
        _paged = PagedResult<MaintenanceIssue>(
          items: updated,
          page: _paged!.page,
          pageSize: _paged!.pageSize,
          totalCount: (_paged!.totalCount > 0) ? _paged!.totalCount - 1 : 0,
        );
      }

      if (_selected?.maintenanceIssueId == id) {
        _selected = null;
      }

      notifyListeners();
    }, isUpdate: true);
  }

  Future<void> refresh() async {
    // Reuse last query; prefer paged when available
    if (_paged != null) {
      await fetchPaged(
        page: _page,
        pageSize: _pageSize,
        filters: _filters,
        sortBy: _sortBy,
        ascending: _ascending,
      );
    } else {
      await fetchList(
        filters: _filters,
        sortBy: _sortBy,
        ascending: _ascending,
      );
    }
  }

  void select(MaintenanceIssue? issue) {
    _selected = issue;
    notifyListeners();
  }

  void applyFilters(Map<String, dynamic> map) {
    _filters = Map<String, dynamic>.from(map);
    notifyListeners();
  }

  void clearFilters() {
    _filters = {};
    notifyListeners();
  }

  // Backward-compatible shims

  /// Legacy: loadPagedIssues(params: { sortBy, sortDescending, page, pageSize, ... })
  /// Returns PagedResult to match current screen usage.
  Future<PagedResult<MaintenanceIssue>?> loadPagedIssues({
    Map<String, dynamic>? params,
  }) async {
    params = params ?? <String, dynamic>{};
    final String? s = params['sortBy'] as String?;
    final bool sortDescending = (params['sortDescending'] as bool?) ?? false;
    final bool asc = !sortDescending;
    final int p = (params['page'] as int?) ?? 1;
    final int ps = (params['pageSize'] as int?) ?? _pageSize;

    // Keep other filters intact (exclude known paging/sort keys)
    final Map<String, dynamic> remaining = Map<String, dynamic>.from(params)
      ..remove('sortBy')
      ..remove('sortDescending')
      ..remove('page')
      ..remove('pageSize');

    return fetchPaged(
      page: p,
      pageSize: ps,
      filters: remaining.isEmpty ? null : remaining,
      sortBy: s,
      ascending: asc,
    );
  }

  /// Legacy: save(issue) => create or update by presence of maintenanceIssueId
  Future<bool> save(MaintenanceIssue issue) async {
    final bool isCreate = (issue.maintenanceIssueId == 0);
    if (isCreate) {
      final created = await create(issue);
      return created != null;
    } else {
      final updated = await update(issue);
      return updated != null;
    }
  }

  /// Legacy: update only status/cost/resolutionNotes
  Future<void> updateIssueStatus(
    String id,
    MaintenanceIssueStatus status, {
    String? resolutionNotes,
    double? cost,
  }) async {
    // Perform a full update to match backend expectations
    await executeWithRetry(() async {
      // Ensure we have the latest
      await getById(id);
      final current = _selected;
      if (current == null) return null;

      final merged = current.copyWith(
        status: status,
        resolutionNotes: resolutionNotes ?? current.resolutionNotes,
        cost: cost ?? current.cost,
      );

      final requestBody = _encodeBody(merged);
      print('[MaintenanceProvider] Updating status to: ${requestBody['status']}, priority: ${requestBody['priority']}');
      
      final updated = await api.putAndDecode<MaintenanceIssue>(
        '$_basePath/$id',
        requestBody,
        MaintenanceIssue.fromJson,
      );

      // Update caches
      final idx = _items.indexWhere((e) => e.maintenanceIssueId.toString() == id);
      if (idx >= 0) _items[idx] = updated;

      if (_paged != null) {
        final list = List<MaintenanceIssue>.from(_paged!.items);
        final pIdx = list.indexWhere((e) => e.maintenanceIssueId.toString() == id);
        if (pIdx >= 0) {
          list[pIdx] = updated;
          _paged = PagedResult<MaintenanceIssue>(
            items: list,
            page: _paged!.page,
            pageSize: _paged!.pageSize,
            totalCount: _paged!.totalCount,
          );
        }
      }

      if (_selected?.maintenanceIssueId.toString() == id) {
        _selected = updated;
      }

      notifyListeners();
      return updated;
    }, isUpdate: true);
  }

  // Property and tenant management methods
  Future<void> loadProperties() async {
    if (_propertiesLoaded) return;
    
    await executeWithState<void>(() async {
      final properties = await api.getListAndDecode<Property>(
        _propertiesPath,
        Property.fromJson,
      );
      
      _properties
        ..clear()
        ..addAll(properties);
      _propertiesLoaded = true;
      notifyListeners();
    });
  }

  Future<void> loadTenantsForProperty(int propertyId) async {
    await executeWithState<void>(() async {
      // Load tenants who have active bookings for this property
      final tenants = await api.getListAndDecode<User>(
        '$_usersPath?propertyId=$propertyId&userType=Tenant&hasActiveBooking=true',
        User.fromJson,
      );
      
      _tenants
        ..clear()
        ..addAll(tenants);
      _tenantsLoaded = true;
      notifyListeners();
    });
  }

  void clearTenants() {
    _tenants.clear();
    _tenantsLoaded = false;
    notifyListeners();
  }

  String getPropertyDisplayName(Property property) {
    final city = property.address?.city ?? 'Unknown City';
    return '${property.name} - $city';
  }

  String getTenantDisplayName(User tenant) {
    return '${tenant.firstName} ${tenant.lastName} (${tenant.email})';
  }

  // Encode request body ensuring server-compatible enum casing
  Map<String, dynamic> _encodeBody(MaintenanceIssue dto) {
    final map = dto.toJson();
    // The MaintenanceIssue.toJson() now handles PascalCase conversion
    return map;
  }
}
