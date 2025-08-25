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

  // New Phase 2 fields - Payment tracking
  final String paymentMethod;
  final String? paymentStatus; // "Pending", "Completed", "Failed"
  final String? paymentReference; // PayPal Transaction ID

  // New Phase 2 fields - Booking details
  final int numberOfGuests;
  final String? specialRequests;

  // ✅ NEW CRITICAL FIELD for backend alignment
  final int? bookingStatusId; // Backend expects bookingStatusId for filtering

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
    // New fields with defaults
    this.paymentMethod = 'PayPal',
    this.paymentStatus,
    this.paymentReference,
    this.numberOfGuests = 1,
    this.specialRequests,
    // Backend alignment
    this.bookingStatusId,
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

  // Helper methods for payment status
  bool get isPaymentCompleted => paymentStatus?.toLowerCase() == 'completed';
  bool get isPaymentPending => paymentStatus?.toLowerCase() == 'pending';
  bool get isPaymentFailed => paymentStatus?.toLowerCase() == 'failed';

  // Helper methods for booking details
  String get guestCountDisplay =>
      numberOfGuests == 1 ? '1 Guest' : '$numberOfGuests Guests';
  bool get hasSpecialRequests => specialRequests?.isNotEmpty == true;

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
      // New fields with safe parsing
      paymentMethod: json['paymentMethod'] as String? ?? 'PayPal',
      paymentStatus: json['paymentStatus'] as String?,
      paymentReference: json['paymentReference'] as String?,
      numberOfGuests: json['numberOfGuests'] as int? ?? 1,
      specialRequests: json['specialRequests'] as String?,
      // Backend alignment
      bookingStatusId: json['bookingStatusId'] as int?,
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
        // New fields
        'paymentMethod': paymentMethod,
        'paymentStatus': paymentStatus,
        'paymentReference': paymentReference,
        'numberOfGuests': numberOfGuests,
        'specialRequests': specialRequests,
        // Backend alignment
        'bookingStatusId': bookingStatusId,
      };

  bool isActive() {
    if (endDate == null) return true;
    DateTime now = DateTime.now();
    return startDate.isBefore(now) && endDate!.isAfter(now);
  }

  Booking copyWith({
    int? bookingId,
    int? propertyId,
    int? userId,
    String? propertyName,
    String? propertyImageUrl,
    String? propertyThumbnailUrl,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? minimumStayEndDate,
    double? totalPrice,
    double? dailyRate,
    BookingStatus? status,
    String? currency,
    DateTime? bookingDate,
    String? reviewContent,
    int? reviewRating,
    String? paymentMethod,
    String? paymentStatus,
    String? paymentReference,
    int? numberOfGuests,
    String? specialRequests,
    int? bookingStatusId,
  }) {
    return Booking(
      bookingId: bookingId ?? this.bookingId,
      propertyId: propertyId ?? this.propertyId,
      userId: userId ?? this.userId,
      propertyName: propertyName ?? this.propertyName,
      propertyImageUrl: propertyImageUrl ?? this.propertyImageUrl,
      propertyThumbnailUrl: propertyThumbnailUrl ?? this.propertyThumbnailUrl,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      minimumStayEndDate: minimumStayEndDate ?? this.minimumStayEndDate,
      totalPrice: totalPrice ?? this.totalPrice,
      dailyRate: dailyRate ?? this.dailyRate,
      status: status ?? this.status,
      currency: currency ?? this.currency,
      bookingDate: bookingDate ?? this.bookingDate,
      reviewContent: reviewContent ?? this.reviewContent,
      reviewRating: reviewRating ?? this.reviewRating,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentReference: paymentReference ?? this.paymentReference,
      numberOfGuests: numberOfGuests ?? this.numberOfGuests,
      specialRequests: specialRequests ?? this.specialRequests,
      bookingStatusId: bookingStatusId ?? this.bookingStatusId,
    );
  }
}
