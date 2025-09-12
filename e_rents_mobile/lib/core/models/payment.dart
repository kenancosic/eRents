class Payment {
  final int paymentId;
  final int? tenantId;
  final int? propertyId;
  final double amount;
  final DateTime? datePaid;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? paymentReference;
  final String? currency;
  final DateTime? createdAt;
  // Optional extras (shown in invoice details if provided by backend)
  final String? propertyName;
  final DateTime? periodStart;
  final DateTime? periodEnd;

  Payment({
    required this.paymentId,
    this.tenantId,
    this.propertyId,
    required this.amount,
    this.datePaid,
    this.paymentMethod,
    this.paymentStatus,
    this.paymentReference,
    this.currency,
    this.createdAt,
    this.propertyName,
    this.periodStart,
    this.periodEnd,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    DateTime? _parseDate(dynamic v) {
      try {
        if (v == null) return null;
        if (v is DateTime) return v;
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    return Payment(
      paymentId: json['paymentId'],
      tenantId: json['tenantId'],
      propertyId: json['propertyId'],
      amount: json['amount'].toDouble(),
      datePaid: json['datePaid'] != null ? DateTime.parse(json['datePaid']) : null,
      paymentMethod: json['paymentMethod'],
      paymentStatus: json['paymentStatus'],
      paymentReference: json['paymentReference'],
      currency: json['currency'],
      createdAt: _parseDate(json['createdAt']),
      propertyName: json['propertyName']?.toString(),
      periodStart: _parseDate(json['subscriptionStartDate'] ?? json['periodStart'] ?? json['startDate']),
      periodEnd: _parseDate(json['subscriptionEndDate'] ?? json['periodEnd'] ?? json['endDate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentId': paymentId,
      'tenantId': tenantId,
      'propertyId': propertyId,
      'amount': amount,
      'datePaid': datePaid?.toIso8601String(),
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'paymentReference': paymentReference,
      'currency': currency,
      'createdAt': createdAt?.toIso8601String(),
      'propertyName': propertyName,
      'periodStart': periodStart?.toIso8601String(),
      'periodEnd': periodEnd?.toIso8601String(),
    };
  }
}
