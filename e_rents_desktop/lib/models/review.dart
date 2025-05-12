class Review {
  final String id;
  final String bookingId;
  final String propertyId;
  final double starRating;
  final String description;
  final DateTime dateReported;
  final ReviewStatus status;
  final ReviewSeverity severity;

  Review({
    required this.id,
    required this.bookingId,
    required this.propertyId,
    required this.starRating,
    required this.description,
    required this.dateReported,
    required this.status,
    required this.severity,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      bookingId: json['bookingId'] as String,
      propertyId: json['propertyId'] as String,
      starRating: (json['starRating'] as num).toDouble(),
      description: json['description'] as String,
      dateReported: DateTime.parse(json['dateReported'] as String),
      status: ReviewStatus.values.firstWhere(
        (e) => e.toString() == 'ReviewStatus.${json['status']}',
        orElse: () => ReviewStatus.pending,
      ),
      severity: ReviewSeverity.values.firstWhere(
        (e) => e.toString() == 'ReviewSeverity.${json['severity']}',
        orElse: () => ReviewSeverity.medium,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'propertyId': propertyId,
      'starRating': starRating,
      'description': description,
      'dateReported': dateReported.toIso8601String(),
      'status': status.toString().split('.').last,
      'severity': severity.toString().split('.').last,
    };
  }
}

enum ReviewStatus { pending, approved, rejected, flagged }

enum ReviewSeverity { low, medium, high, critical }
