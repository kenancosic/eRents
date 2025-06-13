import "package:e_rents_mobile/core/base/base_repository.dart";
import "package:e_rents_mobile/core/models/review.dart";
import "package:e_rents_mobile/core/services/review_service.dart";
import "package:e_rents_mobile/core/services/cache_manager.dart";

/// Concrete repository for Review entities
/// Implements BaseRepository pattern with Review-specific logic and full CRUD operations
class ReviewRepository extends BaseRepository<Review, ReviewService> {
  ReviewRepository({
    required ReviewService service,
    required CacheManager cacheManager,
  }) : super(service: service, cacheManager: cacheManager);

  @override
  String get resourceName => "reviews";

  @override
  Duration get cacheTtl => const Duration(minutes: 15);

  @override
  Future<Review?> fetchFromService(String id) async {
    final reviewId = int.tryParse(id);
    if (reviewId == null) {
      throw ArgumentError("Invalid review ID: $id");
    }
    return await service.getReviewById(reviewId);
  }

  @override
  Future<List<Review>> fetchAllFromService(
      [Map<String, dynamic>? params]) async {
    return await service.getReviews(params);
  }

  @override
  Future<Review> createInService(Review item) async {
    return await service.createReview(item);
  }

  @override
  Future<Review> updateInService(String id, Review item) async {
    final reviewId = int.tryParse(id);
    if (reviewId == null) {
      throw ArgumentError("Invalid review ID: $id");
    }
    return await service.updateReview(reviewId, item);
  }

  @override
  Future<bool> deleteInService(String id) async {
    final reviewId = int.tryParse(id);
    if (reviewId == null) {
      throw ArgumentError("Invalid review ID: $id");
    }
    return await service.deleteReview(reviewId);
  }

  @override
  Map<String, dynamic> toJson(Review item) {
    return item.toJson();
  }

  @override
  Review fromJson(Map<String, dynamic> json) {
    return Review.fromJson(json);
  }

  @override
  String getItemId(Review item) {
    return item.reviewId.toString();
  }

  // Review-specific methods with backend universal filtering support

  /// Search reviews with filters compatible with backend universal filtering
  Future<List<Review>> searchReviews({
    ReviewType? reviewType,
    int? propertyId,
    int? revieweeId,
    int? reviewerId,
    int? bookingId,
    int? parentReviewId,
    double? minStarRating,
    double? maxStarRating,
    DateTime? fromDate,
    DateTime? toDate,
    bool? isVerified,
    bool? isResponse,
  }) async {
    final searchParams = <String, dynamic>{};

    // Add non-null parameters for backend universal filtering
    if (reviewType != null) searchParams['reviewType'] = reviewType.name;
    if (propertyId != null) searchParams['propertyId'] = propertyId;
    if (revieweeId != null) searchParams['revieweeId'] = revieweeId;
    if (reviewerId != null) searchParams['reviewerId'] = reviewerId;
    if (bookingId != null) searchParams['bookingId'] = bookingId;
    if (parentReviewId != null) searchParams['parentReviewId'] = parentReviewId;
    if (isVerified != null) searchParams['isVerified'] = isVerified;
    if (isResponse != null) searchParams['isResponse'] = isResponse;

    // Range filtering for star rating
    if (minStarRating != null) searchParams['minStarRating'] = minStarRating;
    if (maxStarRating != null) searchParams['maxStarRating'] = maxStarRating;

    // Date range filtering
    if (fromDate != null) searchParams['fromDate'] = fromDate.toIso8601String();
    if (toDate != null) searchParams['toDate'] = toDate.toIso8601String();

    return await getAll(searchParams);
  }

  /// Get reviews for a specific property
  Future<List<Review>> getPropertyReviews(int propertyId) async {
    return await searchReviews(
      reviewType: ReviewType.propertyReview,
      propertyId: propertyId,
    );
  }

  /// Get reviews by a specific user (reviewer)
  Future<List<Review>> getReviewsByUser(int userId) async {
    return await searchReviews(reviewerId: userId);
  }

  /// Get reviews for a specific user (reviewee)
  Future<List<Review>> getReviewsForUser(int userId) async {
    return await searchReviews(revieweeId: userId);
  }

  /// Get reviews for a specific booking
  Future<List<Review>> getBookingReviews(int bookingId) async {
    return await searchReviews(bookingId: bookingId);
  }

  /// Get response reviews for a parent review
  Future<List<Review>> getResponseReviews(int parentReviewId) async {
    return await searchReviews(
      reviewType: ReviewType.responseReview,
      parentReviewId: parentReviewId,
    );
  }

  /// Get only verified reviews (from actual bookings)
  Future<List<Review>> getVerifiedReviews() async {
    return await searchReviews(isVerified: true);
  }

  /// Get reviews within a rating range
  Future<List<Review>> getReviewsByRatingRange(
      double minRating, double maxRating) async {
    return await searchReviews(
      minStarRating: minRating,
      maxStarRating: maxRating,
    );
  }
}

/// Search object for Review filtering - matches backend SearchObject exactly
class ReviewSearchObject {
  // Direct entity field matches (automatic filtering)
  final ReviewType? reviewType;
  final int? propertyId;
  final int? revieweeId;
  final int? reviewerId;
  final int? bookingId;
  final int? parentReviewId;
  final bool? isVerified;
  final bool? isResponse;

  // Range filtering (Min/Max pairs)
  final double? minStarRating;
  final double? maxStarRating;
  final DateTime? fromDate; // → dateCreated >=
  final DateTime? toDate; // → dateCreated <=

  // Pagination and sorting (standard fields)
  final int? page;
  final int? pageSize;
  final String? sortBy;
  final String? sortDirection;

  ReviewSearchObject({
    this.reviewType,
    this.propertyId,
    this.revieweeId,
    this.reviewerId,
    this.bookingId,
    this.parentReviewId,
    this.isVerified,
    this.isResponse,
    this.minStarRating,
    this.maxStarRating,
    this.fromDate,
    this.toDate,
    this.page,
    this.pageSize,
    this.sortBy,
    this.sortDirection,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (reviewType != null) json['reviewType'] = reviewType!.name;
    if (propertyId != null) json['propertyId'] = propertyId;
    if (revieweeId != null) json['revieweeId'] = revieweeId;
    if (reviewerId != null) json['reviewerId'] = reviewerId;
    if (bookingId != null) json['bookingId'] = bookingId;
    if (parentReviewId != null) json['parentReviewId'] = parentReviewId;
    if (isVerified != null) json['isVerified'] = isVerified;
    if (isResponse != null) json['isResponse'] = isResponse;
    if (minStarRating != null) json['minStarRating'] = minStarRating;
    if (maxStarRating != null) json['maxStarRating'] = maxStarRating;
    if (fromDate != null) json['fromDate'] = fromDate!.toIso8601String();
    if (toDate != null) json['toDate'] = toDate!.toIso8601String();
    if (page != null) json['page'] = page! + 1; // Convert 0-based to 1-based
    if (pageSize != null) json['pageSize'] = pageSize;
    if (sortBy != null) json['sortBy'] = sortBy;
    if (sortDirection != null) json['sortDirection'] = sortDirection;

    return json;
  }
}
