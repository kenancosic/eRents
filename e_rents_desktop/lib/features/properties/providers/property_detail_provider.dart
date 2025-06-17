import 'package:flutter/foundation.dart';
import '../../../base/base.dart';
import '../../../models/property.dart';
import '../../../models/renting_type.dart';

import '../../../models/review.dart';
import '../../../services/review_service.dart';

/// Detail provider for managing single property data
///
/// Replaces part of the old PropertyDetailsProvider with a cleaner implementation
/// focused only on property detail management. Related data (bookings, reviews, etc.)
/// are handled by separate specialized providers.
class PropertyDetailProvider extends DetailProvider<Property> {
  final ReviewService reviewService;

  PropertyDetailProvider(
    PropertyRepository super.repository, {
    required this.reviewService,
  });

  /// Get the property repository with proper typing
  PropertyRepository get propertyRepository => repository as PropertyRepository;

  /// List of reviews for the current property
  List<Review> reviews = [];
  bool areReviewsLoading = false;
  AppError? reviewsError;

  // Review pagination state
  int _currentReviewPage = 1;
  int _reviewPageSize = 5; // Show 5 reviews initially for property details
  int _totalReviewCount = 0;
  bool _hasMoreReviews = false;

  // Review pagination getters
  int get currentReviewPage => _currentReviewPage;
  int get reviewPageSize => _reviewPageSize;
  int get totalReviewCount => _totalReviewCount;
  bool get hasMoreReviews => _hasMoreReviews;

  // Property-specific convenience getters

  /// Get the current property (alias for item)
  Property? get property => item;

  /// Check if property is available for rent
  bool get isAvailable => property?.propertyStatus == PropertyStatus.available;

  /// Check if property is currently rented
  bool get isRented => property?.propertyStatus == PropertyStatus.rented;

  /// Check if property is under maintenance
  bool get inMaintenance =>
      property?.propertyStatus == PropertyStatus.maintenance;

  /// Get property title safely
  String get title => property?.name ?? 'Unknown Property';

  /// Get property description safely
  String get description => property?.description ?? '';

  /// Get property price safely
  double get price => property?.price ?? 0.0;

  /// Get property currency safely
  String get currency => property?.currency ?? 'BAM';

  /// Get property type safely - NO FALLBACK to avoid masking data issues
  PropertyType? get propertyType => property?.type;

  /// Get property renting type safely - NO FALLBACK to avoid masking data issues
  RentingType? get rentingType => property?.rentingType;

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

  /// Check if property has minimum stay requirement
  bool get hasMinimumStay => property?.minimumStayDays != null;

  /// Get minimum stay days safely
  int get minimumStayDays => property?.minimumStayDays ?? 0;

  // Business logic methods

  /// Calculate monthly income potential
  double get monthlyIncomeEstimate {
    if (property == null || rentingType == null) return 0.0;

    switch (rentingType!) {
      case RentingType.daily:
        // Assume 70% occupancy rate for daily rentals
        return property!.price * 30 * 0.7;
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
    switch (property?.propertyStatus) {
      case PropertyStatus.available:
        return 'Available';
      case PropertyStatus.rented:
        return 'Rented';
      case PropertyStatus.maintenance:
        return 'Under Maintenance';
      case PropertyStatus.unavailable:
        return 'Unavailable';
      case null:
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
      case null:
        return 'Unknown';
    }
  }

  /// Get renting type display text with improved error handling
  String get rentingTypeDisplayText {
    if (rentingType == null) {
      return 'Type Unknown';
    }

    switch (rentingType!) {
      case RentingType.daily:
        return 'Daily Rental';
      case RentingType.monthly:
        return 'Monthly Rental';
    }
  }

  /// Get renting type display name for UI consistency
  String get rentingTypeDisplayName {
    return rentingType?.displayName ?? 'Unknown';
  }

  // Enhanced loading methods

  /// Load property by ID with enhanced error handling and debugging
  Future<void> loadPropertyById(int id) async {
    debugPrint('🏠 PropertyDetailProvider: Loading property ID: $id');

    // Reset previous data
    reviews = [];

    // Load property and then reviews
    await loadItem(id.toString());

    // Debug logging
    if (item != null) {
      debugPrint('🏠 PropertyDetailProvider: Property loaded successfully');
      debugPrint('🏠 PropertyDetailProvider: Property name: ${item!.name}');
      debugPrint(
        '🏠 PropertyDetailProvider: Renting type: ${item!.rentingType}',
      );
      debugPrint(
        '🏠 PropertyDetailProvider: Renting type display: ${item!.rentingType.displayName}',
      );

      await _loadReviews(id.toString());
    } else {
      debugPrint(
        '🏠 PropertyDetailProvider: Failed to load property or property is null',
      );
    }
  }

  /// Load reviews for a given property ID
  Future<void> _loadReviews(String propertyId) async {
    areReviewsLoading = true;
    reviewsError = null;
    safeNotifyListeners();

    try {
      // Reset pagination state
      _currentReviewPage = 1;
      reviews = [];

      // Load first page of reviews using new paginated method
      final reviewData = await reviewService.getPagedPropertyReviews(
        propertyId,
        page: _currentReviewPage,
        pageSize: _reviewPageSize,
      );

      reviews = reviewData['reviews'] as List<Review>;
      _totalReviewCount = reviewData['totalCount'] as int;
      _hasMoreReviews = reviewData['hasNextPage'] as bool;

      debugPrint(
        '🏠 PropertyDetailProvider: Loaded ${reviews.length} reviews (page $_currentReviewPage of ${reviewData['totalPages']})',
      );
    } catch (e, stackTrace) {
      reviewsError = AppError.fromException(e, stackTrace);
      debugPrint('🏠 PropertyDetailProvider: Failed to load reviews: $e');
    } finally {
      areReviewsLoading = false;
      safeNotifyListeners();
    }
  }

  /// Load more reviews (next page)
  Future<void> loadMoreReviews() async {
    if (!_hasMoreReviews || areReviewsLoading || property == null) return;

    areReviewsLoading = true;
    safeNotifyListeners();

    try {
      _currentReviewPage++;

      final reviewData = await reviewService.getPagedPropertyReviews(
        property!.propertyId.toString(),
        page: _currentReviewPage,
        pageSize: _reviewPageSize,
      );

      final newReviews = reviewData['reviews'] as List<Review>;
      reviews.addAll(newReviews);
      _hasMoreReviews = reviewData['hasNextPage'] as bool;

      debugPrint(
        '🏠 PropertyDetailProvider: Loaded ${newReviews.length} more reviews (page $_currentReviewPage)',
      );
    } catch (e, stackTrace) {
      reviewsError = AppError.fromException(e, stackTrace);
      debugPrint('🏠 PropertyDetailProvider: Failed to load more reviews: $e');
      _currentReviewPage--; // Revert page increment on error
    } finally {
      areReviewsLoading = false;
      safeNotifyListeners();
    }
  }

  /// Refresh reviews (reload first page)
  Future<void> refreshReviews() async {
    if (property != null) {
      await _loadReviews(property!.propertyId.toString());
    }
  }

  /// Submit a reply to a review
  Future<bool> submitReply(int parentReviewId, String replyText) async {
    if (property == null || replyText.trim().isEmpty) return false;

    try {
      debugPrint(
        '🏠 PropertyDetailProvider: Submitting reply to review $parentReviewId',
      );

      // Submit the reply using the review service
      final reply = await reviewService.createReply(
        parentReviewId: parentReviewId,
        description: replyText.trim(),
      );

      debugPrint(
        '🏠 PropertyDetailProvider: Reply submitted successfully with ID ${reply.id}',
      );

      // Refresh reviews to show the new reply
      await refreshReviews();

      return true;
    } catch (e, stackTrace) {
      reviewsError = AppError.fromException(e, stackTrace);
      debugPrint('🏠 PropertyDetailProvider: Failed to submit reply: $e');
      safeNotifyListeners();
      return false;
    }
  }

  /// Check if current user can reply to reviews (property owner)
  bool get canReplyToReviews {
    return property != null;
  }

  /// Refresh property data from server
  Future<void> refreshProperty() async {
    if (property != null) {
      debugPrint(
        '🏠 PropertyDetailProvider: Refreshing property ${property!.propertyId}',
      );
      await loadPropertyById(property!.propertyId);
    }
  }

  /// Force reload property from server (bypass cache)
  Future<void> forceReloadProperty() async {
    if (property != null) {
      debugPrint(
        '🏠 PropertyDetailProvider: Force reloading property ${property!.propertyId}',
      );
      await propertyRepository.clearCache();
      await loadPropertyById(property!.propertyId);
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
        area > 0 &&
        propertyType != null &&
        rentingType != null;
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
    if (propertyType == null) errors.add('Property type is missing');
    if (rentingType == null) errors.add('Renting type is missing');

    return errors;
  }

  /// Check if property is valid for display
  bool get isValidForDisplay => validationErrors.isEmpty;

  // Helper methods for UI

  /// Get formatted price string with proper handling
  String getFormattedPrice() {
    if (property == null) return 'N/A';
    if (rentingType == null) return '${price.toStringAsFixed(0)} $currency';

    final priceText = '${price.toStringAsFixed(0)} $currency';

    switch (rentingType!) {
      case RentingType.daily:
        return '$priceText/day';
      case RentingType.monthly:
        return '$priceText/month';
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

  /// Check if property has consistent data
  bool get hasConsistentData {
    return property != null &&
        propertyType != null &&
        rentingType != null &&
        validationErrors.isEmpty;
  }

  /// Get debug information for troubleshooting
  String get debugInfo {
    if (property == null) return 'Property is null';

    return '''
Property ID: ${property!.propertyId}
Property Name: ${property!.name}
Property Type: ${propertyType?.toString() ?? 'NULL'}
Renting Type: ${rentingType?.toString() ?? 'NULL'}
Renting Type Display: ${rentingType?.displayName ?? 'NULL'}
Price: ${property!.price} ${property!.currency}
Status: ${property!.status}
    ''';
  }
}
