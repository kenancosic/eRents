import 'dart:convert';
import 'package:e_rents_desktop/models/lookup_data.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/renting_type.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/utils/logger.dart';

class LookupService extends ApiService {
  LookupService(super.baseUrl, super.storageService);

  // In-memory cache for lookup data
  LookupData? _cachedLookupData;
  DateTime? _cacheTimestamp;

  // Cache duration (1 hour - lookup data doesn't change frequently)
  static const Duration _cacheDuration = Duration(hours: 1);

  /// Fetch all lookup data from backend with caching
  Future<LookupData> getAllLookupData({bool forceRefresh = false}) async {
    // Return cached data if available and not expired
    if (!forceRefresh && _cachedLookupData != null && _isCacheValid()) {
      log.info('LookupService: Returning cached lookup data');
      return _cachedLookupData!;
    }

    log.info('LookupService: Fetching fresh lookup data from backend');

    try {
      final response = await get('/Lookup/all', authenticated: true);
      final Map<String, dynamic> jsonResponse = json.decode(response.body);

      _cachedLookupData = LookupData.fromJson(jsonResponse);
      _cacheTimestamp = DateTime.now();

      log.info('LookupService: Successfully cached lookup data');
      return _cachedLookupData!;
    } catch (e, stackTrace) {
      log.severe('LookupService: Error fetching lookup data', e, stackTrace);
      // If we have cached data, return it even if expired
      if (_cachedLookupData != null) {
        log.warning('LookupService: Returning expired cached data due to error');
        return _cachedLookupData!;
      }
      rethrow;
    }
  }

  /// Fetch property types only
  Future<List<LookupItem>> getPropertyTypes({bool forceRefresh = false}) async {
    final lookupData = await getAllLookupData(forceRefresh: forceRefresh);
    return lookupData.propertyTypes;
  }

  /// Fetch renting types only
  Future<List<LookupItem>> getRentingTypes({bool forceRefresh = false}) async {
    final lookupData = await getAllLookupData(forceRefresh: forceRefresh);
    return lookupData.rentingTypes;
  }

  /// Fetch property statuses only
  Future<List<LookupItem>> getPropertyStatuses({
    bool forceRefresh = false,
  }) async {
    final lookupData = await getAllLookupData(forceRefresh: forceRefresh);
    return lookupData.propertyStatuses;
  }

  /// Fetch user types only
  Future<List<LookupItem>> getUserTypes({bool forceRefresh = false}) async {
    final lookupData = await getAllLookupData(forceRefresh: forceRefresh);
    return lookupData.userTypes;
  }

  /// Fetch booking statuses only
  Future<List<LookupItem>> getBookingStatuses({
    bool forceRefresh = false,
  }) async {
    final lookupData = await getAllLookupData(forceRefresh: forceRefresh);
    return lookupData.bookingStatuses;
  }

  /// Fetch amenities only
  Future<List<LookupItem>> getAmenities({bool forceRefresh = false}) async {
    final lookupData = await getAllLookupData(forceRefresh: forceRefresh);
    return lookupData.amenities;
  }

  // Convenience methods for converting enum values to IDs
  /// Convert PropertyType enum to backend ID
  Future<int> getPropertyTypeId(PropertyType propertyType) async {
    final lookupData = await getAllLookupData();

    // Map enum to expected name
    String typeName = switch (propertyType) {
      PropertyType.apartment => 'Apartment',
      PropertyType.house => 'House',
      PropertyType.condo => 'Condo',
      PropertyType.townhouse => 'Townhouse',
      PropertyType.studio => 'Studio',
    };

    final id = lookupData.getPropertyTypeIdByName(typeName);
    if (id == null) {
      log.warning(
        'LookupService: PropertyType $typeName not found, defaulting to Apartment',
      );
      return lookupData.getPropertyTypeIdByName('Apartment') ?? 1;
    }
    return id;
  }

  /// Convert RentingType enum to backend ID
  Future<int> getRentingTypeId(RentingType rentingType) async {
    final lookupData = await getAllLookupData();

    // Map enum to expected name
    String typeName = switch (rentingType) {
      RentingType.monthly => 'Monthly',
      RentingType.daily => 'Daily',
    };

    final id = lookupData.getRentingTypeIdByName(typeName);
    if (id == null) {
      log.warning(
        'LookupService: RentingType $typeName not found, defaulting to Monthly',
      );
      return lookupData.getRentingTypeIdByName('Monthly') ?? 1;
    }
    return id;
  }

  /// Convert PropertyStatus enum to backend ID
  Future<int> getPropertyStatusId(PropertyStatus propertyStatus) async {
    final lookupData = await getAllLookupData();

    // Map enum to expected name
    String statusName = switch (propertyStatus) {
      PropertyStatus.available => 'Available',
      PropertyStatus.rented => 'Rented',
      PropertyStatus.maintenance => 'Maintenance',
      PropertyStatus.unavailable => 'Unavailable',
    };

    final id = lookupData.getPropertyStatusIdByName(statusName);
    if (id == null) {
      log.warning(
        'LookupService: PropertyStatus $statusName not found, defaulting to Available',
      );
      return lookupData.getPropertyStatusIdByName('Available') ?? 1;
    }
    return id;
  }

  // Reverse lookup methods for converting IDs back to enums
  /// Convert backend ID to PropertyType enum
  Future<PropertyType> getPropertyTypeEnum(int id) async {
    final lookupData = await getAllLookupData();
    final item = lookupData.getPropertyTypeById(id);

    if (item == null) {
      log.warning(
        'LookupService: PropertyType ID $id not found, defaulting to apartment',
      );
      return PropertyType.apartment;
    }

    return switch (item.name.toLowerCase()) {
      'apartment' => PropertyType.apartment,
      'house' => PropertyType.house,
      'condo' => PropertyType.condo,
      'townhouse' => PropertyType.townhouse,
      'studio' => PropertyType.studio,
      _ => PropertyType.apartment,
    };
  }

  /// Convert backend ID to RentingType enum
  Future<RentingType> getRentingTypeEnum(int id) async {
    final lookupData = await getAllLookupData();
    final item = lookupData.getRentingTypeById(id);

    if (item == null) {
      log.warning(
        'LookupService: RentingType ID $id not found, defaulting to monthly',
      );
      return RentingType.monthly;
    }

    return switch (item.name.toLowerCase()) {
      'daily' => RentingType.daily,
      'monthly' => RentingType.monthly,
      _ => RentingType.monthly,
    };
  }

  /// Convert backend ID to PropertyStatus enum
  Future<PropertyStatus> getPropertyStatusEnum(int id) async {
    final lookupData = await getAllLookupData();
    final item = lookupData.getPropertyStatusById(id);

    if (item == null) {
      log.warning(
        'LookupService: PropertyStatus ID $id not found, defaulting to available',
      );
      return PropertyStatus.available;
    }

    return switch (item.name.toLowerCase()) {
      'available' => PropertyStatus.available,
      'rented' => PropertyStatus.rented,
      'maintenance' => PropertyStatus.maintenance,
      'unavailable' => PropertyStatus.unavailable,
      _ => PropertyStatus.available,
    };
  }

  /// Get cache status information
  Map<String, dynamic> getCacheInfo() {
    return {
      'hasCache': _cachedLookupData != null,
      'cacheTimestamp': _cacheTimestamp?.toIso8601String(),
      'isValid': _isCacheValid(),
      'expiresAt': _cacheTimestamp?.add(_cacheDuration).toIso8601String(),
    };
  }

  /// Check if cached data is still valid
  bool _isCacheValid() {
    if (_cacheTimestamp == null) return false;
    return DateTime.now().difference(_cacheTimestamp!) < _cacheDuration;
  }

  /// Clear the cache (useful for testing or forced refresh)
  void clearCache() {
    _cachedLookupData = null;
    _cacheTimestamp = null;
    log.info('LookupService: Cache cleared');
  }
}
