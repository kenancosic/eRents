class Review {
  final int reviewId;
  final int? tenantId;
  final int? propertyId;
  final String? description;
  final String? severity;
  final DateTime? dateReported;
  final String? status;
  final bool isComplaint;
  final double? starRating;
  final bool isFlagged;

  Review({
    required this.reviewId,
    this.tenantId,
    this.propertyId,
    this.description,
    this.severity,
    this.dateReported,
    this.status,
    required this.isComplaint,
    this.starRating,
    required this.isFlagged,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      reviewId: json['reviewId'],
      tenantId: json['tenantId'],
      propertyId: json['propertyId'],
      description: json['description'],
      severity: json['severity'],
      dateReported: json['dateReported'] != null ? DateTime.parse(json['dateReported']) : null,
      status: json['status'],
      isComplaint: json['isComplaint'],
      starRating: json['starRating']?.toDouble(),
      isFlagged: json['isFlagged'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reviewId': reviewId,
      'tenantId': tenantId,
      'propertyId': propertyId,
      'description': description,
      'severity': severity,
      'dateReported': dateReported?.toIso8601String(),
      'status': status,
      'isComplaint': isComplaint,
      'starRating': starRating,
      'isFlagged': isFlagged,
    };
  }
}
