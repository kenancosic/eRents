import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/base/api_service_extensions.dart';
import 'package:e_rents_desktop/models/booking.dart';
import 'package:e_rents_desktop/models/paged_result.dart';
import 'package:e_rents_desktop/models/rental_request.dart';
import 'package:e_rents_desktop/widgets/table/custom_table.dart';
import 'package:e_rents_desktop/widgets/table/providers/base_table_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum RentalType { stay, lease }

class RentsProvider extends BaseProvider implements BaseTableProvider<dynamic> {
  RentsProvider(super.api, {required this.context});

  final BuildContext context;

  // ─── State ──────────────────────────────────────────────────────────────
  RentalType _currentType = RentalType.stay;
  RentalType get currentType => _currentType;

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

  Future<void> getStayById(int id) async {
    final result = await executeWithState<Booking>(() async {
      return await api.getAndDecode('/bookings/$id', Booking.fromJson, authenticated: true);
    });
    
    if (result != null) {
      _selectedStay = result;
      notifyListeners();
    }
  }

  Future<void> getLeaseById(int id) async {
    final result = await executeWithState<RentalRequest>(() async {
      return await api.getAndDecode('/rental-requests/$id', RentalRequest.fromJson, authenticated: true);
    });
    
    if (result != null) {
      _selectedLease = result;
      notifyListeners();
    }
  }

  Future<bool> cancelStay(int bookingId, String reason) async {
    return await _performAction(
      () => api.postJson('/bookings/$bookingId/cancel', {'reason': reason}, authenticated: true),
      'cancelStay',
    );
  }

  // Backward compatibility method for cancelStay without parameters
  Future<bool> cancelSelectedStay() async {
    if (_selectedStay?.bookingId == null) return false;
    return await cancelStay(_selectedStay!.bookingId, 'Cancelled by admin');
  }

  Future<bool> approveLease(int requestId, String response) async {
    return await _performAction(
      () => api.postJson('/rental-requests/$requestId/approve', {'response': response}, authenticated: true),
      'approveLease',
    );
  }

  // Backward compatibility method for approveLease with named parameters
  Future<bool> approveSelectedLease({String? response}) async {
    if (_selectedLease?.requestId == null) return false;
    return await approveLease(_selectedLease!.requestId, response ?? 'Approved');
  }

  Future<bool> rejectLease(int requestId, String response) async {
    return await _performAction(
      () => api.postJson('/rental-requests/$requestId/reject', {'response': response}, authenticated: true),
      'rejectLease',
    );
  }

  // ─── Compatibility Methods for Widgets ────────────────────────────────

  Future<void> getPagedStays() async {
    await fetchData(TableQuery(page: 1, pageSize: 20));
  }

  Future<void> getPagedLeases() async {
    await fetchData(TableQuery(page: 1, pageSize: 20));
  }

  // ─── BaseTableProvider Interface Implementation ────────────────────────
  
  @override
  List<TableColumnConfig<dynamic>> get columns {
    final isStay = _currentType == RentalType.stay;
    final columnLabels = _getColumnLabels(isStay);
    return columnLabels.entries.map((entry) => 
      TableColumnConfig<dynamic>(
        key: entry.key,
        label: entry.value,
        cellBuilder: (item) => Text(item.toString()),
      )
    ).toList();
  }
  
  @override
  List<TableFilter> get availableFilters {
    return [
      TableFilter(
        key: 'status',
        label: 'Status',
        type: FilterType.dropdown,
        options: [],
      ),
      TableFilter(
        key: 'dates',
        label: 'Date Range',
        type: FilterType.dateRange,
        options: [],
      ),
    ];
  }
  
  @override
  String get emptyStateMessage {
    return _currentType == RentalType.stay ? 'No stays found.' : 'No leases found.';
  }

  // ─── Table Provider Methods ────────────────────────────────────────────

  Future<PagedResult<dynamic>> fetchData(TableQuery query) async {
    PagedResult<dynamic> result = PagedResult.empty();
    final fetchResult = await executeWithState<PagedResult<dynamic>>(() async {
      if (_currentType == RentalType.stay) {
        _stayPagedResult = await api.getPagedAndDecode<Booking>('/bookings${api.buildQueryString(query.toQueryParams())}', Booking.fromJson, authenticated: true);
        return _stayPagedResult;
      } else {
        _leasePagedResult = await api.getPagedAndDecode<RentalRequest>('/rental-requests${api.buildQueryString(query.toQueryParams())}', RentalRequest.fromJson, authenticated: true);
        return _leasePagedResult;
      }
    });
    
    if (fetchResult != null) {
      result = fetchResult;
      notifyListeners();
    }
    return result;
  }

  UniversalTableConfig getTableConfig(BuildContext tableContext) {
    final isStay = _currentType == RentalType.stay;
    return UniversalTableConfig(
      title: isStay ? 'Stays' : 'Leases',
      searchHint: isStay ? 'Search stays...' : 'Search leases...',
      emptyStateMessage: isStay ? 'No stays found.' : 'No leases found.',
      columnLabels: _getColumnLabels(isStay),
      customCellBuilders: _getCellBuilders(isStay, tableContext),
      onRowTap: (item) => navigateToDetail(tableContext, item),
    );
  }

  void navigateToDetail(BuildContext context, dynamic item) {
    if (item is Booking) {
      context.push('/stays/${item.bookingId}');
    } else if (item is RentalRequest) {
      context.push('/leases/${item.requestId}');
    }
  }

  // ─── Private Helpers ────────────────────────────────────────────────────

  Future<bool> _performAction(Future<dynamic> Function() apiCall, String key) async {
    final result = await executeWithState<dynamic>(() async {
      return await apiCall();
    });
    return result != null;
  }

  Map<String, String> _getColumnLabels(bool isStay) {
    return isStay
        ? {'property': 'Property', 'tenant': 'Tenant', 'dates': 'Dates', 'status': 'Status', 'total': 'Total'}
        : {'property': 'Property', 'tenant': 'Tenant', 'dates': 'Dates', 'status': 'Status'};
  }

  Map<String, Widget Function(dynamic)> _getCellBuilders(bool isStay, BuildContext context) {
    if (isStay) {
      return {
        'property': (item) => Text(item.property?.name ?? 'N/A'),
        'tenant': (item) => Text(item.user?.fullName ?? 'N/A'),
        'dates': (item) => Text('${item.checkInDate} - ${item.checkOutDate}'),
        'status': (item) => Text(item.status ?? 'N/A'),
        'total': (item) => Text('\$${item.totalPrice?.toStringAsFixed(2) ?? '0.00'}'),
      };
    } else {
      return {
        'property': (item) => Text(item.property?.name ?? 'N/A'),
        'tenant': (item) => Text(item.user?.fullName ?? 'N/A'),
        'dates': (item) => Text('${item.leaseStartDate} - ${item.leaseEndDate}'),
        'status': (item) => Text(item.status ?? 'N/A'),
      };
    }
  }
}
