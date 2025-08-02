import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/base/api_service_extensions.dart';
import 'package:e_rents_desktop/models/booking.dart';
import 'package:e_rents_desktop/models/paged_result.dart';
import 'package:e_rents_desktop/models/rental_request.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum RentalType { stay, lease }

class RentsProvider extends BaseProvider {
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
    return await _performAction(
      () => api.postJson('api/rental-requests/$requestId/approve', {'response': response}, authenticated: true),
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
      () => api.postJson('api/rental-requests/$requestId/reject', {'response': response}, authenticated: true),
      'rejectLease',
    );
  }

  // ─── Compatibility Methods for Widgets ────────────────────────────────
  
  Future<void> getPagedStays({Map<String, dynamic>? params}) async {
    await fetchData(params ?? {}, RentalType.stay);
  }

  Future<void> getPagedLeases({Map<String, dynamic>? params}) async {
    await fetchData(params ?? {}, RentalType.lease);
  }

  // ─── Data Fetching Methods ────────────────────────────────────────────

  Future<PagedResult<dynamic>> fetchData(Map<String, dynamic> queryParams, RentalType type) async {
    PagedResult<dynamic> result = PagedResult.empty();
    final fetchResult = await executeWithState<PagedResult<dynamic>>(() async {
      if (type == RentalType.stay) {
        _stayPagedResult = await api.getPagedAndDecode<Booking>('api/booking${api.buildQueryString(queryParams)}', Booking.fromJson, authenticated: true);
        return _stayPagedResult;
      } else {
        _leasePagedResult = await api.getPagedAndDecode<RentalRequest>('/api/rental-requests${api.buildQueryString(queryParams)}', RentalRequest.fromJson, authenticated: true);
        return _leasePagedResult;
      }
    });
    
    if (fetchResult != null) {
      result = fetchResult;
      notifyListeners();
    }
    return result;
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

  Future<bool> _performAction(Future<dynamic> Function() apiCall, String key) async {
    final result = await executeWithState<dynamic>(() async {
      return await apiCall();
    });
    return result != null;
  }

  // Column definitions removed as UniversalTableConfig is removed
  // Map<String, String> _getColumnLabels(bool isStay) { ... }
  // Map<String, Widget Function(dynamic)> _getCellBuilders(bool isStay, BuildContext context) { ... }
}
