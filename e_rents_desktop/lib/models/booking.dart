/// Booking status enumeration
enum BookingStatus {
  upcoming,
  active,
  completed,
  cancelled;

  static BookingStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return BookingStatus.upcoming;
      case 'active':
        return BookingStatus.active;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      default:
        throw ArgumentError('Unknown booking status: $status');
    }
  }

  String get displayName {
    switch (this) {
      case BookingStatus.upcoming:
        return 'Upcoming';
      case BookingStatus.active:
        return 'Active';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get statusName => name.toLowerCase();
}

/// Main booking model representing a property rental booking
class Booking {
  final int bookingId;
  final int? propertyId;
  final int? userId;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? minimumStayEndDate;
  final double totalPrice;
  final DateTime? bookingDate;
  final BookingStatus status;

  // Phase 2 fields - Payment Information
  final String paymentMethod;
  final String currency;
  final String? paymentStatus;
  final String? paymentReference;

  // Phase 2 fields - Booking Details
  final int numberOfGuests;
  final String? specialRequests;

  // Navigation properties (loaded from includes)
  final String? propertyName;
  final String? propertyAddress;
  final int?
  propertyImageId; // Property's main image ID - construct URL as needed
  final String? userName;
  final String? userEmail;
  final String? tenantName; // New DTO field
  final String? tenantEmail; // New DTO field

  // Base entity fields
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? modifiedBy;

  const Booking({
    required this.bookingId,
    this.propertyId,
    this.userId,
    required this.startDate,
    this.endDate,
    this.minimumStayEndDate,
    required this.totalPrice,
    this.bookingDate,
    required this.status,
    this.paymentMethod = 'PayPal',
    this.currency = 'BAM',
    this.paymentStatus,
    this.paymentReference,
    this.numberOfGuests = 1,
    this.specialRequests,
    this.propertyName,
    this.propertyAddress,
    this.propertyImageId,
    this.userName,
    this.userEmail,
    this.tenantName,
    this.tenantEmail,
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.modifiedBy,
  });

  /// Create a Booking from JSON response
  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      bookingId: json['bookingId'] ?? 0,
      propertyId: json['propertyId'],
      userId: json['userId'],
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      minimumStayEndDate:
          json['minimumStayEndDate'] != null
              ? DateTime.parse(json['minimumStayEndDate'])
              : null,
      totalPrice: (json['totalPrice'] ?? 0.0).toDouble(),
      bookingDate:
          json['bookingDate'] != null
              ? DateTime.parse(json['bookingDate'])
              : null,
      status: _parseStatus(json),
      paymentMethod: json['paymentMethod'] ?? 'PayPal',
      currency: json['currency'] ?? 'BAM',
      paymentStatus: json['paymentStatus'],
      paymentReference: json['paymentReference'],
      numberOfGuests: json['numberOfGuests'] ?? 1,
      specialRequests: json['specialRequests'],
      propertyName: json['propertyName'],
      propertyAddress: json['propertyAddress'],
      propertyImageId: json['propertyImageId'],
      // ✅ FIXED: Use exact Entity field names from BookingResponse
      userName: _buildFullName(json['userFirstName'], json['userLastName']),
      userEmail: json['userEmail'],
      tenantName: json['tenantName'],
      tenantEmail: json['tenantEmail'],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      createdBy: json['createdBy'],
      modifiedBy: json['modifiedBy'],
    );
  }

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'propertyId': propertyId,
      'userId': userId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'minimumStayEndDate': minimumStayEndDate?.toIso8601String(),
      'totalPrice': totalPrice,
      'bookingDate': bookingDate?.toIso8601String(),
      'status': status.statusName,
      'paymentMethod': paymentMethod,
      'currency': currency,
      'paymentStatus': paymentStatus,
      'paymentReference': paymentReference,
      'numberOfGuests': numberOfGuests,
      'specialRequests': specialRequests,
    };
  }

  /// Helper method to parse booking status from JSON
  static BookingStatus _parseStatus(Map<String, dynamic> json) {
    final statusString = json['status'] ?? 'upcoming';

    try {
      return BookingStatus.fromString(statusString);
    } catch (e) {
      return BookingStatus.upcoming; // Default fallback
    }
  }

  /// Helper method to build full name from first and last name
  static String? _buildFullName(String? firstName, String? lastName) {
    if (firstName == null && lastName == null) return null;
    return '${firstName ?? ''} ${lastName ?? ''}'.trim();
  }

  /// Copy with method for updates
  Booking copyWith({
    int? bookingId,
    int? propertyId,
    int? userId,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? minimumStayEndDate,
    double? totalPrice,
    DateTime? bookingDate,
    BookingStatus? status,
    String? paymentMethod,
    String? currency,
    String? paymentStatus,
    String? paymentReference,
    int? numberOfGuests,
    String? specialRequests,
    String? propertyName,
    String? propertyAddress,
    int? propertyImageId,
    String? userName,
    String? userEmail,
    String? tenantName,
    String? tenantEmail,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? modifiedBy,
  }) {
    return Booking(
      bookingId: bookingId ?? this.bookingId,
      propertyId: propertyId ?? this.propertyId,
      userId: userId ?? this.userId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      minimumStayEndDate: minimumStayEndDate ?? this.minimumStayEndDate,
      totalPrice: totalPrice ?? this.totalPrice,
      bookingDate: bookingDate ?? this.bookingDate,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      currency: currency ?? this.currency,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentReference: paymentReference ?? this.paymentReference,
      numberOfGuests: numberOfGuests ?? this.numberOfGuests,
      specialRequests: specialRequests ?? this.specialRequests,
      propertyName: propertyName ?? this.propertyName,
      propertyAddress: propertyAddress ?? this.propertyAddress,
      propertyImageId: propertyImageId ?? this.propertyImageId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      tenantName: tenantName ?? this.tenantName,
      tenantEmail: tenantEmail ?? this.tenantEmail,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      modifiedBy: modifiedBy ?? this.modifiedBy,
    );
  }

  /// Check if booking is currently active
  bool get isActive {
    final now = DateTime.now();
    return status == BookingStatus.active &&
        startDate.isBefore(now) &&
        (endDate == null || endDate!.isAfter(now));
  }

  /// Check if booking can be cancelled
  bool get canBeCancelled {
    return status == BookingStatus.upcoming || status == BookingStatus.active;
  }

  bool get isCompleted => status == BookingStatus.completed;
  bool get isCancelled => status == BookingStatus.cancelled;
  bool get isUpcoming => status == BookingStatus.upcoming;

  /// Get booking duration in days
  int? get durationInDays {
    if (endDate == null) return null;
    return endDate!.difference(startDate).inDays;
  }

  /// Get formatted date range
  String get dateRange {
    final start = startDate.toString().split(' ')[0];
    if (endDate == null) {
      return 'From $start (Open-ended)';
    }
    final end = endDate!.toString().split(' ')[0];
    return '$start - $end';
  }

  /// Get formatted price with currency
  String get formattedPrice {
    return '$totalPrice $currency';
  }

  /// Get formatted total price (alias for formattedPrice)
  String get formattedTotalPrice => formattedPrice;

  /// Get formatted start date
  String get formattedStartDate {
    return startDate.toString().split(' ')[0]; // YYYY-MM-DD format
  }

  /// Get formatted end date
  String get formattedEndDate {
    if (endDate == null) return 'Open-ended';
    return endDate!.toString().split(' ')[0]; // YYYY-MM-DD format
  }

  /// Get duration as a formatted string
  String? get duration {
    if (durationInDays == null) return null;
    final days = durationInDays!;
    if (days == 1) return '1 day';
    return '$days days';
  }

  @override
  String toString() {
    return 'Booking(id: $bookingId, property: $propertyId, status: $status, dates: $dateRange)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Booking &&
          runtimeType == other.runtimeType &&
          bookingId == other.bookingId;

  @override
  int get hashCode => bookingId.hashCode;
}

/// Booking insert request model for creating new bookings
class BookingInsertRequest {
  final int propertyId;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;
  final String? paymentMethod;
  final String? currency;
  final int numberOfGuests;
  final String? specialRequests;

  const BookingInsertRequest({
    required this.propertyId,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    this.paymentMethod = 'PayPal',
    this.currency = 'BAM',
    this.numberOfGuests = 1,
    this.specialRequests,
  });

  Map<String, dynamic> toJson() {
    return {
      'propertyId': propertyId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'totalPrice': totalPrice,
      'paymentMethod': paymentMethod,
      'currency': currency,
      'numberOfGuests': numberOfGuests,
      'specialRequests': specialRequests,
    };
  }
}

/// Booking update request model
class BookingUpdateRequest {
  final DateTime? startDate;
  final DateTime? endDate;
  final int? numberOfGuests;
  final String? specialRequests;

  const BookingUpdateRequest({
    this.startDate,
    this.endDate,
    this.numberOfGuests,
    this.specialRequests,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (startDate != null) json['startDate'] = startDate!.toIso8601String();
    if (endDate != null) json['endDate'] = endDate!.toIso8601String();
    if (numberOfGuests != null) json['numberOfGuests'] = numberOfGuests;
    if (specialRequests != null) json['specialRequests'] = specialRequests;
    return json;
  }
}

/// Booking cancellation request model
class BookingCancellationRequest {
  final int bookingId;
  final String? cancellationReason;
  final bool requestRefund;
  final String? refundMethod;

  const BookingCancellationRequest({
    required this.bookingId,
    this.cancellationReason,
    this.requestRefund = false,
    this.refundMethod,
  });

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'cancellationReason': cancellationReason,
      'requestRefund': requestRefund,
      'refundMethod': refundMethod,
    };
  }
}
