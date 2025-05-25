enum BookingStatus { upcoming, completed, cancelled, active }

class Booking {
  final int bookingId;
  final int propertyId;
  final int userId;
  final String propertyName;
  final String? propertyImageUrl;
  final String? propertyThumbnailUrl;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? minimumStayEndDate;
  final double totalPrice;
  final double dailyRate;
  final BookingStatus status;
  final String? currency;
  final DateTime? bookingDate;
  final String? reviewContent;
  final int? reviewRating;

  Booking({
    required this.bookingId,
    required this.propertyId,
    required this.userId,
    required this.propertyName,
    this.propertyImageUrl,
    this.propertyThumbnailUrl,
    required this.startDate,
    this.endDate,
    this.minimumStayEndDate,
    required this.totalPrice,
    required this.dailyRate,
    required this.status,
    this.currency,
    this.bookingDate,
    this.reviewContent,
    this.reviewRating,
  });

  String get statusDisplay {
    switch (status) {
      case BookingStatus.upcoming:
        return 'Upcoming';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.active:
        return 'Active';
    }
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    String statusString = json['bookingStatus']?['statusName'] ??
        json['status'] ?? // Direct status string fallback
        'Upcoming'; // Default status

    BookingStatus statusEnum = BookingStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == statusString.toLowerCase(),
      orElse: () => BookingStatus.upcoming, // Default if parsing fails
    );

    return Booking(
      bookingId: json['bookingId'] as int,
      propertyId: json['propertyId'] as int,
      userId: json['userId'] as int,
      propertyName: json['propertyName'] as String? ?? 'N/A',
      propertyImageUrl: json['propertyImageUrl'] as String?,
      propertyThumbnailUrl: json['propertyThumbnailUrl'] ??
          json['propertyImageUrl']
              as String?, // Use thumbnail if available, else fallback to imageURL
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      minimumStayEndDate: json['minimumStayEndDate'] != null
          ? DateTime.parse(json['minimumStayEndDate'] as String)
          : null,
      totalPrice: (json['totalPrice'] as num).toDouble(),
      dailyRate: (json['dailyRate'] as num).toDouble(),
      status: statusEnum,
      currency: json['currency'] as String?,
      bookingDate: json['bookingDate'] != null
          ? DateTime.parse(json['bookingDate'] as String)
          : null,
      reviewContent: json['reviewContent'] as String?,
      reviewRating: json['reviewRating'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'bookingId': bookingId,
        'propertyId': propertyId,
        'userId': userId,
        'propertyName': propertyName,
        'propertyImageUrl': propertyImageUrl,
        'propertyThumbnailUrl': propertyThumbnailUrl,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'minimumStayEndDate': minimumStayEndDate?.toIso8601String(),
        'totalPrice': totalPrice,
        'dailyRate': dailyRate,
        'status': status.name, // Send status name
        'currency': currency,
        'bookingDate': bookingDate?.toIso8601String(),
        'reviewContent': reviewContent,
        'reviewRating': reviewRating,
      };

  bool isActive() {
    if (endDate == null) return true;
    DateTime now = DateTime.now();
    return startDate.isBefore(now) && endDate!.isAfter(now);
  }
}
