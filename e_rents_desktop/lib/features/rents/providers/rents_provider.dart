import 'dart:convert';
import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/base/api_service_extensions.dart';
import 'package:e_rents_desktop/models/booking.dart';
import 'package:e_rents_desktop/models/paged_result.dart';
import 'package:e_rents_desktop/models/enums/booking_status.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/enums/renting_type.dart';
import 'package:e_rents_desktop/models/tenant.dart';
import 'package:e_rents_desktop/models/lease_extension_request.dart';

class RentsProvider extends BaseProvider {
  RentsProvider(super.api);

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
        BookingStatus.pending: 'Pending',
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

  /// Helper to find the most recent booking for a given tenant (userId) and property
  /// Returns bookingId or null if none exist
  Future<int?> getLatestBookingIdForTenantProperty(int userId, int propertyId) async {
    final paged = await executeWithState<PagedResult<Booking>>(() async {
      final query = {
        'UserId': userId.toString(),
        'PropertyId': propertyId.toString(),
        'SortBy': 'createdat',
        'SortDirection': 'desc',
        'Page': '1',
        'PageSize': '1',
      };
      return await api.getPagedAndDecode<Booking>(
        '/Bookings${api.buildQueryString(query)}',
        Booking.fromJson,
        authenticated: true,
      );
    });

    if (paged != null && paged.items.isNotEmpty) {
      return paged.items.first.bookingId;
    }
    return null;
  }

  Future<void> approveBooking(int bookingId) async {
    final success = await executeWithState<bool>(() async {
      await api.post('/Bookings/$bookingId/approve', {}, authenticated: true);
      return true;
    });

    if (success == true) {
      await refresh();
    }
  }

  Future<void> rejectBooking(int bookingId, {String? reason}) async {
    final success = await executeWithState<bool>(() async {
      final body = <String, dynamic>{};
      if (reason != null && reason.isNotEmpty) {
        body['reason'] = reason;
      }
      await api.post('/Bookings/$bookingId/reject', body, authenticated: true);
      return true;
    });

    if (success == true) {
      await refresh();
    }
  }

  // ─── Lease Extension Requests ───────────────────────────────────────────

  Future<List<LeaseExtensionRequest>> getExtensionRequests({String status = 'Pending'}) async {
    final list = await executeWithState<List<LeaseExtensionRequest>>(() async {
      final items = await api.getListAndDecode<LeaseExtensionRequest>(
        '/LeaseExtensions?status=$status',
        (j) => LeaseExtensionRequest.fromJson(j),
        authenticated: true,
      );
      return items;
    });
    return list ?? <LeaseExtensionRequest>[];
  }

  Future<bool> approveExtension(int requestId) async {
    final ok = await executeWithState<bool>(() async {
      await api.post('/LeaseExtensions/$requestId/approve', {}, authenticated: true);
      return true;
    });
    if (ok == true) {
      await refresh();
      return true;
    }
    return false;
  }

  Future<bool> rejectExtension(int requestId, {String? reason}) async {
    final ok = await executeWithState<bool>(() async {
      await api.post('/LeaseExtensions/$requestId/reject', {
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      }, authenticated: true);
      return true;
    });
    if (ok == true) {
      await refresh();
      return true;
    }
    return false;
  }

  /// Offer a lease extension to a tenant (owner-initiated).
  /// Sends email notification to the tenant.
  Future<Map<String, dynamic>?> offerLeaseExtension({
    required int bookingId,
    int? extendByMonths,
    DateTime? newEndDate,
    double? newMonthlyAmount,
    String? message,
  }) async {
    final result = await executeWithState<Map<String, dynamic>>(() async {
      final body = <String, dynamic>{};
      if (extendByMonths != null) body['extendByMonths'] = extendByMonths;
      if (newEndDate != null) body['newEndDate'] = newEndDate.toIso8601String().split('T').first;
      if (newMonthlyAmount != null) body['newMonthlyAmount'] = newMonthlyAmount;
      if (message != null && message.isNotEmpty) body['message'] = message;

      final response = await api.post(
        '/LeaseExtensions/offer/$bookingId',
        body,
        authenticated: true,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(errorJson['error'] ?? 'Failed to send extension offer');
      }
    });
    return result;
  }

  /// Terminate a lease (cancel booking with reason).
  /// Sends email notification to the tenant.
  Future<Map<String, dynamic>?> terminateLease({
    required int bookingId,
    String? reason,
    DateTime? cancellationDate,
  }) async {
    final result = await executeWithState<Map<String, dynamic>>(() async {
      final body = <String, dynamic>{};
      if (reason != null && reason.isNotEmpty) body['reason'] = reason;
      if (cancellationDate != null) body['cancellationDate'] = cancellationDate.toIso8601String().split('T').first;

      final response = await api.post(
        '/Bookings/$bookingId/cancel',
        body,
        authenticated: true,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(errorJson['error'] ?? 'Failed to terminate lease');
      }
    });
    
    if (result != null) {
      await refresh();
    }
    return result;
  }

  /// Fetch payment history for a specific tenant.
  Future<List<Map<String, dynamic>>> getTenantPaymentHistory(int tenantId) async {
    final result = await executeWithState<List<Map<String, dynamic>>>(() async {
      final response = await api.get(
        '/Payments?TenantId=$tenantId&SortBy=createdat&SortDirection=desc',
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json is Map && json.containsKey('items')) {
          return (json['items'] as List).cast<Map<String, dynamic>>();
        } else if (json is List) {
          return json.cast<Map<String, dynamic>>();
        }
        return <Map<String, dynamic>>[];
      } else {
        throw Exception('Failed to fetch payment history');
      }
    });
    return result ?? <Map<String, dynamic>>[];
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

  Future<void> rejectTenantRequest(int tenantId) async {
    final success = await executeWithState<bool>(() async {
      await api.post('/Tenants/$tenantId/reject', {}, authenticated: true);
      return true;
    });

    if (success == true) {
      await refresh();
    }
  }

  /// Sends an invoice/payment request to the tenant for a subscription.
  /// Creates a pending payment and sends both in-app notification and email.
  /// Returns a map with: success, paymentId, notificationSent, emailSent, message
  Future<Map<String, dynamic>?> sendInvoice({
    required int subscriptionId,
    required double amount,
    String? description,
    DateTime? dueDate,
  }) async {
    final result = await executeWithState<Map<String, dynamic>>(() async {
      final body = {
        'amount': amount,
        if (description != null) 'description': description,
        if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
      };
      final response = await api.post(
        '/Subscriptions/$subscriptionId/send-invoice',
        body,
        authenticated: true,
      );
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json;
      } else {
        final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(errorJson['error'] ?? 'Failed to send invoice');
      }
    });
    
    return result;
  }

  /// Gets the subscription ID for a tenant if one exists
  Future<int?> getSubscriptionIdForTenant(int tenantId) async {
    final result = await executeWithState<int?>(() async {
      // Query subscriptions endpoint filtered by tenantId
      final response = await api.get(
        '/Subscriptions?tenantId=$tenantId&status=Active',
        authenticated: true,
      );
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json is List && json.isNotEmpty) {
          return json.first['subscriptionId'] as int?;
        }
      }
      return null;
    });
    
    return result;
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
