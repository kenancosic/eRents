class Review {
  final int id;
  final ReviewType reviewType;
  final int? propertyId;
  final int? revieweeId; // For tenant reviews - the user being reviewed
  final int? reviewerId; // The user who wrote the review
  final int? bookingId; // Optional for replies
  final double? starRating; // Optional for replies
  final String description; // Required
  final DateTime dateCreated;
  final int? parentReviewId; // For threaded conversations
  final List<int> imageIds; // Use ImageController to fetch images
  final List<Review> replies; // Child replies
  final int replyCount; // Total number of replies

  // Fields from other entities - use "EntityName + FieldName" pattern
  final String? userFirstNameReviewer; // Reviewer's first name
  final String? userLastNameReviewer; // Reviewer's last name
  final String?
  userFirstNameReviewee; // Reviewee's first name (for tenant reviews)
  final String?
  userLastNameReviewee; // Reviewee's last name (for tenant reviews)
  final String? propertyName; // Property name

  Review({
    required this.id,
    required this.reviewType,
    this.propertyId,
    this.revieweeId,
    this.reviewerId,
    this.bookingId,
    this.starRating,
    required this.description,
    required this.dateCreated,
    this.parentReviewId,
    this.imageIds = const [],
    this.replies = const [],
    this.replyCount = 0,
    this.userFirstNameReviewer,
    this.userLastNameReviewer,
    this.userFirstNameReviewee,
    this.userLastNameReviewee,
    this.propertyName,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    try {
      return Review(
        id: json['reviewId'] as int? ?? json['id'] as int? ?? 0,
        reviewType: _parseReviewType(json['reviewType']),
        propertyId: json['propertyId'] as int?,
        revieweeId: json['revieweeId'] as int?,
        reviewerId: json['reviewerId'] as int?,
        bookingId: json['bookingId'] as int?,
        starRating: (json['starRating'] as num?)?.toDouble(),
        description: json['description'] as String? ?? '',
        dateCreated:
            json['dateCreated'] != null
                ? DateTime.tryParse(json['dateCreated'].toString()) ??
                    DateTime.now()
                : DateTime.now(),
        parentReviewId: json['parentReviewId'] as int?,
        imageIds: _parseImageIds(json['imageIds']),
        replies:
            (json['replies'] as List<dynamic>?)
                ?.map(
                  (replyJson) =>
                      Review.fromJson(replyJson as Map<String, dynamic>),
                )
                .toList() ??
            [],
        replyCount: json['replyCount'] as int? ?? 0,
        // Fields from other entities - use "EntityName + FieldName" pattern
        userFirstNameReviewer: json['userFirstNameReviewer'] as String?,
        userLastNameReviewer: json['userLastNameReviewer'] as String?,
        userFirstNameReviewee: json['userFirstNameReviewee'] as String?,
        userLastNameReviewee: json['userLastNameReviewee'] as String?,
        propertyName: json['propertyName'] as String?,
      );
    } catch (e) {
      print('Error parsing Review from JSON: $e');
      // Return a default review if parsing fails
      return Review(
        id: 0,
        reviewType: ReviewType.propertyReview,
        reviewerId: null,
        description: 'Error loading review',
        dateCreated: DateTime.now(),
      );
    }
  }

  static ReviewType _parseReviewType(dynamic reviewType) {
    if (reviewType == null) return ReviewType.propertyReview;

    String typeStr = reviewType.toString().toLowerCase();
    switch (typeStr) {
      case 'tenantreview':
        return ReviewType.tenantReview;
      case 'propertyreview':
      default:
        return ReviewType.propertyReview;
    }
  }

  static List<int> _parseImageIds(dynamic imageIdsValue) {
    if (imageIdsValue == null) return [];

    try {
      if (imageIdsValue is List) {
        return imageIdsValue
            .map((e) {
              if (e is int) return e;
              if (e is String) return int.tryParse(e) ?? 0;
              if (e is Map<String, dynamic> && e['id'] != null) {
                return e['id'] as int;
              }
              return 0;
            })
            .where((id) => id > 0)
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'reviewId': id,
      'reviewType': reviewType.toString().split('.').last,
      'propertyId': propertyId,
      'revieweeId': revieweeId,
      'reviewerId': reviewerId,
      'bookingId': bookingId,
      'starRating': starRating,
      'description': description,
      'dateCreated': dateCreated.toIso8601String(),
      'parentReviewId': parentReviewId,
      'imageIds': imageIds,
      'replies': replies.map((reply) => reply.toJson()).toList(),
      'replyCount': replyCount,
    };
  }

  // Computed properties for UI convenience (for backward compatibility)
  String? get reviewerName =>
      !((userFirstNameReviewer?.isEmpty ?? true) &&
              (userLastNameReviewer?.isEmpty ?? true))
          ? '${userFirstNameReviewer ?? ''} ${userLastNameReviewer ?? ''}'
              .trim()
          : null;

  String? get revieweeName =>
      !((userFirstNameReviewee?.isEmpty ?? true) &&
              (userLastNameReviewee?.isEmpty ?? true))
          ? '${userFirstNameReviewee ?? ''} ${userLastNameReviewee ?? ''}'
              .trim()
          : null;

  // Helper methods
  bool get isPropertyReview => reviewType == ReviewType.propertyReview;
  bool get isTenantReview => reviewType == ReviewType.tenantReview;
  bool get isReply => parentReviewId != null;
  bool get isOriginalReview => parentReviewId == null;
  bool get hasReplies => replies.isNotEmpty;
  bool get hasRating => starRating != null;
}

enum ReviewType { propertyReview, tenantReview }
