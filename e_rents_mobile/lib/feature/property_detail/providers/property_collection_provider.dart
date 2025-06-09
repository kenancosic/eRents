import 'package:flutter/foundation.dart';
import 'package:e_rents_mobile/core/base/collection_provider.dart';
import 'package:e_rents_mobile/core/repositories/property_repository.dart';
import 'package:e_rents_mobile/core/models/property.dart';

/// Concrete collection provider for Property entities
/// Demonstrates the new architecture pattern with automatic caching, loading states, and search
class PropertyCollectionProvider extends CollectionProvider<Property> {
  PropertyCollectionProvider(PropertyRepository super.repository);

  // Get the property repository with proper typing
  PropertyRepository get propertyRepository => repository as PropertyRepository;

  @override
  bool matchesSearch(Property item, String query) {
    final lowerQuery = query.toLowerCase();
    return item.name.toLowerCase().contains(lowerQuery) ||
        (item.description?.toLowerCase().contains(lowerQuery) ?? false) ||
        (item.address?.city?.toLowerCase().contains(lowerQuery) ?? false) ||
        (item.facilities?.toLowerCase().contains(lowerQuery) ?? false);
  }

  @override
  bool matchesFilters(Property item, Map<String, dynamic> filters) {
    // Property status filter
    if (filters.containsKey('status')) {
      final statusFilter = filters['status'] as String?;
      if (statusFilter != null &&
          item.status.toString().split('.').last != statusFilter) {
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

    // Bedrooms filter
    if (filters.containsKey('bedrooms')) {
      final bedrooms = filters['bedrooms'] as int?;
      if (bedrooms != null &&
          (item.bedrooms == null || item.bedrooms! < bedrooms)) {
        return false;
      }
    }

    // Bathrooms filter
    if (filters.containsKey('bathrooms')) {
      final bathrooms = filters['bathrooms'] as int?;
      if (bathrooms != null &&
          (item.bathrooms == null || item.bathrooms! < bathrooms)) {
        return false;
      }
    }

    // Property type filter
    if (filters.containsKey('propertyType')) {
      final propertyType = filters['propertyType'] as PropertyType?;
      if (propertyType != null && item.propertyType != propertyType) {
        return false;
      }
    }

    // Rental type filter
    if (filters.containsKey('rentalType')) {
      final rentalType = filters['rentalType'] as PropertyRentalType?;
      if (rentalType != null && item.rentalType != rentalType) {
        return false;
      }
    }

    // Owner filter
    if (filters.containsKey('ownerId')) {
      final ownerId = filters['ownerId'] as int?;
      if (ownerId != null && item.ownerId != ownerId) {
        return false;
      }
    }

    return true;
  }

  // Property-specific convenience methods

  /// Filter available properties only
  Future<void> loadAvailableProperties() async {
    await loadItems();
    applyFilters({'status': 'available'});
  }

  /// Filter properties by owner
  Future<void> loadPropertiesByOwner(int ownerId) async {
    await loadItems();
    applyFilters({'ownerId': ownerId});
  }

  /// Filter properties by price range
  void filterByPriceRange(double? minPrice, double? maxPrice) {
    final filters = Map<String, dynamic>.from(currentFilters);
    if (minPrice != null) filters['minPrice'] = minPrice;
    if (maxPrice != null) filters['maxPrice'] = maxPrice;
    applyFilters(filters);
  }

  /// Filter properties by bedrooms/bathrooms
  void filterByRooms({int? bedrooms, int? bathrooms}) {
    final filters = Map<String, dynamic>.from(currentFilters);
    if (bedrooms != null) filters['bedrooms'] = bedrooms;
    if (bathrooms != null) filters['bathrooms'] = bathrooms;
    applyFilters(filters);
  }

  /// Filter properties by rental type
  void filterByRentalType(PropertyRentalType rentalType) {
    final filters = Map<String, dynamic>.from(currentFilters);
    filters['rentalType'] = rentalType;
    applyFilters(filters);
  }

  /// Sort properties by price (ascending)
  void sortByPriceAsc() {
    sortItems((a, b) => a.price.compareTo(b.price));
  }

  /// Sort properties by price (descending)
  void sortByPriceDesc() {
    sortItems((a, b) => b.price.compareTo(a.price));
  }

  /// Sort properties by rating (highest first)
  void sortByRating() {
    sortItems((a, b) {
      final ratingA = a.averageRating ?? 0.0;
      final ratingB = b.averageRating ?? 0.0;
      return ratingB.compareTo(ratingA);
    });
  }

  /// Sort properties by date added (newest first)
  void sortByNewest() {
    sortItems((a, b) {
      final dateA = a.dateAdded ?? DateTime(1970);
      final dateB = b.dateAdded ?? DateTime(1970);
      return dateB.compareTo(dateA);
    });
  }

  @override
  void onItemsLoaded(List<Property> items) {
    // Custom post-processing after items are loaded
    // e.g., cache property images, validate data, etc.
    debugPrint('PropertyCollectionProvider: Loaded ${items.length} properties');
  }
}
