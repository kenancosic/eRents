import 'package:intl/intl.dart';
import 'package:e_rents_desktop/models/enums/booking_status.dart';

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

  final String? propertyName;
  final String? propertyAddress;
  final int? propertyImageId;
  final String? userName;
  final String? userEmail;
  final String? tenantName;
  final String? tenantEmail;

  // Payment-related (from backend BookingResponse)
  final String? paymentMethod;
  final String? currency;
  final String? paymentStatus;
  final String? paymentReference;

  // Base entity fields
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? modifiedBy;
  final String? updatedBy;

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
    this.propertyName,
    this.propertyAddress,
    this.propertyImageId,
    this.userName,
    this.userEmail,
    this.tenantName,
    this.tenantEmail,
    this.paymentMethod,
    this.currency,
    this.paymentStatus,
    this.paymentReference,
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.modifiedBy,
    this.updatedBy,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    DateTime? _parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      final s = v.toString();
      return s.isEmpty ? null : DateTime.tryParse(s);
    }
    double _toDouble(dynamic v) => v is num ? v.toDouble() : double.parse(v.toString());
    String? _asString(dynamic v) => v == null ? null : v.toString();
    BookingStatus _parseStatus(dynamic v) => BookingStatusX.parse(v);
    return Booking(
      bookingId: (json['bookingId'] as num).toInt(),
      propertyId: (json['propertyId'] as num?)?.toInt(),
      userId: (json['userId'] as num?)?.toInt(),
      startDate: _parseDate(json['startDate']) ?? DateTime.now(),
      endDate: _parseDate(json['endDate']),
      minimumStayEndDate: _parseDate(json['minimumStayEndDate']),
      totalPrice: _toDouble(json['totalPrice']),
      bookingDate: _parseDate(json['bookingDate']),
      status: _parseStatus(json['status']),
      propertyName: _asString(json['propertyName']),
      propertyAddress: _asString(json['propertyAddress']),
      propertyImageId: (json['propertyImageId'] as num?)?.toInt(),
      userName: _asString(json['userName']),
      userEmail: _asString(json['userEmail']),
      tenantName: _asString(json['tenantName']),
      tenantEmail: _asString(json['tenantEmail']),
      paymentMethod: _asString(json['paymentMethod']),
      currency: _asString(json['currency']),
      paymentStatus: _asString(json['paymentStatus']),
      paymentReference: _asString(json['paymentReference']),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']),
      createdBy: _asString(json['createdBy']),
      modifiedBy: _asString(json['modifiedBy']),
      updatedBy: _asString(json['updatedBy']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'bookingId': bookingId,
        'propertyId': propertyId,
        'userId': userId,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'minimumStayEndDate': minimumStayEndDate?.toIso8601String(),
        'totalPrice': totalPrice,
        'bookingDate': bookingDate?.toIso8601String(),
        'status': status.wireValue,
        'propertyName': propertyName,
        'propertyAddress': propertyAddress,
        'propertyImageId': propertyImageId,
        'userName': userName,
        'userEmail': userEmail,
        'tenantName': tenantName,
        'tenantEmail': tenantEmail,
        'paymentMethod': paymentMethod,
        'currency': currency,
        'paymentStatus': paymentStatus,
        'paymentReference': paymentReference,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'createdBy': createdBy,
        'modifiedBy': modifiedBy,
        'updatedBy': updatedBy,
      };

  // Convenience getters for UI
  String get dateRange {
    final startFormatted = DateFormat('MMM dd, yyyy').format(startDate);
    if (endDate != null) {
      final endFormatted = DateFormat('MMM dd, yyyy').format(endDate!);
      return '$startFormatted - $endFormatted';
    }
    return startFormatted;
  }

  String get formattedTotalPrice => '\$${totalPrice.toStringAsFixed(2)}';
}