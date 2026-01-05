/// Review model aligned with backend entity structure for universal filtering
///
/// Backend Review Entity fields:
/// - ReviewId, ReviewType (enum), PropertyId, RevieweeId, ReviewerId
/// - Description, DateCreated, StarRating, BookingId, ParentReviewId
import 'package:e_rents_mobile/core/enums/review_enums.dart';

class Review {
  final int reviewId;
  final ReviewType reviewType; // ✅ NEW: Critical enum field
  final int? propertyId; // ✅ Correct (optional for tenant reviews)
  final int revieweeId; // ✅ NEW: Who is being reviewed
  final int reviewerId; // ✅ NEW: Who is writing the review
  final String? reviewerFirstName; // ✅ NEW: Reviewer's first name
  final String? reviewerLastName; // ✅ NEW: Reviewer's last name
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
    this.reviewerFirstName,
    this.reviewerLastName,
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
    // Handle both current API format and backend DTO format
    final reviewId = json['reviewId'] as int? ?? json['ReviewId'] as int? ?? 0;
    final propertyId = json['propertyId'] as int? ?? json['PropertyId'] as int?;
    final revieweeId = json['revieweeId'] as int? ?? json['RevieweeId'] as int? ?? 0;
    final reviewerId = json['reviewerId'] as int? ?? json['ReviewerId'] as int? ?? 0;
    final reviewerFirstName = json['reviewerFirstName'] as String? ?? json['ReviewerFirstName'] as String?;
    final reviewerLastName = json['reviewerLastName'] as String? ?? json['ReviewerLastName'] as String?;
    final description = json['description'] as String? ?? json['Description'] as String?;
    final bookingId = json['bookingId'] as int? ?? json['BookingId'] as int?;
    final parentReviewId = json['parentReviewId'] as int? ?? json['ParentReviewId'] as int?;
    final isVerified = json['isVerified'] as bool? ?? json['IsVerified'] as bool?;
    final isResponse = json['isResponse'] as bool? ?? json['IsResponse'] as bool?;
    final moderatorNotes = json['moderatorNotes'] as String? ?? json['ModeratorNotes'] as String?;
    
    // Handle star rating from both formats
    final starRating = json['starRating'] != null 
        ? (json['starRating'] as num?)?.toDouble() 
        : (json['StarRating'] as num?)?.toDouble();
    
    // Handle date fields from both formats
    DateTime? dateCreated;
    DateTime? lastModified;
    
    if (json['dateCreated'] != null) {
      dateCreated = DateTime.parse(json['dateCreated'] as String);
    } else if (json['CreatedAt'] != null) {
      dateCreated = DateTime.parse(json['CreatedAt'] as String);
    } else {
      dateCreated = DateTime.now();
    }
    
    if (json['lastModified'] != null) {
      lastModified = DateTime.parse(json['lastModified'] as String);
    } else if (json['UpdatedAt'] != null) {
      lastModified = DateTime.parse(json['UpdatedAt'] as String);
    }
    
    // Handle review type from both formats (string or numeric)
    ReviewType reviewType;
    dynamic rtClient = json['reviewType'];
    dynamic rtDto = json['ReviewType'];
    if (rtClient != null) {
      if (rtClient is String) {
        reviewType = ReviewType.values.firstWhere(
          (e) => e.name.toLowerCase() == rtClient.toLowerCase(),
          orElse: () => ReviewType.propertyReview,
        );
      } else if (rtClient is int) {
        // Backend numeric mapping (Domain enum):
        // 0 = PropertyReview, 1 = TenantReview, 2 = ResponseReview
        switch (rtClient) {
          case 0:
            reviewType = ReviewType.propertyReview;
            break;
          case 1:
            reviewType = ReviewType.tenantReview;
            break;
          case 2:
            reviewType = ReviewType.responseReview;
            break;
          default:
            reviewType = ReviewType.propertyReview;
        }
      } else {
        reviewType = ReviewType.propertyReview;
      }
    } else if (rtDto != null) {
      if (rtDto is String) {
        final reviewTypeStr = rtDto.toLowerCase();
        reviewType = ReviewType.values.firstWhere(
          (e) => e.name.toLowerCase() == reviewTypeStr,
          orElse: () => ReviewType.propertyReview,
        );
      } else if (rtDto is int) {
        switch (rtDto) {
          case 0:
            reviewType = ReviewType.propertyReview;
            break;
          case 1:
            reviewType = ReviewType.tenantReview;
            break;
          case 2:
            reviewType = ReviewType.responseReview;
            break;
          default:
            reviewType = ReviewType.propertyReview;
        }
      } else {
        reviewType = ReviewType.propertyReview;
      }
    } else {
      reviewType = ReviewType.propertyReview;
    }
    
    return Review(
      reviewId: reviewId,
      reviewType: reviewType,
      propertyId: propertyId,
      revieweeId: revieweeId,
      reviewerId: reviewerId,
      reviewerFirstName: reviewerFirstName,
      reviewerLastName: reviewerLastName,
      description: description,
      dateCreated: dateCreated,
      starRating: starRating,
      bookingId: bookingId,
      parentReviewId: parentReviewId,
      isVerified: isVerified,
      isResponse: isResponse,
      lastModified: lastModified,
      moderatorNotes: moderatorNotes,
    );
  }

  /// Helper to get the reviewer's full name (or fallback)
  String get reviewerName {
    if (reviewerFirstName != null || reviewerLastName != null) {
      return '${reviewerFirstName ?? ''} ${reviewerLastName ?? ''}'.trim();
    }
    return 'Anonymous';
  }

  Map<String, dynamic> toJson() {
    return {
      'reviewId': reviewId,
      'reviewType': reviewType.name,
      'propertyId': propertyId,
      'revieweeId': revieweeId,
      'reviewerId': reviewerId,
      'reviewerFirstName': reviewerFirstName,
      'reviewerLastName': reviewerLastName,
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
  
  /// Convert to DTO format for API requests that expect backend DTO structure
  Map<String, dynamic> toDtoJson() {
    return {
      'ReviewId': reviewId,
      'ReviewType': reviewType.name,
      'PropertyId': propertyId,
      'RevieweeId': revieweeId,
      'ReviewerId': reviewerId,
      'Description': description,
      'StarRating': starRating,
      'BookingId': bookingId,
      'ParentReviewId': parentReviewId,
      'CreatedAt': dateCreated.toIso8601String(),
      'UpdatedAt': lastModified?.toIso8601String() ?? DateTime.now().toIso8601String(),
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
    String? reviewerFirstName,
    String? reviewerLastName,
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
      reviewerFirstName: reviewerFirstName ?? this.reviewerFirstName,
      reviewerLastName: reviewerLastName ?? this.reviewerLastName,
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
