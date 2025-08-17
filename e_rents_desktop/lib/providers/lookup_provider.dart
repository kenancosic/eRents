import 'package:e_rents_desktop/models/lookup_item.dart';
import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/base/api_service_extensions.dart';
import 'package:e_rents_desktop/models/enums.dart';
import 'package:e_rents_desktop/utils/name_normalizer.dart';
import 'package:e_rents_desktop/core/lookups/lookup_key.dart';
import 'package:e_rents_desktop/core/lookups/lookup_registry.dart';

/// Refactored LookupProvider using the new base provider architecture
/// 
/// This demonstrates how to use:
/// - BaseProvider for common functionality
/// - Automatic state management (loading, error)
/// - API service extensions for cleaner code
class LookupProvider extends BaseProvider {
  // Central registry for lookups (single source of truth)
  final LookupRegistry registry;

  LookupProvider(super.api, {LookupRegistry? registry})
      : registry = registry ?? LookupRegistry();

  // ─── Public API ─────────────────────────────────────────────────────────

  // ─── Generic Enum Lookup (Phase 1) ─────────────────────────────────────
  static const Map<EnumGroup, String> _endpoints = {
    EnumGroup.propertyType: 'api/lookup/property-types',
    EnumGroup.rentingType: 'api/lookup/rental-types',
    EnumGroup.propertyStatus: 'api/lookup/property-statuses',
    EnumGroup.userType: 'api/lookup/user-types',
    EnumGroup.bookingStatus: 'api/lookup/booking-statuses',
    EnumGroup.amenity: 'api/lookup/amenities',
  };

  // Bridge EnumGroup (legacy) to LookupKey (new unified key)
  static const Map<EnumGroup, LookupKey> _groupToKey = {
    EnumGroup.propertyType: LookupKey.propertyType,
    EnumGroup.rentingType: LookupKey.rentingType,
    EnumGroup.propertyStatus: LookupKey.propertyStatus,
    EnumGroup.userType: LookupKey.userType,
    EnumGroup.bookingStatus: LookupKey.bookingStatus,
    EnumGroup.amenity: LookupKey.amenity,
  };

  Future<List<LookupItem>> getEnumItems(EnumGroup group) async {
    final path = _endpoints[group];
    if (path == null) {
      throw ArgumentError('No endpoint configured for group: $group');
    }
    final result = await executeWithState(() async {
      return await api.getListAndDecode(path, LookupItem.fromJson, authenticated: true);
    });
    final items = result ?? [];
    final key = _groupToKey[group];
    if (key != null) {
      registry.setItems(key, items);
    }
    return items;
  }

  Future<String?> getName(EnumGroup group, int id) async {
    // Prefer registry if already populated, otherwise fetch and populate
    final key = _groupToKey[group];
    if (key != null) {
      final label = registry.label(key, id: id);
      if (label != null) return label;
    }
    final items = await getEnumItems(group);
    final match = items.firstWhere(
      (x) => x.value == id,
      orElse: () => const LookupItem(value: -1, text: '', description: null),
    );
    return match.value == -1 ? null : match.text;
  }

  Future<int?> getId(EnumGroup group, String name) async {
    final key = _groupToKey[group];
    if (key != null) {
      final item = registry.findByName(key, name);
      if (item != null) return item.value;
    }
    final items = await getEnumItems(group);
    final target = NameNormalizer.normalize(name);
    final found = items.firstWhere(
      (x) => NameNormalizer.normalize(x.text) == target,
      orElse: () => const LookupItem(value: -1, text: '', description: null),
    );
    return found.value == -1 ? null : found.value;
  }

  /// Get property types from backend
  Future<List<LookupItem>> getPropertyTypes() async {
    return getEnumItems(EnumGroup.propertyType);
  }

  /// Get property statuses from backend
  Future<List<LookupItem>> getPropertyStatuses() async {
    return getEnumItems(EnumGroup.propertyStatus);
  }

  /// Get renting types from backend
  Future<List<LookupItem>> getRentingTypes() async {
    return getEnumItems(EnumGroup.rentingType);
  }

  /// Get user types from backend
  Future<List<LookupItem>> getUserTypes() async {
    return getEnumItems(EnumGroup.userType);
  }

  /// Get booking statuses from backend
  Future<List<LookupItem>> getBookingStatuses() async {
    return getEnumItems(EnumGroup.bookingStatus);
  }

  /// Get maintenance issue priorities from backend
  Future<List<LookupItem>> getMaintenanceIssuePriorities() async {
    // Not part of EnumGroup; keep direct call
    final result = await executeWithState(() async {
      return await api.getListAndDecode('api/lookup/maintenance-issue-priorities', LookupItem.fromJson, authenticated: true);
    });
    return result ?? [];
  }

  /// Get maintenance issue statuses from backend
  Future<List<LookupItem>> getMaintenanceIssueStatuses() async {
    // Not part of EnumGroup; keep direct call
    final result = await executeWithState(() async {
      return await api.getListAndDecode('api/lookup/maintenance-issue-statuses', LookupItem.fromJson, authenticated: true);
    });
    return result ?? [];
  }

  /// Get amenities from backend
  Future<List<LookupItem>> getAmenities() async {
    return getEnumItems(EnumGroup.amenity);
  }

  // ─── Convenience Methods ───────────────────────────────────────────────

  /// Get property type name by ID - makes API call each time
  Future<String> getPropertyTypeName(int id) async {
    final items = await getPropertyTypes();
    final item = items.where((item) => item.value == id).firstOrNull;
    return item?.text ?? 'Unknown';
  }

  /// Get renting type name by ID - makes API call each time
  Future<String> getRentingTypeName(int id) async {
    final items = await getRentingTypes();
    final item = items.where((item) => item.value == id).firstOrNull;
    return item?.text ?? 'Unknown';
  }

  /// Get property status name by ID - makes API call each time
  Future<String> getPropertyStatusName(int id) async {
    final items = await getPropertyStatuses();
    final item = items.where((item) => item.value == id).firstOrNull;
    return item?.text ?? 'Unknown';
  }

  /// Get booking status name by ID - makes API call each time
  Future<String> getBookingStatusName(int id) async {
    final items = await getBookingStatuses();
    final item = items.where((item) => item.value == id).firstOrNull;
    return item?.text ?? 'Unknown';
  }

  /// Get issue priority name by ID - makes API call each time
  Future<String> getIssuePriorityName(int id) async {
    final items = await getMaintenanceIssuePriorities();
    final item = items.where((item) => item.value == id).firstOrNull;
    return item?.text ?? 'Unknown';
  }

  /// Get issue status name by ID - makes API call each time
  Future<String> getIssueStatusName(int id) async {
    final items = await getMaintenanceIssueStatuses();
    final item = items.where((item) => item.value == id).firstOrNull;
    return item?.text ?? 'Unknown';
  }

  /// Get user type name by ID - makes API call each time
  Future<String> getUserTypeName(int id) async {
    final items = await getUserTypes();
    final item = items.where((item) => item.value == id).firstOrNull;
    return item?.text ?? 'Unknown';
  }

  /// Get amenity name by ID - makes API call each time
  Future<String> getAmenityName(int id) async {
    final items = await getAmenities();
    final item = items.where((item) => item.value == id).firstOrNull;
    return item?.text ?? 'Unknown';
  }

  /// Get amenity names by IDs - makes API call each time
  Future<List<String>> getAmenityNames(List<int> ids) async {
    // Prefer registry for quick mapping
    final labels = <String>[];
    for (final id in ids) {
      final label = registry.label(LookupKey.amenity, id: id);
      if (label != null) {
        labels.add(label);
      } else {
        // fallback to fetch-once
        final items = await getAmenities();
        final item = items.where((item) => item.value == id).firstOrNull;
        labels.add(item?.text ?? 'Unknown');
      }
    }
    return labels;
  }

  // ─── Individual Enum Methods ───────────────────────────────────────────────

  /// Fetch property types from the new enum endpoint
  Future<List<LookupItem>> getPropertyTypesEnum() async {
    return getEnumItems(EnumGroup.propertyType);
  }

  /// Fetch renting types from the new enum endpoint
  Future<List<LookupItem>> getRentingTypesEnum() async {
    return getEnumItems(EnumGroup.rentingType);
  }

  /// Fetch property statuses from the new enum endpoint
  Future<List<LookupItem>> getPropertyStatusesEnum() async {
    return getEnumItems(EnumGroup.propertyStatus);
  }

  /// Fetch user types from the new enum endpoint
  Future<List<LookupItem>> getUserTypesEnum() async {
    return getEnumItems(EnumGroup.userType);
  }

  /// Fetch booking statuses from the new enum endpoint
  Future<List<LookupItem>> getBookingStatusesEnum() async {
    return getEnumItems(EnumGroup.bookingStatus);
  }

  /// Fetch all available enum types
  Future<List<String>> getAvailableEnumTypes() async {
    // Phase 1: return known groups locally
    return _endpoints.keys.map((e) => e.name).toList();
  }

  /// Get lookup data status information
  Map<String, dynamic> getLookupDataStatus() {
    return {
      'providerActive': true,
      'isLoading': isLoading,
      'hasError': hasError,
    };
  }

  // ─── New: Registry-first convenience API for widgets ─────────────────────

  /// Get dropdown items via registry for a given key (no network call)
  List<DropdownItem> dropdownItems(LookupKey key) => registry.dropdownItems(key);

  /// Get items for a given key (no network call)
  List<LookupItem> items(LookupKey key) => registry.getItems(key);

  /// Resolve label by id or name via registry (no network call)
  String? label(LookupKey key, {int? id, String? name}) => registry.label(key, id: id, name: name);
}
