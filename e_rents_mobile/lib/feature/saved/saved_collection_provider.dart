import 'package:e_rents_mobile/core/base/collection_provider.dart';
import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/core/repositories/saved_repository.dart';

/// Collection provider for managing saved/favorite properties
/// Uses repository pattern for automatic caching, error handling, and state management
class SavedCollectionProvider extends CollectionProvider<Property> {
  SavedCollectionProvider(SavedRepository super.repository);

  /// Get the saved repository with proper typing
  SavedRepository get savedRepository => repository as SavedRepository;

  /// Load all saved properties
  Future<void> loadSavedProperties({bool forceRefresh = false}) async {
    await loadItems(null);
  }

  /// Check if a property is saved
  bool isPropertySaved(int propertyId) {
    return items.any((property) => property.propertyId == propertyId);
  }

  /// Toggle saved status of a property
  Future<bool> toggleSavedStatus(Property property) async {
    bool newStatus = false;

    await execute(() async {
      newStatus = await savedRepository.toggleSavedStatus(property);

      if (newStatus) {
        // Property was saved - reload to get updated list
        await loadItems(null);
      } else {
        // Property was unsaved - reload to get updated list
        await loadItems(null);
      }
    });

    return newStatus;
  }

  /// Save a property
  Future<void> saveProperty(Property property) async {
    if (!isPropertySaved(property.propertyId)) {
      await addItem(property);
    }
  }

  /// Remove a property from saved list
  Future<void> unsaveProperty(Property property) async {
    await removeItem(property.propertyId.toString());
  }

  /// Clear all saved properties
  Future<void> clearSavedProperties() async {
    await execute(() async {
      await savedRepository.clearSavedProperties();
      await loadItems(null); // Reload to refresh the list
    });
  }

  @override
  bool matchesSearch(Property item, String query) {
    return item.name.toLowerCase().contains(query) ||
        (item.description?.toLowerCase().contains(query) ?? false) ||
        (item.address?.city?.toLowerCase().contains(query) ?? false);
  }

  @override
  bool matchesFilters(Property item, Map<String, dynamic> filters) {
    // Property type filter
    if (filters.containsKey('propertyType')) {
      final filterType = filters['propertyType'];
      if (filterType != null && item.propertyType?.name != filterType) {
        return false;
      }
    }

    // Price range filter
    if (filters.containsKey('minPrice')) {
      final minPrice = filters['minPrice'] as double?;
      if (minPrice != null && item.price < minPrice) {
        return false;
      }
    }

    if (filters.containsKey('maxPrice')) {
      final maxPrice = filters['maxPrice'] as double?;
      if (maxPrice != null && item.price > maxPrice) {
        return false;
      }
    }

    // Status filter
    if (filters.containsKey('status')) {
      final filterStatus = filters['status'];
      if (filterStatus != null && item.status.name != filterStatus) {
        return false;
      }
    }

    return true;
  }

  /// Get count of saved properties
  int get savedCount => items.length;

  /// Check if any properties are saved
  bool get hasSavedProperties => items.isNotEmpty;

  /// Get saved properties by type
  List<Property> getPropertiesByType(String typeName) {
    return items
        .where((property) => property.propertyType?.name == typeName)
        .toList();
  }

  /// Get saved properties in price range
  List<Property> getPropertiesInPriceRange(double minPrice, double maxPrice) {
    return items
        .where((property) =>
            property.price >= minPrice && property.price <= maxPrice)
        .toList();
  }
}
