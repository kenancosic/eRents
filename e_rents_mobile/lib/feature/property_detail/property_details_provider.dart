import 'package:e_rents_mobile/core/base/detail_provider.dart';
import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/core/models/review.dart';
import 'package:e_rents_mobile/core/repositories/property_repository.dart';

/// PropertyDetailProvider using the new repository architecture
/// Demonstrates the power of DetailProvider<Property> base class
///
/// ⭐ BEFORE: 80+ lines of manual state management
/// ✨ AFTER: 30 lines of business logic only!
class PropertyDetailProvider extends DetailProvider<Property> {
  PropertyDetailProvider(PropertyRepository super.repository);

  // Get the property repository with proper typing
  PropertyRepository get propertyRepository => repository as PropertyRepository;

  // Property-specific convenience getters (business logic only)
  Property? get property => item;

  // Business logic helpers
  bool get isAvailable => property?.status == PropertyStatus.available;
  String get title => property?.name ?? 'Unknown Property';
  double get price => property?.price ?? 0.0;
  String get currency => property?.currency ?? 'BAM';
  int get bedrooms => property?.bedrooms ?? 0;
  int get bathrooms => property?.bathrooms ?? 0;
  double get area => property?.area ?? 0.0;
  String get description => property?.description ?? '';
  List<int> get imageIds => property?.imageIds ?? [];
  List<int> get amenityIds => property?.amenityIds ?? [];

  // Address helpers
  String get fullAddress => property?.address?.getFullAddress() ?? 'No address';
  String get displayAddress =>
      property?.address?.getDisplayAddress() ?? 'No address';
  String get city => property?.address?.city ?? '';

  // Rating and review helpers
  double get averageRating => property?.averageRating ?? 0.0;
  bool get hasRating => averageRating > 0;
  String get ratingDisplay =>
      hasRating ? '${averageRating.toStringAsFixed(1)} ⭐' : 'No rating';

  // Availability helpers
  bool get isRented => property?.status == PropertyStatus.rented;
  bool get inMaintenance => property?.status == PropertyStatus.maintenance;
  bool get isUnavailable => property?.status == PropertyStatus.unavailable;

  // Property type helpers
  String get propertyTypeDisplay => property?.propertyType?.name ?? 'Unknown';
  String get rentalTypeDisplay => property?.rentalType.name ?? 'Monthly';

  // Pricing helpers
  String get priceDisplay => '${price.toStringAsFixed(2)} $currency';
  String get dailyRateDisplay => property?.dailyRate != null
      ? '${property!.dailyRate!.toStringAsFixed(2)} $currency/day'
      : 'N/A';

  // Property specifications
  String get specificationsDisplay {
    final specs = <String>[];
    if (bedrooms > 0) specs.add('$bedrooms bed${bedrooms > 1 ? 's' : ''}');
    if (bathrooms > 0) specs.add('$bathrooms bath${bathrooms > 1 ? 's' : ''}');
    if (area > 0) specs.add('${area.toStringAsFixed(0)} m²');
    return specs.isNotEmpty ? specs.join(' • ') : 'No specs available';
  }

  // Search properties by owner (for "More from this owner" functionality)
  Future<List<Property>> getPropertiesByOwner() async {
    if (property?.ownerId == null) return [];

    try {
      return await propertyRepository.getPropertiesByOwner(property!.ownerId);
    } catch (e) {
      return [];
    }
  }

  // Search similar properties
  Future<List<Property>> getSimilarProperties() async {
    if (property == null) return [];

    try {
      return await propertyRepository.searchProperties(
        propertyTypeId: property!.propertyTypeId,
        bedrooms: property!.bedrooms,
        minPrice: (property!.price * 0.8), // 20% price range
        maxPrice: (property!.price * 1.2),
      );
    } catch (e) {
      return [];
    }
  }

  // Legacy method compatibility - now just delegates to base class
  Future<void> fetchPropertyDetail(int propertyId) async {
    await loadItem(propertyId.toString());
  }

  // Legacy method compatibility - now just delegates to base class
  void clearPropertyDetail() {
    clearItem();
  }

  // Add review functionality (placeholder for now)
  void addReview(Review review) {
    // TODO: Implement review addition when ReviewRepository is integrated
    // This would typically involve:
    // 1. Call ReviewRepository to create the review
    // 2. Refresh the property to get updated rating
    // 3. Notify listeners
    notifyListeners();
  }
}
