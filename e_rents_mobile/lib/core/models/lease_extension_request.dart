enum LeaseExtensionStatus {
  pending,
  approved,
  rejected,
  cancelled,
}

class LeaseExtensionRequest {
  final int? requestId;
  final int bookingId;
  final int propertyId;
  final int tenantId;
  final DateTime? newEndDate; // null for indefinite extension
  final DateTime? newMinimumStayEndDate;
  final String reason;
  final LeaseExtensionStatus status;
  final DateTime dateRequested;
  final DateTime? dateResponded;
  final String? landlordResponse;
  final String? landlordReason;

  LeaseExtensionRequest({
    this.requestId,
    required this.bookingId,
    required this.propertyId,
    required this.tenantId,
    this.newEndDate,
    this.newMinimumStayEndDate,
    required this.reason,
    this.status = LeaseExtensionStatus.pending,
    required this.dateRequested,
    this.dateResponded,
    this.landlordResponse,
    this.landlordReason,
  });

  factory LeaseExtensionRequest.fromJson(Map<String, dynamic> json) {
    return LeaseExtensionRequest(
      requestId: json['requestId'],
      bookingId: json['bookingId'],
      propertyId: json['propertyId'],
      tenantId: json['tenantId'],
      newEndDate: json['newEndDate'] != null
          ? DateTime.parse(json['newEndDate'])
          : null,
      newMinimumStayEndDate: json['newMinimumStayEndDate'] != null
          ? DateTime.parse(json['newMinimumStayEndDate'])
          : null,
      reason: json['reason'],
      status: LeaseExtensionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => LeaseExtensionStatus.pending,
      ),
      dateRequested: DateTime.parse(json['dateRequested']),
      dateResponded: json['dateResponded'] != null
          ? DateTime.parse(json['dateResponded'])
          : null,
      landlordResponse: json['landlordResponse'],
      landlordReason: json['landlordReason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requestId': requestId,
      'bookingId': bookingId,
      'propertyId': propertyId,
      'tenantId': tenantId,
      'newEndDate': newEndDate?.toIso8601String(),
      'newMinimumStayEndDate': newMinimumStayEndDate?.toIso8601String(),
      'reason': reason,
      'status': status.toString().split('.').last,
      'dateRequested': dateRequested.toIso8601String(),
      'dateResponded': dateResponded?.toIso8601String(),
      'landlordResponse': landlordResponse,
      'landlordReason': landlordReason,
    };
  }

  LeaseExtensionRequest copyWith({
    int? requestId,
    int? bookingId,
    int? propertyId,
    int? tenantId,
    DateTime? newEndDate,
    DateTime? newMinimumStayEndDate,
    String? reason,
    LeaseExtensionStatus? status,
    DateTime? dateRequested,
    DateTime? dateResponded,
    String? landlordResponse,
    String? landlordReason,
  }) {
    return LeaseExtensionRequest(
      requestId: requestId ?? this.requestId,
      bookingId: bookingId ?? this.bookingId,
      propertyId: propertyId ?? this.propertyId,
      tenantId: tenantId ?? this.tenantId,
      newEndDate: newEndDate ?? this.newEndDate,
      newMinimumStayEndDate:
          newMinimumStayEndDate ?? this.newMinimumStayEndDate,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      dateRequested: dateRequested ?? this.dateRequested,
      dateResponded: dateResponded ?? this.dateResponded,
      landlordResponse: landlordResponse ?? this.landlordResponse,
      landlordReason: landlordReason ?? this.landlordReason,
    );
  }
}
