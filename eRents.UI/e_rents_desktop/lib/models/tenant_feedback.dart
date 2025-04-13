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
      id: json['id'],
      tenantId: json['tenantId'],
      landlordId: json['landlordId'],
      propertyId: json['propertyId'],
      rating: json['rating'],
      comment: json['comment'],
      feedbackDate: DateTime.parse(json['feedbackDate']),
      stayStartDate: DateTime.parse(json['stayStartDate']),
      stayEndDate: DateTime.parse(json['stayEndDate']),
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
