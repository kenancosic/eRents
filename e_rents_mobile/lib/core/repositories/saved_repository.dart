import 'package:e_rents_mobile/core/base/base_repository.dart';
import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/feature/saved/saved_service.dart';
import 'package:e_rents_mobile/core/services/cache_manager.dart';

/// Concrete repository for Saved/Favorite properties
/// Implements BaseRepository pattern with Property entities for saved properties functionality
class SavedRepository extends BaseRepository<Property, SavedService> {
  SavedRepository({
    required SavedService service,
    required CacheManager cacheManager,
  }) : super(service: service, cacheManager: cacheManager);

  @override
  String get resourceName => 'saved_properties';

  @override
  Duration get cacheTtl =>
      const Duration(hours: 1); // Saved properties don't change frequently

  @override
  Future<Property?> fetchFromService(String id) async {
    final propertyId = int.tryParse(id);
    if (propertyId == null) {
      throw ArgumentError('Invalid property ID: $id');
    }

    // Get saved properties and find the specific one
    final savedProperties = await service.getSavedProperties();
    return savedProperties.firstWhere(
      (property) => property.propertyId == propertyId,
      orElse: () => throw StateError('Property not found in saved list'),
    );
  }

  @override
  Future<List<Property>> fetchAllFromService(
      [Map<String, dynamic>? params]) async {
    return await service.getSavedProperties();
  }

  @override
  Future<Property> createInService(Property item) async {
    await service.saveProperty(item);
    return item; // Return the same item since saved service doesn't modify it
  }

  @override
  Future<Property> updateInService(String id, Property item) async {
    // For saved properties, update would typically be re-saving
    await service.saveProperty(item);
    return item;
  }

  @override
  Future<bool> deleteInService(String id) async {
    final propertyId = int.tryParse(id);
    if (propertyId == null) {
      throw ArgumentError('Invalid property ID: $id');
    }

    return await service.unsaveProperty(propertyId);
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

  // Saved-specific methods

  /// Check if a property is saved
  Future<bool> isPropertySaved(int propertyId) async {
    try {
      await getById(propertyId.toString());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Toggle saved status of a property
  Future<bool> toggleSavedStatus(Property property) async {
    final isSaved = await isPropertySaved(property.propertyId);

    if (isSaved) {
      // Remove from saved
      await delete(property.propertyId.toString());
      return false;
    } else {
      // Add to saved
      await create(property);
      return true;
    }
  }

  /// Save a property
  Future<void> saveProperty(Property property) async {
    await create(property);
  }

  /// Remove a property from saved list
  Future<bool> unsaveProperty(int propertyId) async {
    return await delete(propertyId.toString());
  }

  /// Get all saved properties
  Future<List<Property>> getSavedProperties() async {
    return await getAll();
  }

  /// Clear all saved properties
  Future<void> clearSavedProperties() async {
    final savedProperties = await getSavedProperties();
    for (final property in savedProperties) {
      await delete(property.propertyId.toString());
    }
  }
}
