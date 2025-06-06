import '../../../base/base.dart';
import '../../../models/property.dart';
import '../../../models/renting_type.dart';
import '../../../repositories/property_repository.dart';

/// Detail provider for managing single property data
///
/// Replaces part of the old PropertyDetailsProvider with a cleaner implementation
/// focused only on property detail management. Related data (bookings, reviews, etc.)
/// are handled by separate specialized providers.
class PropertyDetailProvider extends DetailProvider<Property> {
  PropertyDetailProvider(PropertyRepository super.repository);

  /// Get the property repository with proper typing
  PropertyRepository get propertyRepository => repository as PropertyRepository;

  // Implementation required by DetailProvider
  @override
  String _getItemId(Property item) => item.id.toString();

  // Property-specific convenience getters

  /// Get the current property (alias for item)
  Property? get property => item;

  /// Check if property is available for rent
  bool get isAvailable => property?.status == PropertyStatus.available;

  /// Check if property is currently rented
  bool get isRented => property?.status == PropertyStatus.rented;

  /// Check if property is under maintenance
  bool get inMaintenance => property?.status == PropertyStatus.maintenance;

  /// Get property title safely
  String get title => property?.title ?? 'Unknown Property';

  /// Get property description safely
  String get description => property?.description ?? '';

  /// Get property price safely
  double get price => property?.price ?? 0.0;

  /// Get property currency safely
  String get currency => property?.currency ?? 'BAM';

  /// Get property type safely
  PropertyType get propertyType => property?.type ?? PropertyType.apartment;

  /// Get property renting type safely
  RentingType get rentingType => property?.rentingType ?? RentingType.monthly;

  /// Get number of bedrooms safely
  int get bedrooms => property?.bedrooms ?? 0;

  /// Get number of bathrooms safely
  int get bathrooms => property?.bathrooms ?? 0;

  /// Get property area safely
  double get area => property?.area ?? 0.0;

  /// Get property images safely
  List<int> get images => property?.imageIds ?? [];

  /// Get property amenities safely
  List<int> get amenities => property?.amenityIds ?? [];

  /// Get property amenity IDs safely
  List<int> get amenityIds => property?.amenityIds ?? [];

  /// Get property address safely
  String get address =>
      property?.address?.getFullAddress() ?? 'Address not available';

  /// Get property owner ID safely
  int get ownerId => property?.ownerId ?? 0;

  /// Get date property was added safely
  DateTime get dateAdded => property?.dateAdded ?? DateTime.now();

  // Property status checks

  /// Check if property has images
  bool get hasImages => images.isNotEmpty;

  /// Check if property has amenities
  bool get hasAmenities => amenities.isNotEmpty;

  /// Check if property has address details
  bool get hasAddress => property?.address != null;

  /// Check if property has daily rate
  bool get hasDailyRate => property?.dailyRate != null;

  /// Get daily rate safely
  double get dailyRate => property?.dailyRate ?? 0.0;

  /// Check if property has minimum stay requirement
  bool get hasMinimumStay => property?.minimumStayDays != null;

  /// Get minimum stay days safely
  int get minimumStayDays => property?.minimumStayDays ?? 0;

  // Business logic methods

  /// Calculate monthly income potential
  double get monthlyIncomeEstimate {
    if (property == null) return 0.0;

    switch (property!.rentingType) {
      case RentingType.daily:
        // Assume 70% occupancy rate for daily rentals
        return (property!.dailyRate ?? property!.price) * 30 * 0.7;
      case RentingType.monthly:
        return property!.price;
    }
  }

  /// Calculate area per bedroom ratio
  double get areaPerBedroom {
    if (property == null || bedrooms == 0) return 0.0;
    return area / bedrooms;
  }

  /// Get property status display text
  String get statusDisplayText {
    switch (property?.status) {
      case PropertyStatus.available:
        return 'Available';
      case PropertyStatus.rented:
        return 'Rented';
      case PropertyStatus.maintenance:
        return 'Under Maintenance';
      case PropertyStatus.unavailable:
        return 'Unavailable';
      default:
        return 'Unknown';
    }
  }

  /// Get property type display text
  String get typeDisplayText {
    switch (propertyType) {
      case PropertyType.apartment:
        return 'Apartment';
      case PropertyType.house:
        return 'House';
      case PropertyType.condo:
        return 'Condominium';
      case PropertyType.townhouse:
        return 'Townhouse';
      case PropertyType.studio:
        return 'Studio';
      default:
        return 'Unknown';
    }
  }

  /// Get renting type display text
  String get rentingTypeDisplayText {
    switch (rentingType) {
      case RentingType.daily:
        return 'Daily Rental';
      case RentingType.monthly:
        return 'Monthly Rental';
    }
  }

  // Enhanced loading methods

  /// Load property by ID with enhanced error handling
  Future<void> loadPropertyById(int id) async {
    await loadItem(id.toString());
  }

  /// Refresh property data from server
  Future<void> refreshProperty() async {
    if (property != null) {
      await loadPropertyById(property!.id);
    }
  }

  /// Force reload property from server (bypass cache)
  Future<void> forceReloadProperty() async {
    if (property != null) {
      await propertyRepository.clearCache();
      await loadPropertyById(property!.id);
    }
  }

  // Validation methods

  /// Check if property data is complete
  bool get isDataComplete {
    return property != null &&
        title.isNotEmpty &&
        description.isNotEmpty &&
        price > 0 &&
        bedrooms > 0 &&
        bathrooms > 0 &&
        area > 0;
  }

  /// Get validation errors for property data
  List<String> get validationErrors {
    final errors = <String>[];

    if (property == null) {
      errors.add('Property data not loaded');
      return errors;
    }

    if (title.isEmpty) errors.add('Property title is missing');
    if (description.isEmpty) errors.add('Property description is missing');
    if (price <= 0) errors.add('Property price must be greater than 0');
    if (bedrooms <= 0) errors.add('Property must have at least 1 bedroom');
    if (bathrooms <= 0) errors.add('Property must have at least 1 bathroom');
    if (area <= 0) errors.add('Property area must be greater than 0');

    return errors;
  }

  /// Check if property is valid for display
  bool get isValidForDisplay => validationErrors.isEmpty;

  // Helper methods for UI

  /// Get formatted price string
  String getFormattedPrice() {
    if (property == null) return 'N/A';

    final priceText = '${price.toStringAsFixed(0)} $currency';

    switch (rentingType) {
      case RentingType.daily:
        return '$priceText/day';
      case RentingType.monthly:
        return '$priceText/month';
      default:
        return priceText;
    }
  }

  /// Get formatted area string
  String getFormattedArea() {
    if (area <= 0) return 'N/A';
    return '${area.toStringAsFixed(1)} m²';
  }

  /// Get bedroom/bathroom info string
  String getBedroomBathroomInfo() {
    return '$bedrooms bed${bedrooms != 1 ? 's' : ''}, $bathrooms bath${bathrooms != 1 ? 's' : ''}';
  }

  /// Get property summary for display
  String getPropertySummary() {
    if (property == null) return 'Property information unavailable';

    return '${getBedroomBathroomInfo()}, ${getFormattedArea()}, ${getFormattedPrice()}';
  }
}
