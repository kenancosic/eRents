class ReviewNotificationMessage {
  final int propertyId;
  final int reviewId;
  final String? message;

  ReviewNotificationMessage({required this.propertyId, required this.reviewId, this.message});

  factory ReviewNotificationMessage.fromJson(Map<String, dynamic> json) {
    return ReviewNotificationMessage(
      propertyId: json['propertyId'],
      reviewId: json['reviewId'],
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'propertyId': propertyId,
      'reviewId': reviewId,
      'message': message,
    };
  }
}
