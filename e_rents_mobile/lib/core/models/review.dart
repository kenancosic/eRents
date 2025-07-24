/// Review model aligned with backend entity structure for universal filtering
///
/// Backend Review Entity fields:
/// - ReviewId, ReviewType (enum), PropertyId, RevieweeId, ReviewerId
/// - Description, DateCreated, StarRating, BookingId, ParentReviewId
library;

enum ReviewType {
  propertyReview, // Review of a property by a tenant
  tenantReview, // Review of a tenant by a landlord
  landlordReview, // Review of a landlord by a tenant
  responseReview, // Response to another review
}

class Review {
  final int reviewId;
  final ReviewType reviewType; // ✅ NEW: Critical enum field
  final int? propertyId; // ✅ Correct (optional for tenant reviews)
  final int revieweeId; // ✅ NEW: Who is being reviewed
  final int reviewerId; // ✅ NEW: Who is writing the review
  final String? description; // ✅ Correct
  final DateTime dateCreated; // ✅ RENAMED: from dateReported
  final double? starRating; // ✅ Correct (1-5 scale)
  final int? bookingId; // ✅ NEW: Associated booking
  final int? parentReviewId; // ✅ NEW: For threading/responses

  // Additional fields for enhanced functionality
  final bool? isVerified; // If reviewer had actual booking
  final bool? isResponse; // If this is a response to another review
  final DateTime? lastModified; // Track updates
  final String? moderatorNotes; // Admin/moderation notes

  Review({
    required this.reviewId,
    required this.reviewType,
    this.propertyId,
    required this.revieweeId,
    required this.reviewerId,
    this.description,
    required this.dateCreated,
    this.starRating,
    this.bookingId,
    this.parentReviewId,
    this.isVerified,
    this.isResponse,
    this.lastModified,
    this.moderatorNotes,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      reviewId: json['reviewId'] as int,
      reviewType: ReviewType.values.firstWhere(
        (e) =>
            e.name.toLowerCase() ==
            (json['reviewType'] as String).toLowerCase(),
        orElse: () => ReviewType.propertyReview,
      ),
      propertyId: json['propertyId'] as int?,
      revieweeId: json['revieweeId'] as int,
      reviewerId: json['reviewerId'] as int,
      description: json['description'] as String?,
      dateCreated: DateTime.parse(json['dateCreated'] as String),
      starRating: (json['starRating'] as num?)?.toDouble(),
      bookingId: json['bookingId'] as int?,
      parentReviewId: json['parentReviewId'] as int?,
      isVerified: json['isVerified'] as bool?,
      isResponse: json['isResponse'] as bool?,
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'] as String)
          : null,
      moderatorNotes: json['moderatorNotes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reviewId': reviewId,
      'reviewType': reviewType.name,
      'propertyId': propertyId,
      'revieweeId': revieweeId,
      'reviewerId': reviewerId,
      'description': description,
      'dateCreated': dateCreated.toIso8601String(),
      'starRating': starRating,
      'bookingId': bookingId,
      'parentReviewId': parentReviewId,
      'isVerified': isVerified,
      'isResponse': isResponse,
      'lastModified': lastModified?.toIso8601String(),
      'moderatorNotes': moderatorNotes,
    };
  }

  /// Helper methods for UI
  String get reviewTypeDisplay {
    switch (reviewType) {
      case ReviewType.propertyReview:
        return 'Property Review';
      case ReviewType.tenantReview:
        return 'Tenant Review';
      case ReviewType.landlordReview:
        return 'Landlord Review';
      case ReviewType.responseReview:
        return 'Response';
    }
  }

  bool get hasRating => starRating != null && starRating! > 0;

  bool get isPositiveReview => starRating != null && starRating! >= 4.0;

  bool get isNegativeReview => starRating != null && starRating! <= 2.0;

  String get ratingDisplay {
    if (starRating == null) return 'No rating';
    return '${starRating!.toStringAsFixed(1)} ⭐';
  }

  /// Check if this review can have responses
  bool get canHaveResponses => parentReviewId == null; // Only top-level reviews

  /// Check if this is a threaded response
  bool get isThreadedResponse => parentReviewId != null;

  /// Copy with method for updates
  Review copyWith({
    int? reviewId,
    ReviewType? reviewType,
    int? propertyId,
    int? revieweeId,
    int? reviewerId,
    String? description,
    DateTime? dateCreated,
    double? starRating,
    int? bookingId,
    int? parentReviewId,
    bool? isVerified,
    bool? isResponse,
    DateTime? lastModified,
    String? moderatorNotes,
  }) {
    return Review(
      reviewId: reviewId ?? this.reviewId,
      reviewType: reviewType ?? this.reviewType,
      propertyId: propertyId ?? this.propertyId,
      revieweeId: revieweeId ?? this.revieweeId,
      reviewerId: reviewerId ?? this.reviewerId,
      description: description ?? this.description,
      dateCreated: dateCreated ?? this.dateCreated,
      starRating: starRating ?? this.starRating,
      bookingId: bookingId ?? this.bookingId,
      parentReviewId: parentReviewId ?? this.parentReviewId,
      isVerified: isVerified ?? this.isVerified,
      isResponse: isResponse ?? this.isResponse,
      lastModified: lastModified ?? this.lastModified,
      moderatorNotes: moderatorNotes ?? this.moderatorNotes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Review &&
        other.reviewId == reviewId &&
        other.reviewType == reviewType &&
        other.propertyId == propertyId &&
        other.revieweeId == revieweeId &&
        other.reviewerId == reviewerId;
  }

  @override
  int get hashCode {
    return Object.hash(
      reviewId,
      reviewType,
      propertyId,
      revieweeId,
      reviewerId,
    );
  }

  @override
  String toString() {
    return 'Review(id: $reviewId, type: ${reviewType.name}, rating: $starRating)';
  }
}
