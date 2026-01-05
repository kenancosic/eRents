/// Subscription model for monthly rental payments
class Subscription {
  final int subscriptionId;
  final int tenantId;
  final int propertyId;
  final int? bookingId;
  final double monthlyAmount;
  final String currency;
  final String status; // Active, Paused, Cancelled, Completed
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? nextPaymentDate;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Optional related info
  final String? propertyName;
  final String? propertyAddress;

  Subscription({
    required this.subscriptionId,
    required this.tenantId,
    required this.propertyId,
    this.bookingId,
    required this.monthlyAmount,
    required this.currency,
    required this.status,
    required this.startDate,
    this.endDate,
    this.nextPaymentDate,
    required this.createdAt,
    this.updatedAt,
    this.propertyName,
    this.propertyAddress,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      subscriptionId: json['subscriptionId'] ?? json['id'] ?? 0,
      tenantId: json['tenantId'] ?? 0,
      propertyId: json['propertyId'] ?? 0,
      bookingId: json['bookingId'],
      monthlyAmount: (json['monthlyAmount'] ?? json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
      status: json['status'] ?? 'Unknown',
      startDate: json['startDate'] != null 
          ? DateTime.parse(json['startDate']) 
          : DateTime.now(),
      endDate: json['endDate'] != null 
          ? DateTime.parse(json['endDate']) 
          : null,
      nextPaymentDate: json['nextPaymentDate'] != null 
          ? DateTime.parse(json['nextPaymentDate']) 
          : null,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
      propertyName: json['propertyName'] as String?,
      propertyAddress: json['propertyAddress'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subscriptionId': subscriptionId,
      'tenantId': tenantId,
      'propertyId': propertyId,
      'bookingId': bookingId,
      'monthlyAmount': monthlyAmount,
      'currency': currency,
      'status': status,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'nextPaymentDate': nextPaymentDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'propertyName': propertyName,
      'propertyAddress': propertyAddress,
    };
  }

  // Helper properties
  bool get isActive => status.toLowerCase() == 'active';
  bool get isPaused => status.toLowerCase() == 'paused';
  bool get isCancelled => status.toLowerCase() == 'cancelled';
  
  String get formattedAmount => '$currency ${monthlyAmount.toStringAsFixed(2)}';
  
  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'active': return 'Active';
      case 'paused': return 'Paused';
      case 'cancelled': return 'Cancelled';
      case 'completed': return 'Completed';
      default: return status;
    }
  }
}
