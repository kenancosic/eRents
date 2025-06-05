import '../base/base.dart';
import '../services/amenity_service.dart';

/// Concrete repository implementation for AmenityItem entities
///
/// Provides caching and data access for amenities using the repository pattern.
/// Amenities are typically read-only reference data with longer cache times.
class AmenityRepository
    extends ReadOnlyRepository<AmenityItem, AmenityService> {
  AmenityRepository({required super.service, required super.cacheManager});

  @override
  String get resourceName => 'amenities';

  @override
  Duration get defaultCacheTtl => const Duration(hours: 1); // Longer cache for reference data

  @override
  Future<List<AmenityItem>> fetchAllFromService([
    Map<String, dynamic>? params,
  ]) async {
    return await service.getAmenities();
  }

  @override
  Future<AmenityItem> fetchByIdFromService(String id) async {
    final amenities = await service.getAmenities();
    try {
      return amenities.firstWhere((amenity) => amenity.id.toString() == id);
    } catch (e) {
      throw AppError(
        type: ErrorType.notFound,
        message: 'Amenity with ID $id not found',
        details: 'Amenity may have been removed or ID is invalid',
      );
    }
  }

  /// Get amenities by name pattern
  Future<List<AmenityItem>> getAmenitiesByName(String namePattern) async {
    final amenities = await getAll();
    return amenities
        .where((a) => a.name.toLowerCase().contains(namePattern.toLowerCase()))
        .toList();
  }

  /// Get all amenity names
  Future<List<String>> getAmenityNames() async {
    final amenities = await getAll();
    return amenities.map((a) => a.name).toList();
  }

  /// Check if amenity ID exists
  Future<bool> amenityExists(int amenityId) async {
    final amenities = await getAll();
    return amenities.any((a) => a.id == amenityId);
  }

  /// Get amenities by IDs (batch fetch)
  /// Uses the backend's specific endpoint for better performance
  Future<List<AmenityItem>> getAmenitiesByIds(List<int> ids) async {
    if (ids.isEmpty) return [];

    try {
      // Try to fetch specific amenities from backend
      return await service.getAmenitiesByIds(ids);
    } catch (e) {
      // Fallback to fetching all and filtering if specific endpoint fails
      print('AmenityRepository: Fallback to local filtering for IDs: $ids');
      final amenities = await getAll();
      return amenities.where((a) => ids.contains(a.id)).toList();
    }
  }
}
