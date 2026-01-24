import 'package:e_rents_mobile/core/enums/booking_enums.dart';
import 'package:flutter/foundation.dart';

class Booking {
  final int bookingId;
  final int propertyId;
  final int userId;
  final String propertyName;
  final String? userName;
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
  final String? paymentReference; // Payment Transaction ID

  // Backend alignment
  final int? bookingStatusId; // Backend expects bookingStatusId for filtering

  /// Indicates if this booking is a subscription-based monthly rental.
  /// Only subscription bookings can request lease extensions.
  final bool isSubscription;

  Booking({
    required this.bookingId,
    required this.propertyId,
    required this.userId,
    required this.propertyName,
    this.userName,
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
    this.paymentMethod = 'Manual',
    this.paymentStatus,
    this.paymentReference,
    // Backend alignment
    this.bookingStatusId,
    this.isSubscription = false,
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
      case BookingStatus.pending:
        return 'Pending Approval';
    }
  }

  // Helper methods for payment status
  bool get isPaymentCompleted => paymentStatus?.toLowerCase() == 'completed';
  bool get isPaymentPending => paymentStatus?.toLowerCase() == 'pending';
  bool get isPaymentFailed => paymentStatus?.toLowerCase() == 'failed';

  /// Build image URL from propertyCoverImageId or fallback to existing fields
  static String? _buildImageUrl(Map<String, dynamic> json) {
    // First try to use propertyCoverImageId from backend
    final coverImageId = json['propertyCoverImageId'];
    if (coverImageId != null) {
      // Construct the image URL - will be made absolute by the widget
      return '/api/Images/$coverImageId/content';
    }
    // Fallback to existing fields
    return (json['propertyThumbnailUrl'] ?? json['propertyImageUrl'])?.toString();
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    // Handle status parsing for multiple backend shapes: object, string, or int code
    BookingStatus parseStatus(dynamic raw) {
      if (raw == null) return BookingStatus.upcoming;
      // Object with statusName
      if (raw is Map<String, dynamic>) {
        final name = raw['statusName']?.toString();
        if (name != null) {
          return BookingStatus.values.firstWhere(
            (e) => e.name.toLowerCase() == name.toLowerCase(),
            orElse: () => BookingStatus.upcoming,
          );
        }
      }
      // Direct string
      if (raw is String) {
        final s = raw.toLowerCase();
        switch (s) {
          case 'upcoming':
            return BookingStatus.upcoming;
          case 'active':
            return BookingStatus.active;
          case 'cancelled':
          case 'canceled':
            return BookingStatus.cancelled;
          case 'completed':
          case 'done':
            return BookingStatus.completed;
          case 'pending':
            return BookingStatus.pending;
          default:
            return BookingStatus.upcoming;
        }
      }
      // Numeric code from backend enum
      if (raw is int) {
        // Backend enum: 1=Upcoming, 2=Completed, 3=Cancelled, 4=Active, 5=Pending, 6=Approved
        switch (raw) {
          case 1:
            return BookingStatus.upcoming;
          case 2:
            return BookingStatus.completed;
          case 3:
            return BookingStatus.cancelled;
          case 4:
            return BookingStatus.active;
          case 5:
            return BookingStatus.pending;
          case 6:
            return BookingStatus.upcoming; // Approved maps to upcoming
          default:
            return BookingStatus.upcoming;
        }
      }
      // Fallback
      final s = raw.toString();
      return BookingStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == s.toLowerCase(),
        orElse: () => BookingStatus.upcoming,
      );
    }

    final dynamic rawStatus = json['bookingStatus']?['statusName'] ?? json['status'];
    final BookingStatus statusEnum = parseStatus(rawStatus);

    // Handle ID parsing with type conversion
    int bookingId = 0;
    if (json['bookingId'] != null) {
      bookingId = json['bookingId'] is int 
          ? json['bookingId'] 
          : int.tryParse(json['bookingId'].toString()) ?? 0;
    }
    
    int propertyId = 0;
    if (json['propertyId'] != null) {
      propertyId = json['propertyId'] is int 
          ? json['propertyId'] 
          : int.tryParse(json['propertyId'].toString()) ?? 0;
    }
    
    int userId = 0;
    if (json['userId'] != null) {
      userId = json['userId'] is int 
          ? json['userId'] 
          : int.tryParse(json['userId'].toString()) ?? 0;
    }
    
    // Handle numeric parsing with type conversion
    double totalPrice = 0.0;
    if (json['totalPrice'] != null) {
      if (json['totalPrice'] is num) {
        totalPrice = json['totalPrice'].toDouble();
      } else {
        totalPrice = double.tryParse(json['totalPrice'].toString()) ?? 0.0;
      }
    }
    
    double dailyRate = 0.0;
    if (json['dailyRate'] != null) {
      if (json['dailyRate'] is num) {
        dailyRate = json['dailyRate'].toDouble();
      } else {
        dailyRate = double.tryParse(json['dailyRate'].toString()) ?? 0.0;
      }
    }
    
    // Handle date parsing with better error handling
    DateTime? startDate;
    try {
      if (json['startDate'] != null) {
        startDate = DateTime.parse(json['startDate'] is String 
            ? json['startDate'] 
            : json['startDate'].toString());
      }
    } catch (e) {
      debugPrint('Error parsing startDate: $e');
    }
    
    DateTime? endDate;
    try {
      if (json['endDate'] != null) {
        endDate = DateTime.parse(json['endDate'] is String 
            ? json['endDate'] 
            : json['endDate'].toString());
      }
    } catch (e) {
      debugPrint('Error parsing endDate: $e');
    }
    
    DateTime? minimumStayEndDate;
    try {
      if (json['minimumStayEndDate'] != null) {
        minimumStayEndDate = DateTime.parse(json['minimumStayEndDate'] is String 
            ? json['minimumStayEndDate'] 
            : json['minimumStayEndDate'].toString());
      }
    } catch (e) {
      debugPrint('Error parsing minimumStayEndDate: $e');
    }
    
    DateTime? bookingDate;
    try {
      if (json['bookingDate'] != null) {
        bookingDate = DateTime.parse(json['bookingDate'] is String 
            ? json['bookingDate'] 
            : json['bookingDate'].toString());
      }
    } catch (e) {
      debugPrint('Error parsing bookingDate: $e');
    }

    return Booking(
      bookingId: bookingId,
      propertyId: propertyId,
      userId: userId,
      propertyName: json['propertyName']?.toString() ?? 'N/A',
      userName: json['userName']?.toString(),
      propertyImageUrl: _buildImageUrl(json),
      propertyThumbnailUrl: _buildImageUrl(json),
      startDate: startDate ?? DateTime.now(),
      endDate: endDate,
      minimumStayEndDate: minimumStayEndDate,
      totalPrice: totalPrice,
      dailyRate: dailyRate,
      status: statusEnum,
      currency: json['currency']?.toString(),
      bookingDate: bookingDate,
      reviewContent: json['reviewContent']?.toString(),
      reviewRating: json['reviewRating'] is int 
          ? json['reviewRating'] 
          : (json['reviewRating'] != null
              ? int.tryParse(json['reviewRating'].toString())
              : null),
      // New fields with safe parsing
      paymentMethod: json['paymentMethod']?.toString() ?? 'Manual',
      paymentStatus: json['paymentStatus']?.toString(),
      paymentReference: json['paymentReference']?.toString(),
      // Backend alignment
      bookingStatusId: json['bookingStatusId'] is int 
          ? json['bookingStatusId'] 
          : (json['bookingStatusId'] != null
              ? int.tryParse(json['bookingStatusId'].toString())
              : null),
      // Subscription flag for monthly rentals
      isSubscription: json['isSubscription'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'bookingId': bookingId,
        'propertyId': propertyId,
        'userId': userId,
        'propertyName': propertyName,
        'userName': userName,
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
        // Backend alignment
        'bookingStatusId': bookingStatusId,
        'isSubscription': isSubscription,
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
    String? userName,
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
    int? bookingStatusId,
    bool? isSubscription,
  }) {
    return Booking(
      bookingId: bookingId ?? this.bookingId,
      propertyId: propertyId ?? this.propertyId,
      userId: userId ?? this.userId,
      propertyName: propertyName ?? this.propertyName,
      userName: userName ?? this.userName,
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
      bookingStatusId: bookingStatusId ?? this.bookingStatusId,
      isSubscription: isSubscription ?? this.isSubscription,
    );
  }
}
