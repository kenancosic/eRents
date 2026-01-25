/// Status of a lease extension request
enum LeaseExtensionStatus {
  pending,
  approved,
  rejected,
}

/// Response model for lease extension request from API
class LeaseExtensionRequestResponse {
  final int leaseExtensionRequestId;
  final LeaseExtensionStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final DateTime? oldEndDate;
  final DateTime? newEndDate;
  final int? extendByMonths;
  final double? newMonthlyAmount;
  final String? reason;

  LeaseExtensionRequestResponse({
    required this.leaseExtensionRequestId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    this.oldEndDate,
    this.newEndDate,
    this.extendByMonths,
    this.newMonthlyAmount,
    this.reason,
  });

  factory LeaseExtensionRequestResponse.fromJson(Map<String, dynamic> json) {
    LeaseExtensionStatus parseStatus(dynamic raw) {
      if (raw == null) return LeaseExtensionStatus.pending;
      final s = raw.toString().toLowerCase();
      switch (s) {
        case 'approved':
          return LeaseExtensionStatus.approved;
        case 'rejected':
          return LeaseExtensionStatus.rejected;
        default:
          return LeaseExtensionStatus.pending;
      }
    }

    return LeaseExtensionRequestResponse(
      leaseExtensionRequestId: json['leaseExtensionRequestId'] as int? ?? 0,
      status: parseStatus(json['status']),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'] as String)
          : null,
      oldEndDate: json['oldEndDate'] != null
          ? DateTime.parse(json['oldEndDate'] as String)
          : null,
      newEndDate: json['newEndDate'] != null
          ? DateTime.parse(json['newEndDate'] as String)
          : null,
      extendByMonths: json['extendByMonths'] as int?,
      newMonthlyAmount: json['newMonthlyAmount'] != null
          ? (json['newMonthlyAmount'] as num).toDouble()
          : null,
      reason: json['reason'] as String?,
    );
  }

  bool get isPending => status == LeaseExtensionStatus.pending;
  bool get isApproved => status == LeaseExtensionStatus.approved;
  bool get isRejected => status == LeaseExtensionStatus.rejected;

  String get statusDisplay {
    switch (status) {
      case LeaseExtensionStatus.pending:
        return 'Pending';
      case LeaseExtensionStatus.approved:
        return 'Approved';
      case LeaseExtensionStatus.rejected:
        return 'Declined';
    }
  }
}

/// Request model for creating a lease extension request
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
