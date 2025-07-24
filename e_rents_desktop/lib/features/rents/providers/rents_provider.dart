import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/booking.dart';
import '../../../models/paged_result.dart';
import '../../../models/rental_request.dart';
import '../../../services/api_service.dart';
import '../../../widgets/table/custom_table.dart';

/// Consolidated provider for all rental types (short-term stays and long-term leases)
/// following the canonical provider-only architecture
class RentsProvider extends ChangeNotifier implements BaseTableProvider<dynamic> {
  final ApiService _api;
  final BuildContext context;
  
  // API endpoints
  final String _bookingEndpoint = '/bookings';
  final String _leaseEndpoint = '/rental-requests';
  
  // Current state
  bool _isLoading = false;
  String? _error;
  RentalType _currentType = RentalType.stay;
  
  // Table context and filters
  BuildContext? _currentContext;
  // Filter state managed via fetchData parameters
  RentalType get currentType => _currentType;
  
  RentsProvider(this._api, {required this.context}) {
    _currentContext = context;
  }

  // ─── State ──────────────────────────────────────────────────────────────
  bool get isLoading => _isLoading;

  String? get error => _error;

  // Stay (booking) state
  List<Booking> _stays = [];
  List<Booking> get stays => _stays;
  
  Booking? _selectedStay;
  Booking? get selectedStay => _selectedStay;
  
  PagedResult<Booking> _stayPagedResult = PagedResult(
    items: [],
    totalCount: 0,
    page: 1,
    pageSize: 10,
  );
  PagedResult<Booking> get stayPagedResult => _stayPagedResult;
  
  // Lease (rental request) state
  List<RentalRequest> _leases = [];
  List<RentalRequest> get leases => _leases;
  
  RentalRequest? _selectedLease;
  RentalRequest? get selectedLease => _selectedLease;
  
  PagedResult<RentalRequest> _leasePagedResult = PagedResult(
    items: [],
    totalCount: 0,
    page: 1,
    pageSize: 10,
  );
  PagedResult<RentalRequest> get leasePagedResult => _leasePagedResult;
  
  // Action state (previously in separate StayActionState and LeaseActionState)
  bool _isActionInProgress = false;
  bool get isActionInProgress => _isActionInProgress;
  
  // Controllers for action dialogs
  final TextEditingController cancelReasonController = TextEditingController();
  final TextEditingController additionalNotesController = TextEditingController();
  final TextEditingController responseController = TextEditingController();

  // ─── Public API ─────────────────────────────────────────────────────────

  /// Set the current rental type (stay or lease)
  void setRentalType(RentalType type) {
    if (_currentType != type) {
      _currentType = type;
      notifyListeners();
    }
  }
  
  /// Get paged stays (bookings)
  Future<void> getPagedStays({Map<String, dynamic>? params}) async {
    _setLoading(true);
    try {
      String queryString = '';
      if (params != null && params.isNotEmpty) {
        queryString = '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
      }
      final fullEndpoint = '$_bookingEndpoint$queryString';

      final response = await _api.get(fullEndpoint, authenticated: true);
      final data = json.decode(response.body);
      _stayPagedResult = PagedResult<Booking>.fromJson(
        data, 
        (json) => Booking.fromJson(json as Map<String, dynamic>)
      );
      _stays = _stayPagedResult.items;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  /// Get paged leases (rental requests)
  Future<void> getPagedLeases({Map<String, dynamic>? params}) async {
    _setLoading(true);
    try {
      String queryString = '';
      if (params != null && params.isNotEmpty) {
        queryString = '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
      }
      final fullEndpoint = '$_leaseEndpoint$queryString';

      final response = await _api.get(fullEndpoint, authenticated: true);
      final data = json.decode(response.body);
      _leasePagedResult = PagedResult<RentalRequest>.fromJson(
        data, 
        (json) => RentalRequest.fromJson(json as Map<String, dynamic>)
      );
      _leases = _leasePagedResult.items;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  /// Get stay details by ID
  Future<void> getStayById(String id) async {
    _setLoading(true);
    try {
      final response = await _api.get('$_bookingEndpoint/$id', authenticated: true);
      final data = json.decode(response.body);
      _selectedStay = Booking.fromJson(data);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  /// Get lease details by ID
  Future<void> getLeaseById(String id) async {
    _setLoading(true);
    try {
      final response = await _api.get('$_leaseEndpoint/$id', authenticated: true);
      final data = json.decode(response.body);
      _selectedLease = RentalRequest.fromJson(data);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  /// Cancel a stay (booking)
  Future<bool> cancelStay({
    required String bookingId,
    required String reason,
    bool requestRefund = false,
    String? additionalNotes,
  }) async {
    return _executeAction(() async {
      final Map<String, dynamic> payload = {
        'reason': reason,
        'requestRefund': requestRefund,
        'additionalNotes': additionalNotes,
      };
      
      await _api.post(
        '$_bookingEndpoint/$bookingId/cancel',
        payload,
        authenticated: true,
      );
      
      // Refresh data after successful action
      if (_selectedStay?.bookingId == bookingId) {
        await getStayById(bookingId);
      }
    });
  }
  
  /// Approve a lease (rental request)
  Future<bool> approveLease({
    required String requestId,
    String? response,
  }) async {
    return _executeAction(() async {
      final Map<String, dynamic> payload = {
        'response': response,
      };
      
      await _api.post(
        '$_leaseEndpoint/$requestId/approve',
        payload,
        authenticated: true,
      );
      
      // Refresh data after successful action
      if (_selectedLease?.requestId == requestId) {
        await getLeaseById(requestId);
      }
    });
  }
  
  /// Reject a lease (rental request)
  Future<bool> rejectLease({
    required String requestId,
    String? response,
  }) async {
    return _executeAction(() async {
      final Map<String, dynamic> payload = {
        'response': response,
      };
      
      await _api.post(
        '$_leaseEndpoint/$requestId/reject',
        payload,
        authenticated: true,
      );
      
      // Refresh data after successful action
      if (_selectedLease?.requestId == requestId) {
        await getLeaseById(requestId);
      }
    });
  }
  
  /// Execute an action with loading state and error handling
  Future<bool> _executeAction(Future<void> Function() action) async {
    _isActionInProgress = true;
    _error = null;
    notifyListeners();

    try {
      await action();
      _isActionInProgress = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isActionInProgress = false;
      notifyListeners();
      return false;
    }
  }
  
  // ─── Table Integration ───────────────────────────────────────────────────

  /// Cell builders for table display
  Widget _textCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(text),
    );
  }

  Widget _dateCell(DateTime? date) {
    final displayDate = date != null
        ? '${date.day}/${date.month}/${date.year}'
        : 'N/A';
    return _textCell(displayDate);
  }
  
  Widget _statusCell(String text, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color?.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color ?? Colors.grey),
      ),
      child: Text(
        text,
        style: TextStyle(color: color),
      ),
    );
  }
  
  Widget _actionCell(List<Widget> actions) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: actions,
    );
  }

  Widget _iconActionCell({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }

  Color _getStayStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'upcoming':
        return Colors.blue;
      case 'completed':
        return Colors.purple;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getLeaseStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  // Get stay (booking) table columns
  List<TableColumnConfig<Booking>> _getStayTableColumns(BuildContext tableContext) {
    return [
      TableColumnConfig<Booking>(
        key: 'propertyId',
        label: 'Property',
        cellBuilder: (booking) => _textCell('Property ${booking.propertyId}'),
        width: const FlexColumnWidth(1.5),
      ),
      TableColumnConfig<Booking>(
        key: 'guestName',
        label: 'Guest',
        cellBuilder: (booking) => _textCell(booking.userName ?? 'Guest'),
        width: const FlexColumnWidth(1.5),
      ),
      TableColumnConfig<Booking>(
        key: 'checkIn',
        label: 'Check-in',
        cellBuilder: (booking) => _dateCell(booking.startDate),
        width: const FlexColumnWidth(1.0),
      ),
      TableColumnConfig<Booking>(
        key: 'checkOut',
        label: 'Check-out',
        cellBuilder: (booking) => _dateCell(booking.endDate),
        width: const FlexColumnWidth(1.0),
      ),
      TableColumnConfig<Booking>(
        key: 'status',
        label: 'Status',
        cellBuilder: (booking) {
          final statusText = booking.isActive
              ? 'Active'
              : booking.isUpcoming
                  ? 'Upcoming'
                  : booking.isCompleted
                      ? 'Completed'
                      : 'Cancelled';
          return _statusCell(
            statusText,
            color: _getStayStatusColor(statusText),
          );
        },
        width: const FlexColumnWidth(1.0),
      ),
      TableColumnConfig<Booking>(
        key: 'actions',
        label: 'Actions',
        cellBuilder: (booking) => _actionCell([
          if (tableContext.mounted)
            _iconActionCell(
              icon: Icons.visibility,
              tooltip: 'View Details',
              onPressed: () {
                tableContext.push('/stays/${booking.bookingId}');
              },
            ),
          if ((booking.isActive || booking.isUpcoming) && tableContext.mounted)
            _iconActionCell(
              icon: Icons.cancel,
              tooltip: 'Cancel Booking',
              onPressed: () {
                // Show cancel dialog (to be implemented in UI)
              },
            ),
        ]),
        width: const FlexColumnWidth(0.8),
      ),
    ];
  }
  
  // Get lease (rental request) table columns
  List<TableColumnConfig<RentalRequest>> _getLeaseTableColumns(BuildContext tableContext) {
    return [
      TableColumnConfig<RentalRequest>(
        key: 'propertyId',
        label: 'Property',
        cellBuilder: (lease) => _textCell('Property ${lease.propertyId}'),
        width: const FlexColumnWidth(1.5),
      ),
      TableColumnConfig<RentalRequest>(
        key: 'tenantName',
        label: 'Tenant',
        cellBuilder: (lease) => _textCell(lease.userName),
        width: const FlexColumnWidth(1.5),
      ),
      TableColumnConfig<RentalRequest>(
        key: 'startDate',
        label: 'Start Date',
        cellBuilder: (lease) => _dateCell(lease.proposedStartDate),
        width: const FlexColumnWidth(1.0),
      ),
      TableColumnConfig<RentalRequest>(
        key: 'endDate',
        label: 'End Date',
        cellBuilder: (lease) => _dateCell(lease.proposedEndDate),
        width: const FlexColumnWidth(1.0),
      ),
      TableColumnConfig<RentalRequest>(
        key: 'status',
        label: 'Status',
        cellBuilder: (lease) {
          final statusText = lease.isPending
              ? 'Pending'
              : lease.isApproved
                  ? 'Approved'
                  : 'Rejected';
          return _statusCell(
            statusText,
            color: _getLeaseStatusColor(statusText),
          );
        },
        width: const FlexColumnWidth(1.0),
      ),
      TableColumnConfig<RentalRequest>(
        key: 'actions',
        label: 'Actions',
        cellBuilder: (lease) => _actionCell([
          if (tableContext.mounted)
            _iconActionCell(
              icon: Icons.visibility,
              tooltip: 'View Details',
              onPressed: () {
                tableContext.push('/leases/${lease.requestId}');
              },
            ),
          if (lease.isPending && tableContext.mounted)
            _iconActionCell(
              icon: Icons.check_circle,
              tooltip: 'Approve',
              onPressed: () {
                // Show approve dialog (to be implemented in UI)
              },
            ),
          if (lease.isPending && tableContext.mounted)
            _iconActionCell(
              icon: Icons.cancel,
              tooltip: 'Reject',
              onPressed: () {
                // Show reject dialog (to be implemented in UI)
              },
            ),
        ]),
        width: const FlexColumnWidth(1.2),
      ),
    ];
  }
  
  // Get table filters based on current rental type
  List<TableFilter> _getStayTableFilters() {
    return [
      TableFilter(
        key: 'status',
        label: 'Status',
        type: FilterType.dropdown,
        options: [
          FilterOption(label: 'All', value: ''),
          FilterOption(label: 'Active', value: 'active'),
          FilterOption(label: 'Upcoming', value: 'upcoming'),
          FilterOption(label: 'Completed', value: 'completed'),
          FilterOption(label: 'Cancelled', value: 'cancelled'),
        ],
      ),
      TableFilter(
        key: 'dateRange',
        label: 'Date Range',
        type: FilterType.dropdown,
        options: [
          FilterOption(label: 'All Time', value: ''),
          FilterOption(label: 'This Month', value: 'this_month'),
          FilterOption(label: 'Last 3 Months', value: 'last_3_months'),
          FilterOption(label: 'Last 6 Months', value: 'last_6_months'),
          FilterOption(label: 'This Year', value: 'this_year'),
        ],
      ),
    ];
  }
  
  List<TableFilter> _getLeaseTableFilters() {
    return [
      TableFilter(
        key: 'status',
        label: 'Status',
        type: FilterType.dropdown,
        options: [
          FilterOption(label: 'All', value: ''),
          FilterOption(label: 'Pending', value: 'pending'),
          FilterOption(label: 'Approved', value: 'approved'),
          FilterOption(label: 'Rejected', value: 'rejected'),
        ],
      ),
      TableFilter(
        key: 'dateRange',
        label: 'Date Range',
        type: FilterType.dropdown,
        options: [
          FilterOption(label: 'All Time', value: ''),
          FilterOption(label: 'This Month', value: 'this_month'),
          FilterOption(label: 'Last 3 Months', value: 'last_3_months'),
          FilterOption(label: 'Last 6 Months', value: 'last_6_months'),
          FilterOption(label: 'This Year', value: 'this_year'),
        ],
      ),
    ];
  }
  
  // ─── BaseTableProvider Implementation ─────────────────────────────────────

  @override
  List<TableColumnConfig<dynamic>> get columns {
    // Return appropriate columns based on current rental type
    if (_currentContext != null) {
      return _currentType == RentalType.stay
          ? _getStayTableColumns(_currentContext!)
          : _getLeaseTableColumns(_currentContext!);
    }
    
    // Return empty columns if context is null
    return [];
  }
  
  @override
  List<TableFilter> get availableFilters {
    return _currentType == RentalType.stay
        ? _getStayTableFilters()
        : _getLeaseTableFilters();
  }
  
  @override
  String get emptyStateMessage => 
      _currentType == RentalType.stay 
          ? 'No stays found' 
          : 'No leases found';
          
  @override
  Future<PagedResult<dynamic>> fetchData(TableQuery query) async {
    try {
      // Convert query parameters to API parameters
      final Map<String, dynamic> params = {
        'page': query.page,
        'pageSize': query.pageSize,
      };
      
      // Add search term if present
      final searchTerm = query.searchTerm;
      if (searchTerm != null && searchTerm.isNotEmpty) {
        params['search'] = searchTerm;
      }
      
      // Add filters if present
      final filters = query.filters;
      if (filters.isNotEmpty) {
        for (final filter in filters.entries) {
          params[filter.key] = filter.value;
        }
      }
      
      // Make API call based on current rental type
      if (_currentType == RentalType.stay) {
        final url = _bookingEndpoint;
        final response = await _api.get(
          '$url?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}',
          authenticated: true,
        );
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final pagedResult = PagedResult<Booking>.fromJson(
            data,
            (json) => Booking.fromJson(json),
          );
          
          // Update internal state
          _stays = pagedResult.items;
          _stayPagedResult = pagedResult;
          notifyListeners();
          
          return pagedResult;
        } else {
          throw Exception('Failed to fetch stays: ${response.statusCode}');
        }
      } else {
        final url = _leaseEndpoint;
        final response = await _api.get(
          '$url?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}',
          authenticated: true,
        );
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final pagedResult = PagedResult<RentalRequest>.fromJson(
            data,
            (json) => RentalRequest.fromJson(json),
          );
          
          // Update internal state
          _leases = pagedResult.items;
          _leasePagedResult = pagedResult;
          notifyListeners();
          
          return pagedResult;
        } else {
          throw Exception('Failed to fetch leases: ${response.statusCode}');
        }
      }
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  // Get table configuration for the current rental type
  UniversalTableConfig getTableConfig(BuildContext tableContext) {
    // Select columns based on current rental type
    final tableColumns = _currentType == RentalType.stay
        ? _getStayTableColumns(tableContext)
        : _getLeaseTableColumns(tableContext);

    // Prepare column labels, cell builders, and column widths from column configs
    final Map<String, String> columnLabels = {};
    final Map<String, Widget Function(dynamic)> customCellBuilders = {};
    final Map<String, TableColumnWidth> columnWidths = {};
    
    // Convert column configs to the format expected by UniversalTableConfig
    for (var column in tableColumns) {
      columnLabels[column.key] = column.label;
      // Cast the function to the correct type
      customCellBuilders[column.key] = (dynamic item) => column.cellBuilder(item);
      columnWidths[column.key] = column.width;
    }
    
    return UniversalTableConfig(
      title: _currentType == RentalType.stay ? 'Stays' : 'Leases',
      searchHint: _currentType == RentalType.stay ? 'Search stays...' : 'Search leases...',
      emptyStateMessage: emptyStateMessage,
      columnLabels: columnLabels,
      customCellBuilders: customCellBuilders,
      columnWidths: columnWidths,
      customFilters: _currentType == RentalType.stay
          ? _getStayTableFilters()
          : _getLeaseTableFilters(),
      onRowTap: (item) {
        if (_currentContext?.mounted ?? false) {
          final route = _currentType == RentalType.stay
              ? '/stays/${item.bookingId}'
              : '/leases/${item.requestId}';
          _currentContext?.push(route);
        }
      },
    );
  }

  void updateFilters(Map<String, String> filters) {
    // Apply filters directly to fetchData
    fetchData(TableQuery(
      page: 1,
      pageSize: 10,
      searchTerm: '',
      filters: filters,
    ));
  }
  
  void navigateToDetail(BuildContext context, dynamic item) {
    if (_currentType == RentalType.stay && item is Booking) {
      if (context.mounted) {
        context.push('/stays/${item.bookingId}');
      }
    } else if (_currentType == RentalType.lease && item is RentalRequest) {
      if (context.mounted) {
        context.push('/leases/${item.requestId}');
      }
    }
  }

  // ─── Helpers ────────────────────────────────────────────────────────

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _error = message;
    notifyListeners();
  }
  
  @override
  void dispose() {
    cancelReasonController.dispose();
    additionalNotesController.dispose();
    responseController.dispose();
    super.dispose();
  }
}

// Rental type enum to distinguish between stays and leases
enum RentalType {
  stay,
  lease,
}
