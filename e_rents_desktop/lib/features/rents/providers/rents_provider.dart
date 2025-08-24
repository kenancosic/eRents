import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/base/api_service_extensions.dart';
import 'package:e_rents_desktop/models/booking.dart';
import 'package:e_rents_desktop/models/paged_result.dart';
import 'package:flutter/material.dart';

class RentsProvider extends BaseProvider {
  RentsProvider(super.api, {required this.context});

  final BuildContext context;

  // ─── Standardized State (per Playbook) ──────────────────────────────────
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

  PagedResult<Booking> _pagedBookings = PagedResult.empty();
  PagedResult<Booking> get pagedBookings => _pagedBookings;
  List<Booking> get bookings => _pagedBookings.items;

  // ─── Public API ─────────────────────────────────────────────────────────

  // Backend expects BookingSearch.Status as enum name (case-insensitive). Map our UI enum to backend casing.
  void setStatusFilter(BookingStatus? status) {
    if (status == null) {
      _filters.remove('Status');
    } else {
      // Map to PascalCase to match C# enum names
      final map = {
        BookingStatus.upcoming: 'Upcoming',
        BookingStatus.active: 'Active',
        BookingStatus.completed: 'Completed',
        BookingStatus.cancelled: 'Cancelled',
      };
      _filters['Status'] = map[status];
    }
    _page = 1;
    notifyListeners();
  }

  void setPage(int value) {
    _page = value.clamp(1, 1 << 30);
    notifyListeners();
  }

  void setPageSize(int value) {
    _pageSize = value.clamp(5, 200);
    _page = 1;
    notifyListeners();
  }

  Future<void> getPagedBookings({Map<String, dynamic>? params}) async {
    await _fetchPaged(params: params);
  }

  Future<void> refresh() async {
    await _fetchPaged(params: lastQuery);
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

  // ─── Data Fetching ─────────────────────────────────────────────────────

  Future<PagedResult<Booking>> _fetchPaged({Map<String, dynamic>? params}) async {
    final qp = {...?params};
    _sortBy = (qp['sortBy'] as String?) ?? _sortBy;
    _ascending = (qp['ascending'] as bool?) ?? _ascending;
    _page = (qp['page'] as int?) ?? _page;
    _pageSize = (qp['pageSize'] as int?) ?? _pageSize;
    final known = {'sortBy', 'ascending', 'page', 'pageSize'};
    _filters = Map<String, dynamic>.fromEntries(qp.entries.where((e) => !known.contains(e.key)));

    PagedResult<Booking>? result;
    final fetchResult = await executeWithState<PagedResult<Booking>>(() async {
      final query = {
        ..._filters,
        if (_sortBy != null) 'sortBy': _sortBy!,
        'ascending': _ascending,
        'page': _page,
        'pageSize': _pageSize,
      };
      // Align with backend route: BookingsController is annotated with [Route("api/[controller]")] => /api/Bookings
      _pagedBookings = await api.getPagedAndDecode<Booking>('api/Bookings${api.buildQueryString(query)}', Booking.fromJson, authenticated: true);
      return _pagedBookings;
    });
    if (fetchResult != null) {
      result = fetchResult;
      notifyListeners();
    }
    return result ?? PagedResult.empty();
  }
}
