import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/base/api_service_extensions.dart';
import 'package:e_rents_desktop/models/booking.dart';
import 'package:e_rents_desktop/models/paged_result.dart';
import 'package:e_rents_desktop/models/enums/booking_status.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/enums/renting_type.dart';
import 'package:e_rents_desktop/models/tenant.dart';
import 'package:flutter/material.dart';

class RentsProvider extends BaseProvider {
  RentsProvider(super.api, {required this.context});

  final BuildContext context;

  // ─── Standardized State (per Playbook) ──────────────────────────────────
  Map<String, dynamic> _filters = {};
  String? _sortBy = 'startdate';
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
        'sortDirection': _ascending ? 'asc' : 'desc',
        'page': _page,
        'pageSize': _pageSize,
      };

  PagedResult<Booking> _pagedBookings = PagedResult.empty();
  PagedResult<Booking> get pagedBookings => _pagedBookings;
  List<Booking> get bookings => _pagedBookings.items;

  // Tenant data for monthly rentals
  PagedResult<Tenant> _pagedTenants = PagedResult.empty();
  PagedResult<Tenant> get pagedTenants => _pagedTenants;
  List<Tenant> get tenants => _pagedTenants.items;

  // Cache of property renting types to enable displaying contract type without backend changes
  final Map<int, RentingType> _propertyRentingType = {};
  RentingType? rentingTypeFor(int? propertyId) => propertyId == null ? null : _propertyRentingType[propertyId];

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

  Future<void> getPagedTenants({Map<String, dynamic>? params}) async {
    await _fetchPagedTenants(params: params);
  }

  Future<void> refresh() async {
    await _fetchPaged(params: lastQuery);
  }

  void applyFilters(Map<String, dynamic> map) {
    _filters = {..._filters, ...map};
    notifyListeners();
  }

  Future<void> cancelBooking(int bookingId) async {
    final success = await executeWithState<bool>(() async {
      await api.post('/Bookings/$bookingId/cancel', {}, authenticated: true);
      return true;
    });

    if (success == true) {
      await refresh();
    }
  }

  Future<void> acceptTenantRequest(int tenantId, int propertyId) async {
    final success = await executeWithState<bool>(() async {
      // Use the new atomic endpoint to accept tenant and reject others
      await api.post('/Tenants/$tenantId/accept-and-reject-others', {}, authenticated: true);
      return true;
    });

    if (success == true) {
      await refresh();
    }
  }


  void clearFilters() {
    _filters = {};
    _page = 1;
    notifyListeners();
  }

  /// Get the booking status for a tenant based on their lease dates and current date
  String getTenantBookingStatus(Tenant tenant) {
    // If tenant is evicted or lease ended, show as canceled
    if (tenant.tenantStatus == TenantStatus.evicted || tenant.tenantStatus == TenantStatus.leaseEnded) {
      return 'Canceled';
    }
    
    // If tenant is inactive, they are requested
    if (tenant.tenantStatus == TenantStatus.inactive) {
      return 'Requested';
    }
    
    // For active tenants, determine status based on dates
    if (tenant.tenantStatus == TenantStatus.active) {
      final now = DateTime.now();
      
      // If lease has ended, show as completed
      if (tenant.leaseEndDate != null && tenant.leaseEndDate!.isBefore(now)) {
        return 'Completed';
      }
      
      // If lease has started, show as active
      if (tenant.leaseStartDate != null && !tenant.leaseStartDate!.isAfter(now)) {
        return 'Active';
      }
      
      // If lease hasn't started yet, show as upcoming
      if (tenant.leaseStartDate != null && tenant.leaseStartDate!.isAfter(now)) {
        return 'Upcoming';
      }
    }
    
    // Default to the tenant status display name
    return tenant.tenantStatus.displayName;
  }

  // ─── Data Fetching ─────────────────────────────────────────────────────

  Future<PagedResult<Booking>> _fetchPaged({Map<String, dynamic>? params}) async {
    final qp = {...?params};
    final incomingSort = (qp['sortBy'] as String?)?.trim();
    // Backend expects lowercase sort fields: startdate, totalprice, createdat, updatedat
    _sortBy = (incomingSort?.toLowerCase() ?? _sortBy);
    // Accept either legacy 'ascending' (bool) or new 'sortDirection' (asc|desc)
    if (qp.containsKey('ascending') && qp['ascending'] is bool) {
      _ascending = qp['ascending'] as bool;
    }
    final sd = qp['sortDirection'] as String?;
    if (sd != null) {
      _ascending = sd.toLowerCase() != 'desc';
    }
    _page = (qp['page'] as int?) ?? _page;
    _pageSize = (qp['pageSize'] as int?) ?? _pageSize;
    final known = {'sortBy', 'ascending', 'sortDirection', 'page', 'pageSize'};
    _filters = Map<String, dynamic>.fromEntries(qp.entries.where((e) => !known.contains(e.key)));

    PagedResult<Booking>? result;
    final fetchResult = await executeWithState<PagedResult<Booking>>(() async {
      final query = {
        ..._filters,
        if (_sortBy != null) 'sortBy': _sortBy!,
        'sortDirection': _ascending ? 'asc' : 'desc',
        'page': _page,
        'pageSize': _pageSize,
      };
      // Align with backend route: BookingsController is annotated with [Route("api/[controller]")] => Bookings
      _pagedBookings = await api.getPagedAndDecode<Booking>('/Bookings${api.buildQueryString(query)}', Booking.fromJson, authenticated: true);
      return _pagedBookings;
    });
    if (fetchResult != null) {
      result = fetchResult;
      // Hydrate property renting types for current page so UI can display contract type
      await _hydrateRentingTypes(fetchResult.items);
      notifyListeners();
    }
    return result ?? PagedResult.empty();
  }

  Future<PagedResult<Tenant>> _fetchPagedTenants({Map<String, dynamic>? params}) async {
    final qp = {...?params};
    final incomingSort = (qp['sortBy'] as String?)?.trim();
    // Backend expects lowercase sort fields: leasestartdate, leaseenddate, createdat, updatedat
    _sortBy = (incomingSort?.toLowerCase() ?? _sortBy);
    // Accept either legacy 'ascending' (bool) or new 'sortDirection' (asc|desc)
    if (qp.containsKey('ascending') && qp['ascending'] is bool) {
      _ascending = qp['ascending'] as bool;
    }
    final sd = qp['sortDirection'] as String?;
    if (sd != null) {
      _ascending = sd.toLowerCase() != 'desc';
    }
    _page = (qp['page'] as int?) ?? _page;
    _pageSize = (qp['pageSize'] as int?) ?? _pageSize;
    final known = {'sortBy', 'ascending', 'sortDirection', 'page', 'pageSize'};
    _filters = Map<String, dynamic>.fromEntries(qp.entries.where((e) => !known.contains(e.key)));

    PagedResult<Tenant>? result;
    final fetchResult = await executeWithState<PagedResult<Tenant>>(() async {
      final query = {
        ..._filters,
        if (_sortBy != null) 'sortBy': _sortBy!,
        'sortDirection': _ascending ? 'asc' : 'desc',
        'page': _page,
        'pageSize': _pageSize,
      };
      // Align with backend route: TenantsController is annotated with [Route("api/[controller]")] => Tenants
      _pagedTenants = await api.getPagedAndDecode<Tenant>('/Tenants${api.buildQueryString(query)}', Tenant.fromJson, authenticated: true);
      return _pagedTenants;
    });
    if (fetchResult != null) {
      result = fetchResult;
      notifyListeners();
    }
    return result ?? PagedResult.empty();
  }

  Future<void> _hydrateRentingTypes(List<Booking> items) async {
    // Collect unique property IDs missing in cache
    final ids = <int>{};
    for (final b in items) {
      final pid = b.propertyId;
      if (pid != null && !_propertyRentingType.containsKey(pid)) {
        ids.add(pid);
      }
    }
    // Fetch sequentially to keep it simple; cache results
    for (final id in ids) {
      try {
        final prop = await api.getAndDecode<Property>('/Properties/$id', Property.fromJson, authenticated: true);
        final rt = prop.rentingType;
        if (rt != null) {
          _propertyRentingType[id] = rt;
        }
      } catch (_) {
        // ignore; leave missing
      }
    }
  }
}
