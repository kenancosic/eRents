class PropertyTenantSummary {
  final int tenantId;
  final int userId;
  final String? fullName;
  final String? email;
  final DateTime? leaseStartDate;
  final DateTime? leaseEndDate;
  final String tenantStatus; // keep as string for simplicity

  const PropertyTenantSummary({
    required this.tenantId,
    required this.userId,
    this.fullName,
    this.email,
    this.leaseStartDate,
    this.leaseEndDate,
    required this.tenantStatus,
  });

  factory PropertyTenantSummary.fromJson(Map<String, dynamic> json) {
    DateTime? _parse(dynamic v) {
      if (v == null) return null;
      final s = v.toString();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }
    return PropertyTenantSummary(
      tenantId: (json['tenantId'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      fullName: json['fullName'] as String?,
      email: json['email'] as String?,
      leaseStartDate: _parse(json['leaseStartDate']),
      leaseEndDate: _parse(json['leaseEndDate']),
      tenantStatus: (json['tenantStatus']?.toString() ?? ''),
    );
  }
}
