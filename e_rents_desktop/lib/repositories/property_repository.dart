import '../base/base.dart';
import '../services/property_service.dart';
import '../models/property.dart';

/// Concrete repository implementation for Property entities
///
/// Provides caching, error handling, and data access for properties
/// using the repository pattern with PropertyService as the data source.
class PropertyRepository extends BaseRepository<Property, PropertyService> {
  PropertyRepository({required super.service, required super.cacheManager});

  @override
  String get resourceName => 'properties';

  @override
  Duration get defaultCacheTtl => const Duration(minutes: 10);

  @override
  Future<List<Property>> fetchAllFromService([
    Map<String, dynamic>? params,
  ]) async {
    // Convert Map<String, dynamic> to Map<String, String> for PropertyService
    Map<String, String>? queryParams;
    if (params != null) {
      queryParams = params.map((key, value) => MapEntry(key, value.toString()));
    }
    return await service.getProperties(queryParams: queryParams);
  }

  @override
  Future<Property> fetchByIdFromService(String id) async {
    return await service.getPropertyById(int.parse(id));
  }

  @override
  Future<Property> createInService(Property item) async {
    return await service.createProperty(item);
  }

  @override
  Future<Property> updateInService(String id, Property item) async {
    return await service.updateProperty(int.parse(id), item);
  }

  @override
  Future<void> deleteInService(String id) async {
    await service.deleteProperty(int.parse(id));
  }

  @override
  Future<bool> existsInService(String id) async {
    try {
      await service.getPropertyById(int.parse(id));
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<int> countInService([Map<String, dynamic>? params]) async {
    final items = await fetchAllFromService(params);
    return items.length;
  }

  @override
  String? extractIdFromItem(Property item) => item.id.toString();

  // Property-specific methods

  /// Get available properties (status = available)
  Future<List<Property>> getAvailableProperties() async {
    final allProperties = await getAll();
    return allProperties
        .where((p) => p.status == PropertyStatus.available)
        .toList();
  }

  /// Get properties by type
  Future<List<Property>> getPropertiesByType(PropertyType type) async {
    final allProperties = await getAll();
    return allProperties.where((p) => p.type == type).toList();
  }

  /// Get properties by owner
  Future<List<Property>> getPropertiesByOwner(int ownerId) async {
    return await getAll({'ownerId': ownerId});
  }

  /// Calculate occupancy rate from cached data
  Future<double> getOccupancyRate() async {
    final properties = await getAll();
    if (properties.isEmpty) return 0.0;

    final occupiedCount =
        properties.where((p) => p.status == PropertyStatus.rented).length;
    return occupiedCount / properties.length;
  }
}
