import 'package:flutter/foundation.dart';
import 'package:e_rents_mobile/core/base/collection_provider.dart';
import 'package:e_rents_mobile/core/repositories/review_repository.dart';
import 'package:e_rents_mobile/core/models/review.dart';

/// Collection provider for managing review lists
/// Extends CollectionProvider for automatic state management with reviews
class ReviewCollectionProvider extends CollectionProvider<Review> {
  ReviewCollectionProvider(ReviewRepository repository) : super(repository);

  // Get the review repository with proper typing
  ReviewRepository get reviewRepository => repository as ReviewRepository;

  // Convenience getters for different review types
  List<Review> get propertyReviews {
    return items
        .where((review) => review.reviewType == ReviewType.propertyReview)
        .toList();
  }

  List<Review> get tenantReviews {
    return items
        .where((review) => review.reviewType == ReviewType.tenantReview)
        .toList();
  }

  List<Review> get landlordReviews {
    return items
        .where((review) => review.reviewType == ReviewType.landlordReview)
        .toList();
  }

  List<Review> get topLevelReviews {
    return items.where((review) => review.parentReviewId == null).toList();
  }

  List<Review> get positiveReviews {
    return items.where((review) => review.isPositiveReview).toList();
  }

  List<Review> get negativeReviews {
    return items.where((review) => review.isNegativeReview).toList();
  }

  @override
  bool matchesSearch(Review item, String query) {
    final lowerQuery = query.toLowerCase();
    return (item.description?.toLowerCase().contains(lowerQuery) == true) ||
        item.reviewTypeDisplay.toLowerCase().contains(lowerQuery) ||
        item.reviewerId.toString().contains(query) ||
        item.revieweeId.toString().contains(query);
  }

  @override
  bool matchesFilters(Review item, Map<String, dynamic> filters) {
    // Property ID filter
    if (filters.containsKey('propertyId')) {
      final propertyId = filters['propertyId'] as int?;
      if (propertyId != null && item.propertyId != propertyId) {
        return false;
      }
    }

    // Review type filter
    if (filters.containsKey('reviewType')) {
      final reviewType = filters['reviewType'] as ReviewType?;
      if (reviewType != null && item.reviewType != reviewType) {
        return false;
      }
    }

    // Rating range filter
    if (filters.containsKey('minRating')) {
      final minRating = filters['minRating'] as double?;
      if (minRating != null &&
          (item.starRating == null || item.starRating! < minRating)) {
        return false;
      }
    }

    if (filters.containsKey('maxRating')) {
      final maxRating = filters['maxRating'] as double?;
      if (maxRating != null &&
          (item.starRating == null || item.starRating! > maxRating)) {
        return false;
      }
    }

    // Reviewer filter
    if (filters.containsKey('reviewerId')) {
      final reviewerId = filters['reviewerId'] as int?;
      if (reviewerId != null && item.reviewerId != reviewerId) {
        return false;
      }
    }

    // Reviewee filter
    if (filters.containsKey('revieweeId')) {
      final revieweeId = filters['revieweeId'] as int?;
      if (revieweeId != null && item.revieweeId != revieweeId) {
        return false;
      }
    }

    // Verified reviews filter
    if (filters.containsKey('isVerified')) {
      final isVerified = filters['isVerified'] as bool?;
      if (isVerified != null && item.isVerified != isVerified) {
        return false;
      }
    }

    return true;
  }

  // Convenience methods for common review operations

  /// Load reviews for a specific property
  Future<void> loadPropertyReviews(int propertyId) async {
    await loadItems({
      'propertyId': propertyId,
      'reviewType': ReviewType.propertyReview.name
    });
  }

  /// Load reviews by a specific user (reviewer)
  Future<void> loadReviewsByUser(int userId) async {
    await loadItems({'reviewerId': userId});
  }

  /// Load reviews for a specific user (reviewee)
  Future<void> loadReviewsForUser(int userId) async {
    await loadItems({'revieweeId': userId});
  }

  /// Load reviews for a specific booking
  Future<void> loadBookingReviews(int bookingId) async {
    await loadItems({'bookingId': bookingId});
  }

  /// Filter by review type
  void filterByReviewType(ReviewType? reviewType) {
    if (reviewType != null) {
      applyFilters({'reviewType': reviewType});
    } else {
      clearSearchAndFilters();
    }
  }

  /// Filter by property
  void filterByProperty(int? propertyId) {
    if (propertyId != null) {
      applyFilters({'propertyId': propertyId});
    } else {
      clearSearchAndFilters();
    }
  }

  /// Filter by rating range
  void filterByRatingRange(double? minRating, double? maxRating) {
    final filters = <String, dynamic>{};
    if (minRating != null) filters['minRating'] = minRating;
    if (maxRating != null) filters['maxRating'] = maxRating;

    if (filters.isNotEmpty) {
      applyFilters(filters);
    } else {
      clearSearchAndFilters();
    }
  }

  /// Filter by verified reviews only
  void filterByVerified(bool? verifiedOnly) {
    if (verifiedOnly == true) {
      applyFilters({'isVerified': true});
    } else {
      clearSearchAndFilters();
    }
  }

  /// Get average rating for current filtered reviews
  double get averageRating {
    if (items.isEmpty) return 0.0;

    final ratingsOnly = items
        .where((review) => review.starRating != null)
        .map((review) => review.starRating!)
        .toList();

    if (ratingsOnly.isEmpty) return 0.0;

    return ratingsOnly.reduce((a, b) => a + b) / ratingsOnly.length;
  }

  /// Get review count by rating
  Map<int, int> get ratingDistribution {
    final distribution = <int, int>{};

    for (int i = 1; i <= 5; i++) {
      distribution[i] = 0;
    }

    for (final review in items) {
      if (review.starRating != null) {
        final rating = review.starRating!.round();
        if (rating >= 1 && rating <= 5) {
          distribution[rating] = (distribution[rating] ?? 0) + 1;
        }
      }
    }

    return distribution;
  }

  /// Create a new review
  Future<void> createReview({
    required ReviewType reviewType,
    int? propertyId,
    required int revieweeId,
    required int reviewerId,
    String? description,
    double? starRating,
    int? bookingId,
    int? parentReviewId,
  }) async {
    await execute(() async {
      debugPrint('ReviewCollectionProvider: Creating new review');

      final review = Review(
        reviewId: 0, // Will be set by server
        reviewType: reviewType,
        propertyId: propertyId,
        revieweeId: revieweeId,
        reviewerId: reviewerId,
        description: description,
        starRating: starRating,
        dateCreated: DateTime.now(),
        bookingId: bookingId,
        parentReviewId: parentReviewId,
      );

      final createdReview = await repository.create(review);

      // Add to local collection and refresh search/filters
      allItems.add(createdReview);
      searchItems(
          searchQuery); // This triggers _applySearchAndFilters internally

      debugPrint('ReviewCollectionProvider: Review created successfully');
    });
  }

  /// Filter reviews by type
  void filterByType(ReviewType type) {
    applyFilters({'reviewType': type.name});
  }

  /// Filter reviews by date range
  void filterByDateRange(DateTime? fromDate, DateTime? toDate) {
    final filters = <String, dynamic>{};
    if (fromDate != null) filters['fromDate'] = fromDate;
    if (toDate != null) filters['toDate'] = toDate;
    applyFilters(filters);
  }
}
