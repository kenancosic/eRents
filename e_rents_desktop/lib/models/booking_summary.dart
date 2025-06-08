class BookingSummary {
  final int bookingId;
  final int propertyId;
  final String propertyName;
  final int? propertyImageId;
  final List<int>?
  propertyImageData; // Changed from byte[] to List<int> for Dart
  final DateTime startDate;
  final DateTime? endDate;
  final double totalPrice;
  final String currency;
  final String bookingStatus;
  final String? tenantName;
  final String? tenantEmail;

  // New Payment Information fields (matching backend)
  final String paymentMethod;
  final String? paymentStatus; // "Pending", "Completed", "Failed"
  final String? paymentReference; // PayPal Transaction ID

  // New Booking Info fields (matching backend)
  final int numberOfGuests;
  final String? specialRequests;

  BookingSummary({
    required this.bookingId,
    required this.propertyId,
    required this.propertyName,
    this.propertyImageId,
    this.propertyImageData,
    required this.startDate,
    this.endDate,
    required this.totalPrice,
    this.currency = 'BAM',
    required this.bookingStatus,
    this.tenantName,
    this.tenantEmail,
    this.paymentMethod = 'PayPal',
    this.paymentStatus,
    this.paymentReference,
    this.numberOfGuests = 1,
    this.specialRequests,
  });

  factory BookingSummary.fromJson(Map<String, dynamic> json) {
    return BookingSummary(
      bookingId: json['bookingId'] as int? ?? 0,
      propertyId: json['propertyId'] as int? ?? 0,
      propertyName: json['propertyName'] as String? ?? '',
      propertyImageId: json['propertyImageId'] as int?,
      propertyImageData:
          json['propertyImageData'] != null
              ? List<int>.from(json['propertyImageData'])
              : null,
      startDate:
          json['startDate'] != null
              ? DateTime.parse(json['startDate'].toString())
              : DateTime.now(),
      endDate:
          json['endDate'] != null
              ? DateTime.parse(json['endDate'].toString())
              : null,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'BAM',
      bookingStatus:
          json['bookingStatus'] as String? ?? json['status'] as String? ?? '',
      tenantName: json['tenantName'] as String?,
      tenantEmail: json['tenantEmail'] as String?,
      // New fields with safe parsing
      paymentMethod: json['paymentMethod'] as String? ?? 'PayPal',
      paymentStatus: json['paymentStatus'] as String?,
      paymentReference: json['paymentReference'] as String?,
      numberOfGuests: json['numberOfGuests'] as int? ?? 1,
      specialRequests: json['specialRequests'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'propertyId': propertyId,
      'propertyName': propertyName,
      'propertyImageId': propertyImageId,
      'propertyImageData': propertyImageData,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'totalPrice': totalPrice,
      'currency': currency,
      'bookingStatus': bookingStatus,
      'status':
          bookingStatus, // Also include as 'status' for backend compatibility
      'tenantName': tenantName,
      'tenantEmail': tenantEmail,
      // New fields
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'paymentReference': paymentReference,
      'numberOfGuests': numberOfGuests,
      'specialRequests': specialRequests,
    };
  }

  // Helper methods for payment status
  bool get isPaymentCompleted => paymentStatus?.toLowerCase() == 'completed';
  bool get isPaymentPending => paymentStatus?.toLowerCase() == 'pending';
  bool get isPaymentFailed => paymentStatus?.toLowerCase() == 'failed';

  // Helper methods for booking management
  String get guestCountDisplay =>
      numberOfGuests == 1 ? '1 Guest' : '$numberOfGuests Guests';
  bool get hasSpecialRequests => specialRequests?.isNotEmpty == true;

  /// Create BookingSummary from Booking model
  factory BookingSummary.fromBooking(dynamic booking) {
    return BookingSummary(
      bookingId: booking.bookingId ?? 0,
      propertyId: booking.propertyId ?? 0,
      propertyName: booking.property?.name ?? '',
      propertyImageId:
          booking.property?.images?.isNotEmpty == true
              ? booking.property!.images!.first.imageId
              : null,
      propertyImageData:
          booking.property?.images?.isNotEmpty == true
              ? booking.property!.images!.first.imageData
              : null,
      startDate: booking.startDate ?? DateTime.now(),
      endDate: booking.endDate,
      totalPrice: booking.totalPrice ?? 0.0,
      currency: booking.currency ?? 'BAM',
      bookingStatus: booking.bookingStatus?.statusName ?? booking.status ?? '',
      tenantName:
          booking.user != null
              ? '${booking.user.firstName ?? ''} ${booking.user.lastName ?? ''}'
                  .trim()
              : null,
      tenantEmail: booking.user?.email,
      paymentMethod: booking.paymentMethod ?? 'PayPal',
      paymentStatus: booking.paymentStatus,
      paymentReference: booking.paymentReference,
      numberOfGuests: booking.numberOfGuests ?? 1,
      specialRequests: booking.specialRequests,
    );
  }
}

// Stats classes for property details
class PropertyBookingStats {
  final int totalBookings;
  final double totalRevenue;
  final double averageBookingValue;
  final int currentOccupancy;
  final double occupancyRate;

  PropertyBookingStats({
    required this.totalBookings,
    required this.totalRevenue,
    required this.averageBookingValue,
    required this.currentOccupancy,
    required this.occupancyRate,
  });

  factory PropertyBookingStats.fromJson(Map<String, dynamic> json) {
    return PropertyBookingStats(
      totalBookings: json['totalBookings'] as int? ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      averageBookingValue:
          (json['averageBookingValue'] as num?)?.toDouble() ?? 0.0,
      currentOccupancy: json['currentOccupancy'] as int? ?? 0,
      occupancyRate: (json['occupancyRate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PropertyReviewStats {
  final double averageRating;
  final int totalReviews;
  final Map<String, int> ratingDistribution;
  final List<Map<String, dynamic>>
  recentReviews; // Keep as Map for now since Review import causes circular dependency

  PropertyReviewStats({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
    required this.recentReviews,
  });

  factory PropertyReviewStats.fromJson(Map<String, dynamic> json) {
    try {
      // Safely parse averageRating
      double avgRating = 0.0;
      final ratingValue = json['averageRating'];
      if (ratingValue is num) {
        avgRating = ratingValue.toDouble();
      } else if (ratingValue is String) {
        avgRating = double.tryParse(ratingValue) ?? 0.0;
      }

      // Safely parse totalReviews
      int totalReviewsCount = 0;
      final reviewsValue = json['totalReviews'];
      if (reviewsValue is int) {
        totalReviewsCount = reviewsValue;
      } else if (reviewsValue is String) {
        totalReviewsCount = int.tryParse(reviewsValue) ?? 0;
      }

      // Safely parse ratingDistribution - convert to Map<String, int>
      Map<String, int> distribution = {};
      try {
        final distributionData = json['ratingDistribution'];
        if (distributionData is Map) {
          distributionData.forEach((key, value) {
            final stringKey = key.toString();
            final intValue =
                value is int ? value : (int.tryParse(value.toString()) ?? 0);
            distribution[stringKey] = intValue;
          });
        }
      } catch (e) {
        print('Error parsing rating distribution: $e');
      }

      // Safely parse recentReviews as List<Map<String, dynamic>>
      List<Map<String, dynamic>> reviews = [];
      try {
        final reviewsData = json['recentReviews'];
        if (reviewsData is List) {
          reviews =
              reviewsData.map((reviewJson) {
                if (reviewJson is Map<String, dynamic>) {
                  return reviewJson;
                } else {
                  return <String, dynamic>{};
                }
              }).toList();
        }
      } catch (e) {
        print('Error parsing recent reviews: $e');
      }

      return PropertyReviewStats(
        averageRating: avgRating,
        totalReviews: totalReviewsCount,
        ratingDistribution: distribution,
        recentReviews: reviews,
      );
    } catch (e) {
      print('Error parsing PropertyReviewStats: $e');
      return PropertyReviewStats(
        averageRating: 0.0,
        totalReviews: 0,
        ratingDistribution: {},
        recentReviews: [],
      );
    }
  }
}
