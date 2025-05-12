class TenantFeedback {
  final String id;
  final String tenantId;
  final String landlordId;
  final String propertyId;
  final int rating;
  final String comment;
  final DateTime feedbackDate;
  final DateTime stayStartDate;
  final DateTime stayEndDate;

  TenantFeedback({
    required this.id,
    required this.tenantId,
    required this.landlordId,
    required this.propertyId,
    required this.rating,
    required this.comment,
    required this.feedbackDate,
    required this.stayStartDate,
    required this.stayEndDate,
  });

  factory TenantFeedback.fromJson(Map<String, dynamic> json) {
    return TenantFeedback(
      id: json['id'] as String,
      tenantId: json['tenantId'] as String,
      landlordId: json['landlordId'] as String,
      propertyId: json['propertyId'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String,
      feedbackDate: DateTime.parse(json['feedbackDate'] as String),
      stayStartDate: DateTime.parse(json['stayStartDate'] as String),
      stayEndDate: DateTime.parse(json['stayEndDate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenantId': tenantId,
      'landlordId': landlordId,
      'propertyId': propertyId,
      'rating': rating,
      'comment': comment,
      'feedbackDate': feedbackDate.toIso8601String(),
      'stayStartDate': stayStartDate.toIso8601String(),
      'stayEndDate': stayEndDate.toIso8601String(),
    };
  }
}
