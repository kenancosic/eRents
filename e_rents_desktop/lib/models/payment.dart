import 'package:e_rents_desktop/models/booking.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/tenant.dart';
import 'package:e_rents_desktop/models/user.dart';

enum PaymentStatus {
  pending,
  completed,
  failed,
  cancelled,
  refunded;

  static PaymentStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return PaymentStatus.pending;
      case 'completed':
        return PaymentStatus.completed;
      case 'failed':
        return PaymentStatus.failed;
      case 'cancelled':
        return PaymentStatus.cancelled;
      case 'refunded':
        return PaymentStatus.refunded;
      default:
        throw ArgumentError('Unknown payment status: $status');
    }
  }

  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.cancelled:
        return 'Cancelled';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }

  String get statusName => name.toLowerCase();
}

enum PaymentMethod {
  paypal, // Legacy - kept for historical payment records only
  stripe; // Primary payment method

  static PaymentMethod fromString(String method) {
    switch (method.toLowerCase()) {
      case 'paypal':
        return PaymentMethod.paypal;
      case 'stripe':
        return PaymentMethod.stripe;
      default:
        throw ArgumentError('Unknown payment method: $method');
    }
  }

  String get displayName {
    switch (this) {
      case PaymentMethod.paypal:
        return 'PayPal (Legacy)';
      case PaymentMethod.stripe:
        return 'Stripe';
    }
  }

  String get methodName => name;
  
  /// Returns true if this is an active payment method
  bool get isActive => this == PaymentMethod.stripe;
}

enum PaymentType {
  bookingPayment,
  refund;

  static PaymentType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'bookingpayment':
      case 'booking_payment':
        return PaymentType.bookingPayment;
      case 'refund':
        return PaymentType.refund;
      default:
        throw ArgumentError('Unknown payment type: $type');
    }
  }

  String get displayName {
    switch (this) {
      case PaymentType.bookingPayment:
        return 'Booking Payment';
      case PaymentType.refund:
        return 'Refund';
    }
  }

  String get typeName => name;
}

class Payment {
  final int paymentId;
  final int? tenantId;
  final int? propertyId;
  final int? bookingId;
  final double amount;
  final String? currency;
  final PaymentMethod? paymentMethod;
  final PaymentStatus? paymentStatus;
  final String? paymentReference;

  // Stripe payment fields
  final String? stripePaymentIntentId;
  final String? stripeChargeId;

  // Additional fields for refund support
  final int? originalPaymentId;
  final String? refundReason;
  final PaymentType paymentType;

  // BaseEntity fields
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? createdBy;
  final int? modifiedBy;

  // Navigation properties - excluded from JSON serialization
  final Booking? booking;
  final Property? property;
  final Tenant? tenant;
  final Payment? originalPayment;
  final List<Payment>? refunds;

  const Payment({
    required this.paymentId,
    this.tenantId,
    this.propertyId,
    this.bookingId,
    required this.amount,
    this.currency,
    this.paymentMethod,
    this.paymentStatus,
    this.paymentReference,
    this.stripePaymentIntentId,
    this.stripeChargeId,
    this.originalPaymentId,
    this.refundReason,
    this.paymentType = PaymentType.bookingPayment,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.modifiedBy,
    this.booking,
    this.property,
    this.tenant,
    this.originalPayment,
    this.refunds,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    DateTime _reqDate(dynamic v) {
      final d = (v == null) ? null : (v is DateTime ? v : DateTime.tryParse(v.toString()));
      return d ?? DateTime.now();
    }
    double _toDouble(dynamic v) => v is num ? v.toDouble() : double.parse(v.toString());
    int? _asInt(dynamic v) => v == null ? null : (v is num ? v.toInt() : int.tryParse(v.toString()));
    String? _asString(dynamic v) => v == null ? null : v.toString();
    PaymentStatus? _parseStatus(dynamic v) {
      if (v == null) return null;
      final s = v.toString();
      try { return PaymentStatus.fromString(s); } catch (_) { return null; }
    }
    PaymentMethod? _parseMethod(dynamic v) {
      if (v == null) return null;
      final s = v.toString();
      try { return PaymentMethod.fromString(s); } catch (_) { return null; }
    }
    PaymentType _parseType(dynamic v) {
      if (v == null) return PaymentType.bookingPayment;
      final s = v.toString();
      try { return PaymentType.fromString(s); } catch (_) { return PaymentType.bookingPayment; }
    }
    
    // Parse tenant info from backend response
    Tenant? parsedTenant;
    final tenantJson = json['tenant'];
    if (tenantJson != null && tenantJson is Map<String, dynamic>) {
      final now = DateTime.now();
      parsedTenant = Tenant(
        tenantId: _asInt(tenantJson['tenantId']) ?? 0,
        userId: _asInt(tenantJson['userId']) ?? 0,
        propertyId: null,
        leaseStartDate: null,
        leaseEndDate: null,
        tenantStatus: TenantStatus.active,
        createdAt: now,
        updatedAt: now,
        user: User(
          userId: _asInt(tenantJson['userId']) ?? 0,
          firstName: _asString(tenantJson['firstName']),
          lastName: _asString(tenantJson['lastName']),
          email: _asString(tenantJson['email']) ?? '',
          username: '',
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    
    return Payment(
      paymentId: (json['paymentId'] as num).toInt(),
      tenantId: _asInt(json['tenantId']),
      propertyId: _asInt(json['propertyId']),
      bookingId: _asInt(json['bookingId']),
      amount: _toDouble(json['amount']),
      currency: _asString(json['currency']),
      paymentMethod: _parseMethod(json['paymentMethod']),
      paymentStatus: _parseStatus(json['paymentStatus']),
      paymentReference: _asString(json['paymentReference']),
      stripePaymentIntentId: _asString(json['stripePaymentIntentId']),
      stripeChargeId: _asString(json['stripeChargeId']),
      originalPaymentId: _asInt(json['originalPaymentId']),
      refundReason: _asString(json['refundReason']),
      paymentType: _parseType(json['paymentType']),
      createdAt: _reqDate(json['createdAt']),
      updatedAt: _reqDate(json['updatedAt'] ?? json['createdAt']),
      createdBy: _asInt(json['createdBy']),
      modifiedBy: _asInt(json['modifiedBy']),
      booking: null,
      property: null,
      tenant: parsedTenant,
      originalPayment: null,
      refunds: null,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'paymentId': paymentId,
        'tenantId': tenantId,
        'propertyId': propertyId,
        'bookingId': bookingId,
        'amount': amount,
        'currency': currency,
        'paymentMethod': paymentMethod?.methodName,
        'paymentStatus': paymentStatus?.statusName,
        'paymentReference': paymentReference,
        'stripePaymentIntentId': stripePaymentIntentId,
        'stripeChargeId': stripeChargeId,
        'originalPaymentId': originalPaymentId,
        'refundReason': refundReason,
        'paymentType': paymentType.typeName,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'createdBy': createdBy,
        'modifiedBy': modifiedBy,
      };
}