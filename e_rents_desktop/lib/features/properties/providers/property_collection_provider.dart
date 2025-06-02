import '../../../base/base.dart';
import '../../../models/property.dart';
import '../../../models/renting_type.dart';

/// Collection provider for managing property data
///
/// Replaces the old PropertyProvider with a cleaner, more focused implementation
/// that separates concerns and uses the repository pattern for data access.
class PropertyCollectionProvider extends CollectionProvider<Property> {
  PropertyCollectionProvider(PropertyRepository repository) : super(repository);

  /// Get the property repository with proper typing
  PropertyRepository get propertyRepository => repository as PropertyRepository;

  // Implementation required by CollectionProvider
  @override
  String _getItemId(Property item) => item.id.toString();

  // Property-specific convenience getters

  /// Get all properties (alias for items)
  List<Property> get properties => items;

  /// Get available properties
  List<Property> get availableProperties {
    return filterItems(
      (property) => property.status == PropertyStatus.available,
    );
  }

  /// Get occupied/rented properties
  List<Property> get occupiedProperties {
    return filterItems((property) => property.status == PropertyStatus.rented);
  }

  /// Get properties in maintenance
  List<Property> get maintenanceProperties {
    return filterItems(
      (property) => property.status == PropertyStatus.maintenance,
    );
  }

  /// Get properties by type
  List<Property> getPropertiesByType(PropertyType type) {
    return filterItems((property) => property.type == type);
  }

  /// Get properties by status
  List<Property> getPropertiesByStatus(PropertyStatus status) {
    return filterItems((property) => property.status == status);
  }

  // Property-specific business logic

  /// Get total number of properties
  int get totalProperties => length;

  /// Get count of available properties
  int get availablePropertiesCount => availableProperties.length;

  /// Get count of occupied properties
  int get occupiedPropertiesCount => occupiedProperties.length;

  /// Calculate occupancy rate
  double get occupancyRate {
    if (totalProperties == 0) return 0.0;
    return occupiedPropertiesCount / totalProperties;
  }

  /// Get a property by ID (returns null if not found)
  Property? getPropertyById(int id) {
    return getItemById(id.toString());
  }

  /// Check if a property exists in the current list
  bool hasProperty(int id) {
    return containsItem(id.toString());
  }

  // Advanced filtering and search

  /// Filter properties by multiple criteria
  List<Property> filterProperties({
    PropertyStatus? status,
    PropertyType? type,
    String? searchQuery,
    double? minPrice,
    double? maxPrice,
    int? minBedrooms,
    int? maxBedrooms,
    RentingType? rentingType,
  }) {
    return filterItems((property) {
      // Status filter
      if (status != null && property.status != status) return false;

      // Type filter
      if (type != null && property.type != type) return false;

      // Renting type filter
      if (rentingType != null && property.rentingType != rentingType)
        return false;

      // Price range filter
      if (minPrice != null && property.price < minPrice) return false;
      if (maxPrice != null && property.price > maxPrice) return false;

      // Bedrooms filter
      if (minBedrooms != null && property.bedrooms < minBedrooms) return false;
      if (maxBedrooms != null && property.bedrooms > maxBedrooms) return false;

      // Search query filter (title and description)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchesTitle = property.title.toLowerCase().contains(query);
        final matchesDescription = property.description.toLowerCase().contains(
          query,
        );
        if (!matchesTitle && !matchesDescription) return false;
      }

      return true;
    });
  }

  /// Search properties by query string
  List<Property> searchProperties(String query) {
    if (query.isEmpty) return properties;

    return filterProperties(searchQuery: query);
  }

  // Repository-backed methods (use caching and proper error handling)

  /// Fetch available properties with caching
  Future<List<Property>> fetchAvailableProperties() async {
    try {
      final availableProps = await propertyRepository.getAvailableProperties();
      // Update local cache with available properties
      // Note: This doesn't replace all items, just provides filtered data
      return availableProps;
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Fetch properties by type with caching
  Future<List<Property>> fetchPropertiesByType(PropertyType type) async {
    try {
      return await propertyRepository.getPropertiesByType(type);
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Fetch properties by owner with caching
  Future<List<Property>> fetchPropertiesByOwner(int ownerId) async {
    try {
      return await propertyRepository.getPropertiesByOwner(ownerId);
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Get real-time occupancy rate from repository
  Future<double> fetchOccupancyRate() async {
    try {
      return await propertyRepository.getOccupancyRate();
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Fetch a specific property by ID from server
  Future<Property> fetchPropertyById(int id) async {
    try {
      return await propertyRepository.getById(id.toString());
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  // CRUD operations (inherited from CollectionProvider but with type safety)

  /// Add a new property
  Future<void> addProperty(Property property) async {
    await addItem(property);
  }

  /// Update an existing property
  Future<void> updateProperty(Property property) async {
    await updateItem(property.id.toString(), property);
  }

  /// Delete a property
  Future<void> deleteProperty(int id) async {
    await removeItem(id.toString());
  }

  // Sorting and organization

  /// Sort properties by price (ascending)
  List<Property> sortByPriceAsc() {
    return sortItems((a, b) => a.price.compareTo(b.price));
  }

  /// Sort properties by price (descending)
  List<Property> sortByPriceDesc() {
    return sortItems((a, b) => b.price.compareTo(a.price));
  }

  /// Sort properties by date added (newest first)
  List<Property> sortByDateDesc() {
    return sortItems((a, b) => b.dateAdded.compareTo(a.dateAdded));
  }

  /// Sort properties by title alphabetically
  List<Property> sortByTitle() {
    return sortItems((a, b) => a.title.compareTo(b.title));
  }

  /// Sort properties by area (largest first)
  List<Property> sortByAreaDesc() {
    return sortItems((a, b) => b.area.compareTo(a.area));
  }

  // Statistics and insights

  /// Get property count by status
  Map<PropertyStatus, int> getPropertyCountByStatus() {
    final Map<PropertyStatus, int> counts = {};

    for (final status in PropertyStatus.values) {
      counts[status] = getPropertiesByStatus(status).length;
    }

    return counts;
  }

  /// Get property count by type
  Map<PropertyType, int> getPropertyCountByType() {
    final Map<PropertyType, int> counts = {};

    for (final type in PropertyType.values) {
      counts[type] = getPropertiesByType(type).length;
    }

    return counts;
  }

  /// Get average property price
  double get averagePrice {
    if (properties.isEmpty) return 0.0;

    final totalPrice = properties.fold<double>(
      0.0,
      (sum, property) => sum + property.price,
    );
    return totalPrice / properties.length;
  }

  /// Get average property area
  double get averageArea {
    if (properties.isEmpty) return 0.0;

    final totalArea = properties.fold<double>(
      0.0,
      (sum, property) => sum + property.area,
    );
    return totalArea / properties.length;
  }

  /// Get total rental value (sum of all property prices)
  double get totalRentalValue {
    return properties.fold<double>(
      0.0,
      (sum, property) => sum + property.price,
    );
  }

  // Special fetching methods for UI needs

  /// Fetch properties with filtering and sorting
  Future<void> fetchFilteredProperties({
    PropertyStatus? status,
    PropertyType? type,
    String? searchQuery,
    Map<String, dynamic>? additionalParams,
  }) async {
    final Map<String, dynamic> params = additionalParams ?? {};

    if (status != null) {
      params['status'] = status.toString().split('.').last;
    }
    if (type != null) {
      params['type'] = type.toString().split('.').last;
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      params['search'] = searchQuery;
    }

    await fetchItems(params.isNotEmpty ? params : null);
  }

  /// Refresh all properties
  Future<void> refreshProperties() async {
    await refreshItems();
  }
}
