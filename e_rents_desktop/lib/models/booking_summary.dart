import 'booking.dart';

/// Summarized booking information for display in lists
class BookingSummary {
  final int bookingId;
  final int propertyId;
  final String propertyName;
  final int tenantId;
  final String? tenantName;
  final String? tenantEmail;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;
  final String currency;
  final String bookingStatus;
  final String paymentStatus;
  final int numberOfGuests;
  final String? specialRequests;
  final bool isArchived;

  BookingSummary({
    required this.bookingId,
    required this.propertyId,
    required this.propertyName,
    required this.tenantId,
    this.tenantName,
    this.tenantEmail,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    this.currency = 'BAM',
    required this.bookingStatus,
    required this.paymentStatus,
    required this.numberOfGuests,
    this.specialRequests,
    this.isArchived = false,
  });

  factory BookingSummary.fromJson(Map<String, dynamic> json) {
    return BookingSummary(
      bookingId: json['bookingId'] ?? 0,
      propertyId: json['propertyId'] ?? 0,
      propertyName: json['propertyName'] ?? 'N/A',
      tenantId: json['tenantId'] ?? 0,
      tenantName: json['tenantName'],
      tenantEmail: json['tenantEmail'],
      startDate: DateTime.tryParse(json['startDate'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['endDate'] ?? '') ?? DateTime.now(),
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'BAM',
      bookingStatus: json['bookingStatus'] ?? 'Unknown',
      paymentStatus: json['paymentStatus'] ?? 'Unknown',
      numberOfGuests: json['numberOfGuests'] ?? 1,
      specialRequests: json['specialRequests'],
      isArchived: json['isArchived'] ?? false,
    );
  }

  /// Create BookingSummary from a full Booking object
  factory BookingSummary.fromBooking(Booking booking) {
    return BookingSummary(
      bookingId: booking.bookingId,
      propertyId: booking.propertyId ?? 0,
      propertyName: booking.propertyName ?? 'N/A',
      tenantId: booking.userId ?? 0,
      tenantName: booking.tenantName ?? booking.userName,
      tenantEmail: booking.tenantEmail ?? booking.userEmail,
      startDate: booking.startDate,
      endDate: booking.endDate ?? booking.startDate,
      totalPrice: booking.totalPrice,
      currency: booking.currency,
      bookingStatus: booking.status.displayName,
      paymentStatus: booking.paymentStatus ?? 'Unknown',
      numberOfGuests: booking.numberOfGuests,
      specialRequests: booking.specialRequests,
      isArchived: false,
    );
  }

  // Helper getters for UI
  bool get isPaymentCompleted => paymentStatus.toLowerCase() == 'completed';
  bool get isPaymentPending => paymentStatus.toLowerCase() == 'pending';
  bool get isPaymentFailed => paymentStatus.toLowerCase() == 'failed';
  bool get hasSpecialRequests =>
      specialRequests != null && specialRequests!.isNotEmpty;
  String get guestCountDisplay =>
      '$numberOfGuests ${numberOfGuests > 1 ? 'guests' : 'guest'}';
}
