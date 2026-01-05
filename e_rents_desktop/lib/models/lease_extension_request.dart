class LeaseExtensionRequest {
  final int requestId;
  final String status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final int requestedByUserId;
  final String? requestedByUserName;
  final int bookingId;
  final int propertyId;
  final String propertyName;
  final DateTime? oldEndDate;
  final DateTime? newEndDate;
  final int? extendByMonths;
  final double? newMonthlyAmount;

  LeaseExtensionRequest({
    required this.requestId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    required this.requestedByUserId,
    this.requestedByUserName,
    required this.bookingId,
    required this.propertyId,
    required this.propertyName,
    this.oldEndDate,
    this.newEndDate,
    this.extendByMonths,
    this.newMonthlyAmount,
  });

  /// Display name for the requester - shows name if available, otherwise user ID
  String get requesterDisplayName => 
      requestedByUserName?.isNotEmpty == true ? requestedByUserName! : 'User #$requestedByUserId';

  factory LeaseExtensionRequest.fromJson(Map<String, dynamic> json) => LeaseExtensionRequest(
        requestId: json['leaseExtensionRequestId'] as int,
        status: (json['status'] as String?) ?? 'Pending',
        createdAt: DateTime.parse(json['createdAt'] as String),
        respondedAt: json['respondedAt'] != null ? DateTime.parse(json['respondedAt'] as String) : null,
        requestedByUserId: json['requestedByUserId'] as int,
        requestedByUserName: json['requestedByUserName'] as String?,
        bookingId: json['bookingId'] as int,
        propertyId: json['propertyId'] as int,
        propertyName: json['propertyName'] as String,
        oldEndDate: _parseDate(json['oldEndDate']),
        newEndDate: _parseDate(json['newEndDate']),
        extendByMonths: json['extendByMonths'] as int?,
        newMonthlyAmount: (json['newMonthlyAmount'] as num?)?.toDouble(),
      );

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    // Support DateOnly serialized as yyyy-MM-dd
    if (s.length == 10 && s[4] == '-' && s[7] == '-') {
      return DateTime.parse(s);
    }
    return DateTime.tryParse(s);
  }
}
