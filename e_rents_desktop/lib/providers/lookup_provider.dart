import 'dart:convert';
import 'package:e_rents_desktop/models/lookup_data.dart';
import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/base/api_service_extensions.dart';

/// Refactored LookupProvider using the new base provider architecture
/// 
/// This demonstrates how to use:
/// - BaseProvider for common functionality
/// - Automatic state management (loading, error)
/// - API service extensions for cleaner code
class LookupProvider extends BaseProvider {
  LookupProvider(super.api);

  // ─── State ──────────────────────────────────────────────────────────────
  LookupData? _lookupData;
  
  // ─── Getters ────────────────────────────────────────────────────────────
  LookupData? get lookupData => _lookupData;
  bool get hasData => _lookupData != null;

  // Property types for dropdowns - all derived from cached data
  List<LookupItem> get propertyTypes => _lookupData?.propertyTypes ?? [];
  List<LookupItem> get rentingTypes => _lookupData?.rentingTypes ?? [];
  List<LookupItem> get propertyStatuses => _lookupData?.propertyStatuses ?? [];
  List<LookupItem> get userTypes => _lookupData?.userTypes ?? [];
  List<LookupItem> get bookingStatuses => _lookupData?.bookingStatuses ?? [];
  List<LookupItem> get issuePriorities => _lookupData?.issuePriorities ?? [];
  List<LookupItem> get issueStatuses => _lookupData?.issueStatuses ?? [];
  List<LookupItem> get amenities => _lookupData?.amenities ?? [];

  // ─── Public API ─────────────────────────────────────────────────────────

  /// Initialize lookup data on app startup
  Future<void> initializeLookupData() async {
    if (_lookupData != null) {
      return; // Already initialized
    }

    await loadLookupData();
  }

  /// Load lookup data with state management
  /// The BaseProvider handles loading states and error handling automatically
  Future<void> loadLookupData({bool forceRefresh = false}) async {
    final data = await executeWithState(
      () => _fetchLookupData(),
      errorMessage: 'Failed to load lookup data',
    );

    if (data != null) {
      _lookupData = data;
      notifyListeners();
    }
  }

  /// Refresh lookup data from backend
  /// Forces fresh data fetch
  Future<void> refreshLookupData() async {
    await loadLookupData(forceRefresh: true);
  }

  /// Clear and reload lookup data
  Future<void> clearCacheAndReload() async {
    _lookupData = null;
    await loadLookupData(forceRefresh: true);
  }

  // ─── Convenience Methods ───────────────────────────────────────────────

  /// Get property type name by ID
  String getPropertyTypeName(int id) {
    final item = _lookupData?.getPropertyTypeById(id);
    return item?.name ?? 'Unknown';
  }

  /// Get renting type name by ID
  String getRentingTypeName(int id) {
    final item = _lookupData?.getRentingTypeById(id);
    return item?.name ?? 'Unknown';
  }

  /// Get property status name by ID
  String getPropertyStatusName(int id) {
    final item = _lookupData?.getPropertyStatusById(id);
    return item?.name ?? 'Unknown';
  }

  /// Get booking status name by ID
  String getBookingStatusName(int id) {
    final item = _lookupData?.getBookingStatusById(id);
    return item?.name ?? 'Unknown';
  }

  /// Get issue priority name by ID
  String getIssuePriorityName(int id) {
    final item = _lookupData?.getIssuePriorityById(id);
    return item?.name ?? 'Unknown';
  }

  /// Get issue status name by ID
  String getIssueStatusName(int id) {
    final item = _lookupData?.getIssueStatusById(id);
    return item?.name ?? 'Unknown';
  }

  /// Get user type name by ID
  String getUserTypeName(int id) {
    final item = _lookupData?.getUserTypeById(id);
    return item?.name ?? 'Unknown';
  }

  /// Get amenity name by ID
  String getAmenityName(int id) {
    final item = _lookupData?.getAmenityById(id);
    return item?.name ?? 'Unknown';
  }

  /// Get amenity names by IDs
  List<String> getAmenityNames(List<int> ids) {
    return ids.map((id) => getAmenityName(id)).toList();
  }

  // ─── Individual Enum Methods ───────────────────────────────────────────────

  /// Fetch property types from the new enum endpoint
  Future<List<LookupItem>> getPropertyTypesEnum() async {
    final result = await executeWithState(() async {
      return await api.getListAndDecode(
        '/lookup/enums/PropertyTypeEnum',
        LookupItem.fromJson,
        authenticated: true,
        customHeaders: api.desktopHeaders,
      );
    });
    return result ?? [];
  }

  /// Fetch renting types from the new enum endpoint
  Future<List<LookupItem>> getRentingTypesEnum() async {
    final result = await executeWithState(() async {
      return await api.getListAndDecode(
        '/lookup/enums/RentalType',
        LookupItem.fromJson,
        authenticated: true,
        customHeaders: api.desktopHeaders,
      );
    });
    return result ?? [];
  }

  /// Fetch property statuses from the new enum endpoint
  Future<List<LookupItem>> getPropertyStatusesEnum() async {
    final result = await executeWithState(() async {
      return await api.getListAndDecode(
        '/lookup/enums/PropertyStatusEnum',
        LookupItem.fromJson,
        authenticated: true,
        customHeaders: api.desktopHeaders,
      );
    });
    return result ?? [];
  }

  /// Fetch user types from the new enum endpoint
  Future<List<LookupItem>> getUserTypesEnum() async {
    final result = await executeWithState(() async {
      return await api.getListAndDecode(
        '/lookup/enums/UserTypeEnum',
        LookupItem.fromJson,
        authenticated: true,
        customHeaders: api.desktopHeaders,
      );
    });
    return result ?? [];
  }

  /// Fetch booking statuses from the new enum endpoint
  Future<List<LookupItem>> getBookingStatusesEnum() async {
    final result = await executeWithState(() async {
      return await api.getListAndDecode(
        '/lookup/enums/BookingStatusEnum',
        LookupItem.fromJson,
        authenticated: true,
        customHeaders: api.desktopHeaders,
      );
    });
    return result ?? [];
  }

  /// Fetch all available enum types
  Future<List<String>> getAvailableEnumTypes() async {
    final result = await executeWithState(() async {
      final response = await api.get(
        '/lookup/enums',
        authenticated: true,
        customHeaders: api.desktopHeaders,
      );
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.cast<String>().toList();
    });
    return result ?? [];
  }

  /// Get lookup data status information
  Map<String, dynamic> getLookupDataStatus() {
    return {
      'lookupDataLoaded': _lookupData != null,
    };
  }

  // ─── Private Methods ────────────────────────────────────────────────────

  /// Fetch lookup data from API
  /// Uses the new API service extensions for cleaner code
  Future<LookupData> _fetchLookupData() async {
    // Using the API service extension for automatic JSON decoding
    return await api.getAndDecode(
      '/lookup/all',
      LookupData.fromJson,
      authenticated: true,
      customHeaders: api.desktopHeaders,
    );
  }
}

// Helper class for dropdown items (unchanged)
class DropdownItem {
  final int value;
  final String label;

  const DropdownItem({required this.value, required this.label});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DropdownItem &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'DropdownItem(value: $value, label: $label)';
}
