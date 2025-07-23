import 'package:flutter/foundation.dart';
import 'package:e_rents_desktop/models/lookup_data.dart';
import 'package:e_rents_desktop/services/lookup_service.dart';
import 'package:e_rents_desktop/utils/logger.dart';

class LookupProvider with ChangeNotifier {
  final LookupService _lookupService;

  LookupData? _lookupData;
  bool _isLoading = false;
  String? _error;

  LookupProvider(this._lookupService);

  // Getters
  LookupData? get lookupData => _lookupData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasData => _lookupData != null;

  // Property types for dropdowns
  List<LookupItem> get propertyTypes => _lookupData?.propertyTypes ?? [];
  List<LookupItem> get rentingTypes => _lookupData?.rentingTypes ?? [];
  List<LookupItem> get propertyStatuses => _lookupData?.propertyStatuses ?? [];
  List<LookupItem> get userTypes => _lookupData?.userTypes ?? [];
  List<LookupItem> get bookingStatuses => _lookupData?.bookingStatuses ?? [];
  List<LookupItem> get issuePriorities => _lookupData?.issuePriorities ?? [];
  List<LookupItem> get issueStatuses => _lookupData?.issueStatuses ?? [];
  List<LookupItem> get amenities => _lookupData?.amenities ?? [];

  /// Initialize lookup data on app startup
  Future<void> initializeLookupData() async {
    if (_lookupData != null) {
      // Already initialized
      return;
    }

    await loadLookupData(forceRefresh: false);
  }

  /// Load lookup data from backend
  Future<void> loadLookupData({bool forceRefresh = false}) async {
    if (_isLoading) return; // Prevent concurrent loading

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      log.info(
        'LookupProvider: Loading lookup data (forceRefresh: $forceRefresh)',
      );
      _lookupData = await _lookupService.getAllLookupData(
        forceRefresh: forceRefresh,
      );
      log.info(
        'LookupProvider: Successfully loaded ${_lookupData?.propertyTypes.length} property types',
      );
    } catch (e, stackTrace) {
      _error = e.toString();
      log.severe('LookupProvider: Error loading lookup data', e, stackTrace);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh lookup data from backend
  Future<void> refreshLookupData() async {
    await loadLookupData(forceRefresh: true);
  }

  /// Clear cache and reload
  Future<void> clearCacheAndReload() async {
    _lookupService.clearCache();
    _lookupData = null;
    await loadLookupData(forceRefresh: true);
  }

  // Convenience methods for UI components
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

  /// Get cache information for debugging
  Map<String, dynamic> getCacheInfo() {
    return _lookupService.getCacheInfo();
  }
}

// Helper class for dropdown items
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
