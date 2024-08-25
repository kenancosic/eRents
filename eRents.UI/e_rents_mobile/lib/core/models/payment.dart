class Payment {
  final int paymentId;
  final int? tenantId;
  final int? propertyId;
  final double amount;
  final DateTime? datePaid;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? paymentReference;

  Payment({
    required this.paymentId,
    this.tenantId,
    this.propertyId,
    required this.amount,
    this.datePaid,
    this.paymentMethod,
    this.paymentStatus,
    this.paymentReference,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      paymentId: json['paymentId'],
      tenantId: json['tenantId'],
      propertyId: json['propertyId'],
      amount: json['amount'].toDouble(),
      datePaid: json['datePaid'] != null ? DateTime.parse(json['datePaid']) : null,
      paymentMethod: json['paymentMethod'],
      paymentStatus: json['paymentStatus'],
      paymentReference: json['paymentReference'],
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
    };
  }
}
