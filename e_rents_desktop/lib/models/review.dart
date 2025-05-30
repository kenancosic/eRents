class Review {
  final int id;
  final ReviewType reviewType;
  final int? propertyId;
  final int? revieweeId; // For tenant reviews - the user being reviewed
  final int? reviewerId; // The user who wrote the review
  final String? reviewerName; // For display purposes
  final String? revieweeName; // For tenant reviews display
  final String? propertyName; // For display purposes
  final int? bookingId; // Optional for replies
  final double? starRating; // Optional for replies
  final String description; // Required
  final DateTime dateCreated;
  final int? parentReviewId; // For threaded conversations
  final List<Review> replies; // Child replies
  final int replyCount; // Total number of replies

  Review({
    required this.id,
    required this.reviewType,
    this.propertyId,
    this.revieweeId,
    this.reviewerId,
    this.reviewerName,
    this.revieweeName,
    this.propertyName,
    this.bookingId,
    this.starRating,
    required this.description,
    required this.dateCreated,
    this.parentReviewId,
    this.replies = const [],
    this.replyCount = 0,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    try {
      return Review(
        id: json['reviewId'] as int? ?? json['id'] as int? ?? 0,
        reviewType: _parseReviewType(json['reviewType']),
        propertyId: json['propertyId'] as int?,
        revieweeId: json['revieweeId'] as int?,
        reviewerId: json['reviewerId'] as int?,
        reviewerName: json['reviewerName'] as String?,
        revieweeName: json['revieweeName'] as String?,
        propertyName: json['propertyName'] as String?,
        bookingId: json['bookingId'] as int?,
        starRating: (json['starRating'] as num?)?.toDouble(),
        description: json['description'] as String? ?? '',
        dateCreated:
            json['dateCreated'] != null
                ? DateTime.tryParse(json['dateCreated'].toString()) ??
                    DateTime.now()
                : DateTime.now(),
        parentReviewId: json['parentReviewId'] as int?,
        replies:
            (json['replies'] as List<dynamic>?)
                ?.map(
                  (replyJson) =>
                      Review.fromJson(replyJson as Map<String, dynamic>),
                )
                .toList() ??
            [],
        replyCount: json['replyCount'] as int? ?? 0,
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
      'replies': replies.map((reply) => reply.toJson()).toList(),
      'replyCount': replyCount,
    };
  }

  // Helper methods
  bool get isPropertyReview => reviewType == ReviewType.propertyReview;
  bool get isTenantReview => reviewType == ReviewType.tenantReview;
  bool get isReply => parentReviewId != null;
  bool get isOriginalReview => parentReviewId == null;
  bool get hasReplies => replies.isNotEmpty;
  bool get hasRating => starRating != null;
}

enum ReviewType { propertyReview, tenantReview }
