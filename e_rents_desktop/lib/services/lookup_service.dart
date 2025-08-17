import 'dart:convert';
import 'package:e_rents_desktop/models/enums/property_status.dart';
import 'package:e_rents_desktop/models/enums/property_type.dart';
import 'package:e_rents_desktop/models/enums/renting_type.dart';
import 'package:e_rents_desktop/models/lookup_item.dart';
import 'package:e_rents_desktop/models/enums.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/utils/logger.dart';
import 'package:e_rents_desktop/utils/name_normalizer.dart';

class LookupService extends ApiService {
  LookupService(super.baseUrl, super.storageService);

  // ─── Generic Enum Lookup (Single Source Of Truth) ──────────────────────

  static const Map<EnumGroup, String> _endpoints = {
    EnumGroup.propertyType: '/api/lookup/property-types',
    EnumGroup.rentingType: '/api/lookup/rental-types',
    EnumGroup.propertyStatus: '/api/lookup/property-statuses',
    EnumGroup.userType: '/api/lookup/user-types',
    EnumGroup.bookingStatus: '/api/lookup/booking-statuses',
    EnumGroup.amenity: '/api/lookup/amenities',
  };

  Future<List<LookupItem>> getEnumItems(EnumGroup group) async {
    final path = _endpoints[group];
    if (path == null) {
      throw ArgumentError('No endpoint configured for group: $group');
    }
    try {
      final response = await get(path, authenticated: true);
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList
          .map((item) => LookupItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      log.severe('LookupService: Error fetching items for $group', e, stackTrace);
      rethrow;
    }
  }

  Future<String?> getName(EnumGroup group, int id) async {
    final items = await getEnumItems(group);
    return items.firstWhere(
      (x) => x.value == id,
      orElse: () => const LookupItem(value: -1, text: '', description: null),
    ).text.isEmpty
        ? null
        : items.firstWhere((x) => x.value == id).text;
  }

  Future<int?> getId(EnumGroup group, String name) async {
    final items = await getEnumItems(group);
    final target = NameNormalizer.normalize(name);
    final found = items.firstWhere(
      (x) => NameNormalizer.normalize(x.text) == target,
      orElse: () => const LookupItem(value: -1, text: '', description: null),
    );
    return found.value == -1 ? null : found.value;
  }

  /// Fetch property types only
  @Deprecated('Use getEnumItems(EnumGroup.propertyType) instead')
  Future<List<LookupItem>> getPropertyTypes({bool forceRefresh = false}) async {
    return getEnumItems(EnumGroup.propertyType);
  }

  /// Fetch property types from the new enum endpoint
  @Deprecated('Use getEnumItems(EnumGroup.propertyType) instead')
  Future<List<LookupItem>> getPropertyTypesEnum() async {
    return getEnumItems(EnumGroup.propertyType);
  }

  /// Fetch renting types only
  @Deprecated('Use getEnumItems(EnumGroup.rentingType) instead')
  Future<List<LookupItem>> getRentingTypes({bool forceRefresh = false}) async {
    return getEnumItems(EnumGroup.rentingType);
  }

  /// Fetch renting types from the new enum endpoint
  @Deprecated('Use getEnumItems(EnumGroup.rentingType) instead')
  Future<List<LookupItem>> getRentingTypesEnum() async {
    return getEnumItems(EnumGroup.rentingType);
  }

  /// Fetch property statuses only
  @Deprecated('Use getEnumItems(EnumGroup.propertyStatus) instead')
  Future<List<LookupItem>> getPropertyStatuses({
    bool forceRefresh = false,
  }) async {
    return getEnumItems(EnumGroup.propertyStatus);
  }

  /// Fetch property statuses from the new enum endpoint
  @Deprecated('Use getEnumItems(EnumGroup.propertyStatus) instead')
  Future<List<LookupItem>> getPropertyStatusesEnum() async {
    return getEnumItems(EnumGroup.propertyStatus);
  }

  /// Fetch user types only
  @Deprecated('Use getEnumItems(EnumGroup.userType) instead')
  Future<List<LookupItem>> getUserTypes({bool forceRefresh = false}) async {
    return getEnumItems(EnumGroup.userType);
  }

  /// Fetch user types from the new enum endpoint
  @Deprecated('Use getEnumItems(EnumGroup.userType) instead')
  Future<List<LookupItem>> getUserTypesEnum() async {
    return getEnumItems(EnumGroup.userType);
  }

  /// Fetch booking statuses only
  @Deprecated('Use getEnumItems(EnumGroup.bookingStatus) instead')
  Future<List<LookupItem>> getBookingStatuses({
    bool forceRefresh = false,
  }) async {
    return getEnumItems(EnumGroup.bookingStatus);
  }

  /// Fetch booking statuses from the new enum endpoint
  @Deprecated('Use getEnumItems(EnumGroup.bookingStatus) instead')
  Future<List<LookupItem>> getBookingStatusesEnum() async {
    return getEnumItems(EnumGroup.bookingStatus);
  }

  /// Fetch amenities only
  @Deprecated('Use getEnumItems(EnumGroup.amenity) instead')
  Future<List<LookupItem>> getAmenities({bool forceRefresh = false}) async {
    return getEnumItems(EnumGroup.amenity);
  }

  /// Fetch all available enum types
  @Deprecated('Use EnumGroup.values.map((e) => e.name) on client')
  Future<List<String>> getAvailableEnumTypes() async {
    // Phase 1: return known groups locally
    return _endpoints.keys.map((e) => e.name).toList();
  }

  // Convenience methods for converting enum values to IDs
  /// Convert PropertyType enum to backend ID
  Future<int> getPropertyTypeId(PropertyType propertyType) async {
    final typeName = propertyType.displayName;
    final id = await getId(EnumGroup.propertyType, typeName);
    if (id == null) {
      log.warning(
        'LookupService: PropertyType $typeName not found, defaulting to Apartment',
      );
      return (await getId(EnumGroup.propertyType, 'Apartment')) ?? 1;
    }
    return id;
  }

  /// Convert RentingType enum to backend ID
  Future<int> getRentingTypeId(RentingType rentingType) async {
    final typeName = rentingType.displayName;
    final id = await getId(EnumGroup.rentingType, typeName);
    if (id == null) {
      log.warning(
        'LookupService: RentingType $typeName not found, defaulting to Monthly',
      );
      return (await getId(EnumGroup.rentingType, 'Monthly')) ?? 1;
    }
    return id;
  }

  /// Convert PropertyStatus enum to backend ID
  Future<int> getPropertyStatusId(PropertyStatus propertyStatus) async {
    final statusName = propertyStatus.displayName;
    final id = await getId(EnumGroup.propertyStatus, statusName);
    if (id == null) {
      log.warning(
        'LookupService: PropertyStatus $statusName not found, defaulting to Available',
      );
      return (await getId(EnumGroup.propertyStatus, 'Available')) ?? 1;
    }
    return id;
  }

  // Reverse lookup methods for converting IDs back to enums
  /// Convert backend ID to PropertyType enum
  Future<PropertyType> getPropertyTypeEnum(int id) async {
    final name = await getName(EnumGroup.propertyType, id);
    if (name == null) {
      log.warning(
        'LookupService: PropertyType ID $id not found, defaulting to apartment',
      );
      return PropertyType.apartment;
    }
    try {
      return PropertyType.fromString(name);
    } catch (_) {
      // Fallback by normalized name
      final n = NameNormalizer.normalize(name);
      if (n == 'apartment') return PropertyType.apartment;
      if (n == 'house') return PropertyType.house;
      if (n == 'studio') return PropertyType.studio;
      if (n == 'villa') return PropertyType.villa;
      if (n == 'room') return PropertyType.room;
      return PropertyType.apartment;
    }
  }

  /// Convert backend ID to RentingType enum
  Future<RentingType> getRentingTypeEnum(int id) async {
    final name = await getName(EnumGroup.rentingType, id);
    if (name == null) {
      log.warning(
        'LookupService: RentingType ID $id not found, defaulting to monthly',
      );
      return RentingType.monthly;
    }
    try {
      return RentingType.fromString(name);
    } catch (_) {
      final n = NameNormalizer.normalize(name);
      if (n == 'daily') return RentingType.daily;
      if (n == 'monthly') return RentingType.monthly;
      return RentingType.monthly;
    }
  }

  /// Convert backend ID to PropertyStatus enum
  Future<PropertyStatus> getPropertyStatusEnum(int id) async {
    final name = await getName(EnumGroup.propertyStatus, id);
    if (name == null) {
      log.warning(
        'LookupService: PropertyStatus ID $id not found, defaulting to available',
      );
      return PropertyStatus.available;
    }
    try {
      return PropertyStatus.fromString(name);
    } catch (_) {
      final n = NameNormalizer.normalize(name);
      switch (n) {
        case 'available':
          return PropertyStatus.available;
        case 'occupied':
          return PropertyStatus.occupied;
        case 'under maintenance':
        case 'maintenance':
        case 'undermaintenance':
          return PropertyStatus.underMaintenance;
        case 'unavailable':
          return PropertyStatus.unavailable;
        default:
          return PropertyStatus.available;
      }
    }
  }

  /// Get cache status information
  Map<String, dynamic> getCacheInfo() {
    // Caching disabled
    return {
      'hasCache': false,
      'cacheTimestamp': null,
      'isValid': false,
      'expiresAt': null,
    };
  }

}
