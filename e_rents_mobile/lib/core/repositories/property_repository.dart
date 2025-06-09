import 'package:e_rents_mobile/core/base/base_repository.dart';
import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/core/services/property_service.dart';
import 'package:e_rents_mobile/core/services/cache_manager.dart';

/// Concrete repository for Property entities
/// Implements BaseRepository pattern with Property-specific logic
class PropertyRepository extends BaseRepository<Property, PropertyService> {
  PropertyRepository({
    required PropertyService service,
    required CacheManager cacheManager,
  }) : super(service: service, cacheManager: cacheManager);

  @override
  String get resourceName => 'properties';

  @override
  Duration get cacheTtl =>
      const Duration(minutes: 30); // Properties cache longer

  @override
  Future<Property?> fetchFromService(String id) async {
    final propertyId = int.tryParse(id);
    if (propertyId == null) {
      throw ArgumentError('Invalid property ID: $id');
    }

    return await service.getPropertyById(propertyId);
  }

  @override
  Future<List<Property>> fetchAllFromService(
      [Map<String, dynamic>? params]) async {
    // PropertyService.getProperties() doesn't support params yet,
    // but we'll use it for now and add param support later
    return await service.getProperties();
  }

  @override
  Future<Property> createInService(Property item) async {
    return await service.createProperty(item);
  }

  @override
  Future<Property> updateInService(String id, Property item) async {
    final propertyId = int.tryParse(id);
    if (propertyId == null) {
      throw ArgumentError('Invalid property ID: $id');
    }
    return await service.updateProperty(propertyId, item);
  }

  @override
  Future<bool> deleteInService(String id) async {
    final propertyId = int.tryParse(id);
    if (propertyId == null) {
      throw ArgumentError('Invalid property ID: $id');
    }
    return await service.deleteProperty(propertyId);
  }

  @override
  Map<String, dynamic> toJson(Property item) {
    return item.toJson();
  }

  @override
  Property fromJson(Map<String, dynamic> json) {
    return Property.fromJson(json);
  }

  @override
  String getItemId(Property item) {
    return item.propertyId.toString();
  }

  // Property-specific methods

  /// Search properties with filters compatible with backend universal filtering
  Future<List<Property>> searchProperties({
    String? name,
    int? ownerId,
    String? description,
    String? status,
    String? currency,
    int? propertyTypeId,
    int? rentingTypeId,
    int? bedrooms,
    int? bathrooms,
    int? minimumStayDays,
    double? minPrice,
    double? maxPrice,
    double? minArea,
    double? maxArea,
  }) async {
    final searchParams = <String, dynamic>{};

    // Add non-null parameters for backend universal filtering
    if (name != null) searchParams['name'] = name;
    if (ownerId != null) searchParams['ownerId'] = ownerId;
    if (description != null) searchParams['description'] = description;
    if (status != null) searchParams['status'] = status;
    if (currency != null) searchParams['currency'] = currency;
    if (propertyTypeId != null) searchParams['propertyTypeId'] = propertyTypeId;
    if (rentingTypeId != null) searchParams['rentingTypeId'] = rentingTypeId;
    if (bedrooms != null) searchParams['bedrooms'] = bedrooms;
    if (bathrooms != null) searchParams['bathrooms'] = bathrooms;
    if (minimumStayDays != null)
      searchParams['minimumStayDays'] = minimumStayDays;

    // Range filtering (Min/Max pairs)
    if (minPrice != null) searchParams['minPrice'] = minPrice;
    if (maxPrice != null) searchParams['maxPrice'] = maxPrice;
    if (minArea != null) searchParams['minArea'] = minArea;
    if (maxArea != null) searchParams['maxArea'] = maxArea;

    return await getAll(searchParams);
  }

  /// Get properties by owner
  Future<List<Property>> getPropertiesByOwner(int ownerId) async {
    return await getAll({'ownerId': ownerId});
  }

  /// Get available properties
  Future<List<Property>> getAvailableProperties() async {
    return await getAll({'status': 'available'});
  }
}
