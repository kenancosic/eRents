import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/base/api_service_extensions.dart';
import 'package:e_rents_desktop/models/paged_result.dart';
import 'package:e_rents_desktop/models/tenant.dart';
import 'package:e_rents_desktop/models/user.dart';
 
/// TenantsProvider
/// - Manages two datasets:
///   1) Current tenants (Tenant entities) via /tenants
///   2) Prospective tenants (public Users) via /users
class TenantsProvider extends BaseProvider {
  TenantsProvider(super.api);

  // Standardized query state
  Map<String, dynamic> _filters = {};
  String? _sortBy;
  bool _ascending = true;
  int _page = 1;
  int _pageSize = 20;

  Map<String, dynamic> get filters => _filters;
  String? get sortBy => _sortBy;
  bool get ascending => _ascending;
  int get page => _page;
  int get pageSize => _pageSize;

  Map<String, dynamic> get lastQuery => {
        ..._filters,
        if (_sortBy != null) 'sortBy': _sortBy,
        'ascending': _ascending,
        'page': _page,
        'pageSize': _pageSize,
      };

  // Data sets
  PagedResult<Tenant> _pagedTenants = PagedResult.empty();
  PagedResult<User> _pagedProspectives = PagedResult.empty();

  PagedResult<Tenant> get pagedTenants => _pagedTenants;
  List<Tenant> get tenants => _pagedTenants.items;

  PagedResult<User> get pagedProspectives => _pagedProspectives;
  List<User> get prospectiveTenants => _pagedProspectives.items;

  // Filters specific to tenants
  void setTenantStatusFilter(TenantStatus? status) {
    if (status == null) {
      _filters.remove('TenantStatus');
    } else {
      // Backend enum is PascalCase based on C# enum names
      final map = {
        TenantStatus.active: 'Active',
        TenantStatus.inactive: 'Inactive',
        TenantStatus.evicted: 'Evicted',
        TenantStatus.leaseEnded: 'LeaseEnded',
      };
      _filters['TenantStatus'] = map[status];
    }
    _page = 1;
    notifyListeners();
  }

  // Prospective tenants no longer support client-side filters.

  void setPage(int value) {
    _page = value.clamp(1, 1 << 30);
    notifyListeners();
  }

  void setPageSize(int value) {
    _pageSize = value.clamp(5, 200);
    _page = 1;
    notifyListeners();
  }

  void applyFilters(Map<String, dynamic> map) {
    _filters = {..._filters, ...map};
    notifyListeners();
  }

  void clearFilters() {
    _filters = {};
    _page = 1;
    notifyListeners();
  }

  // Fetch current tenants (/tenants)
  Future<PagedResult<Tenant>> getPagedTenants({Map<String, dynamic>? params}) async {
    return _fetchTenants(params: params);
  }

  Future<void> refreshTenants() async {
    await _fetchTenants(params: lastQuery);
  }

  // Fetch prospective tenants (/users?IsPublic=true)
  Future<PagedResult<User>> getPagedProspectives({Map<String, dynamic>? params}) async {
    return _fetchProspectives(params: params);
  }

  Future<void> refreshProspectives() async {
    await _fetchProspectives(params: lastQuery);
  }

  // Internals
  Future<PagedResult<Tenant>> _fetchTenants({Map<String, dynamic>? params}) async {
    final qp = {...?params};
    _sortBy = (qp['sortBy'] as String?) ?? _sortBy;
    _ascending = (qp['ascending'] as bool?) ?? _ascending;
    _page = (qp['page'] as int?) ?? _page;
    _pageSize = (qp['pageSize'] as int?) ?? _pageSize;
    final known = {'sortBy', 'ascending', 'page', 'pageSize'};
    _filters = Map<String, dynamic>.fromEntries(qp.entries.where((e) => !known.contains(e.key)));

    PagedResult<Tenant>? result;
    final fetchResult = await executeWithState<PagedResult<Tenant>>(() async {
      final query = {
        ..._filters,
        if (_sortBy != null) 'sortBy': _sortBy!,
        'ascending': _ascending,
        'page': _page,
        'pageSize': _pageSize,
      };
      _pagedTenants = await api.getPagedAndDecode<Tenant>('/tenants${api.buildQueryString(query)}', Tenant.fromJson, authenticated: true);
      return _pagedTenants;
    });
    if (fetchResult != null) {
      result = fetchResult;
      notifyListeners();
    }
    return result ?? PagedResult.empty();
  }

  Future<PagedResult<User>> _fetchProspectives({Map<String, dynamic>? params}) async {
    final qp = {...?params};
    // Keep tenant tab paging separated from prospective tab by not mutating tenant state here.
    final sortBy = (qp['sortBy'] as String?) ?? _sortBy;
    final ascending = (qp['ascending'] as bool?) ?? _ascending;
    final page = (qp['page'] as int?) ?? _page;
    final pageSize = (qp['pageSize'] as int?) ?? _pageSize;
    final cityContains = (qp['CityContains'] as String?)?.trim();

    PagedResult<User>? result;
    final fetchResult = await executeWithState<PagedResult<User>>(() async {
      final baseFilters = {
        // Hard constraints for prospective tenants
        'IsPublic': true,
      };
      // Do not merge shared _filters to avoid cross-tab contamination. Only accept explicit params (e.g., CityContains).
      final query = {
        ...baseFilters,
        if (cityContains != null && cityContains.isNotEmpty) 'CityContains': cityContains,
        if (sortBy != null) 'sortBy': sortBy,
        'ascending': ascending,
        'page': page,
        'pageSize': pageSize,
      };
      _pagedProspectives = await api.getPagedAndDecode<User>('/users${api.buildQueryString(query)}', User.fromJson, authenticated: true);
      return _pagedProspectives;
    });
    if (fetchResult != null) {
      result = fetchResult;
      notifyListeners();
    }
    return result ?? PagedResult.empty();
  }
}
