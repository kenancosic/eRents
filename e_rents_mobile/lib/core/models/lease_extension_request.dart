class LeaseExtensionRequest {
  final int bookingId;
  // Provide either newEndDate OR extendByMonths (mutually exclusive)
  final DateTime? newEndDate;
  final int? extendByMonths;
  // Optional: update monthly amount on the subscription
  final double? newMonthlyAmount;

  LeaseExtensionRequest({
    required this.bookingId,
    this.newEndDate,
    this.extendByMonths,
    this.newMonthlyAmount,
  }) : assert(
          (newEndDate != null) ^ (extendByMonths != null),
          'Provide either newEndDate or extendByMonths, not both',
        );

  factory LeaseExtensionRequest.fromJson(Map<String, dynamic> json) {
    return LeaseExtensionRequest(
      bookingId: json['bookingId'] as int,
      newEndDate: json['newEndDate'] != null
          ? DateTime.parse(json['newEndDate'] as String)
          : null,
      extendByMonths:
          json['extendByMonths'] != null ? json['extendByMonths'] as int : null,
      newMonthlyAmount: json['newMonthlyAmount'] != null
          ? (json['newMonthlyAmount'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'newEndDate': newEndDate?.toIso8601String(),
      'extendByMonths': extendByMonths,
      'newMonthlyAmount': newMonthlyAmount,
    };
  }

  LeaseExtensionRequest copyWith({
    int? bookingId,
    DateTime? newEndDate,
    int? extendByMonths,
    double? newMonthlyAmount,
  }) {
    return LeaseExtensionRequest(
      bookingId: bookingId ?? this.bookingId,
      newEndDate: newEndDate ?? this.newEndDate,
      extendByMonths: extendByMonths ?? this.extendByMonths,
      newMonthlyAmount: newMonthlyAmount ?? this.newMonthlyAmount,
    );
  }
}
