import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/base/api_service_extensions.dart';
import 'package:e_rents_desktop/models/booking.dart';
import 'package:e_rents_desktop/models/paged_result.dart';
import 'package:e_rents_desktop/models/rental_request.dart';
import 'package:e_rents_desktop/models/enums/rental_request_status.dart';
import 'package:flutter/material.dart';

enum RentalType { stay, lease }

class RentsProvider extends BaseProvider {
  RentsProvider(super.api, {required this.context});

  final BuildContext context;

  // ─── Standardized State (per Playbook) ──────────────────────────────────
  RentalType _currentType = RentalType.stay;
  RentalType get currentType => _currentType;

  // Standard provider fields for filters/sort/paging (per Playbook)
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

  // lastQuery for refresh
  Map<String, dynamic> get lastQuery => {
        ..._filters,
        if (_sortBy != null) 'sortBy': _sortBy,
        'ascending': _ascending,
        'page': _page,
        'pageSize': _pageSize,
      };

  PagedResult<Booking> _stayPagedResult = PagedResult.empty();
  PagedResult<Booking> get stayPagedResult => _stayPagedResult;

  PagedResult<RentalRequest> _leasePagedResult = PagedResult.empty();
  PagedResult<RentalRequest> get leasePagedResult => _leasePagedResult;

  // Compatibility getters for widgets
  List<Booking> get stays => _stayPagedResult.items;
  List<RentalRequest> get leases => _leasePagedResult.items;

  Booking? _selectedStay;
  Booking? get selectedStay => _selectedStay;

  RentalRequest? _selectedLease;
  RentalRequest? get selectedLease => _selectedLease;

  // ─── Public API ─────────────────────────────────────────────────────────

  void setRentalType(RentalType type) {
    if (_currentType == type) return;
    _currentType = type;
    notifyListeners();
  }

  Future<void> getLeaseById(int id) async {
    final result = await executeWithState<RentalRequest>(() async {
      return await api.getAndDecode('api/rental-requests/$id', RentalRequest.fromJson, authenticated: true);
    });
    
    if (result != null) {
      _selectedLease = result;
      notifyListeners();
    }
  }

  Future<bool> approveLease(int requestId, String response) async {
    final ok = await executeWithRetry<bool>(() async {
      await api.postJson('api/rental-requests/$requestId/approve', {'response': response}, authenticated: true);
      // postJson returns a non-nullable Map on success; if no exception, consider it success
      return true;
    }, isUpdate: true);
    if (ok == true) {
      // Optimistic: update item in lease list if present
      final idx = _leasePagedResult.items.indexWhere((e) => e.requestId == requestId);
      if (idx >= 0) {
        final current = _leasePagedResult.items[idx];
        final updated = RentalRequest(
          requestId: current.requestId,
          propertyId: current.propertyId,
          userId: current.userId,
          proposedStartDate: current.proposedStartDate,
          proposedEndDate: current.proposedEndDate,
          proposedMonthlyRent: current.proposedMonthlyRent,
          leaseDurationMonths: current.leaseDurationMonths,
          message: current.message,
          status: RentalRequestStatus.approved,
          landlordResponse: response,
          requestDate: current.requestDate,
          createdAt: current.createdAt,
          updatedAt: current.updatedAt,
          createdBy: current.createdBy,
          modifiedBy: current.modifiedBy,
          property: current.property,
          user: current.user,
        );
        final newItems = [..._leasePagedResult.items]..[idx] = updated;
        _leasePagedResult = PagedResult<RentalRequest>(
          items: newItems,
          page: _leasePagedResult.page,
          pageSize: _leasePagedResult.pageSize,
          totalCount: _leasePagedResult.totalCount,
        );
        notifyListeners();
      }
      // After action, refresh leases using lastQuery
      await getPagedLeases(params: lastQuery);
      return true;
    }
    return false;
  }

  // Backward compatibility method for approveLease with named parameters
  Future<bool> approveSelectedLease({String? response}) async {
    if (_selectedLease?.requestId == null) return false;
    return await approveLease(_selectedLease!.requestId, response ?? 'Approved');
  }

  Future<bool> rejectLease(int requestId, String response) async {
    final ok = await executeWithRetry<bool>(() async {
      await api.postJson('api/rental-requests/$requestId/reject', {'response': response}, authenticated: true);
      // postJson returns a non-nullable Map on success; if no exception, consider it success
      return true;
    }, isUpdate: true);
    if (ok == true) {
      // Optimistic: update item in lease list if present
      final idx = _leasePagedResult.items.indexWhere((e) => e.requestId == requestId);
      if (idx >= 0) {
        final current = _leasePagedResult.items[idx];
        final updated = RentalRequest(
          requestId: current.requestId,
          propertyId: current.propertyId,
          userId: current.userId,
          proposedStartDate: current.proposedStartDate,
          proposedEndDate: current.proposedEndDate,
          proposedMonthlyRent: current.proposedMonthlyRent,
          leaseDurationMonths: current.leaseDurationMonths,
          message: current.message,
          status: RentalRequestStatus.rejected,
          landlordResponse: response,
          requestDate: current.requestDate,
          createdAt: current.createdAt,
          updatedAt: current.updatedAt,
          createdBy: current.createdBy,
          modifiedBy: current.modifiedBy,
          property: current.property,
          user: current.user,
        );
        final newItems = [..._leasePagedResult.items]..[idx] = updated;
        _leasePagedResult = PagedResult<RentalRequest>(
          items: newItems,
          page: _leasePagedResult.page,
          pageSize: _leasePagedResult.pageSize,
          totalCount: _leasePagedResult.totalCount,
        );
        notifyListeners();
      }
      await getPagedLeases(params: lastQuery);
      return true;
    }
    return false;
  }

  // ─── Compatibility Methods for Widgets ────────────────────────────────
  
  Future<void> getPagedStays({Map<String, dynamic>? params}) async {
    await fetchPaged(type: RentalType.stay, params: params);
  }

  Future<void> getPagedLeases({Map<String, dynamic>? params}) async {
    await fetchPaged(type: RentalType.lease, params: params);
  }

  // ─── Data Fetching Methods ────────────────────────────────────────────
  
  Future<PagedResult<dynamic>> fetchPaged({required RentalType type, Map<String, dynamic>? params}) async {
    // normalize and persist query into standardized fields
    final qp = {...?params};
    _sortBy = (qp['sortBy'] as String?) ?? _sortBy;
    _ascending = (qp['ascending'] as bool?) ?? _ascending;
    _page = (qp['page'] as int?) ?? _page;
    _pageSize = (qp['pageSize'] as int?) ?? _pageSize;
    // persist remaining as filters (excluding known keys)
    final known = {'sortBy', 'ascending', 'page', 'pageSize'};
    _filters = Map<String, dynamic>.fromEntries(qp.entries.where((e) => !known.contains(e.key)));

    PagedResult<dynamic>? result;
    final fetchResult = await executeWithState<PagedResult<dynamic>>(() async {
      final query = {
        ..._filters,
        if (_sortBy != null) 'sortBy': _sortBy!,
        'ascending': _ascending,
        'page': _page,
        'pageSize': _pageSize,
      };
      if (type == RentalType.stay) {
        _stayPagedResult = await api.getPagedAndDecode<Booking>('api/booking${api.buildQueryString(query)}', Booking.fromJson, authenticated: true);
        return _stayPagedResult;
      } else {
        _leasePagedResult = await api.getPagedAndDecode<RentalRequest>('/api/rental-requests${api.buildQueryString(query)}', RentalRequest.fromJson, authenticated: true);
        return _leasePagedResult;
      }
    });
    if (fetchResult != null) {
      result = fetchResult;
      notifyListeners();
    }
    return result ?? PagedResult.empty();
  }

  // Refresh current tab using lastQuery
  Future<void> refresh() async {
    await fetchPaged(type: _currentType, params: lastQuery);
  }

  // Apply filters and clear filters
  void applyFilters(Map<String, dynamic> map) {
    _filters = {..._filters, ...map};
    notifyListeners();
  }

  void clearFilters() {
    _filters = {};
    notifyListeners();
  }

  // ─── Navigation ─────────────────────────────────────────────────────────

  void navigateToDetail(BuildContext context, dynamic item) {
    if (item is Booking) {
      // For simplified app, no detail screen for stays, just list
      // context.push('/stays/${item.bookingId}');
    } else if (item is RentalRequest) {
      // For simplified app, no detail screen for leases, just list and manage directly
      // context.push('/leases/${item.requestId}');
    }
    // No navigation for now, since no detail screens are planned for simplified app
  }

  // ─── Private Helpers ────────────────────────────────────────────────────

  // Note: _performAction is superseded by executeWithRetry/executeWithStateForSuccess

  // Column definitions removed as UniversalTableConfig is removed
  // Map<String, String> _getColumnLabels(bool isStay) { ... }
  // Map<String, Widget Function(dynamic)> _getCellBuilders(bool isStay, BuildContext context) { ... }
}
