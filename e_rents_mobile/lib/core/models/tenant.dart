import 'package:e_rents_mobile/core/models/user.dart'; // Assuming User model path

class Tenant {
  final int tenantId;
  final int userId;
  final int? propertyId;
  final DateTime? leaseStartDate;
  final String? tenantStatus;
  final User? user; // Nested User object

  Tenant({
    required this.tenantId,
    required this.userId,
    this.propertyId,
    this.leaseStartDate,
    this.tenantStatus,
    this.user,
  });

  factory Tenant.fromJson(Map<String, dynamic> json) {
    return Tenant(
      tenantId: json['tenantId'] as int,
      userId: json['userId'] as int,
      propertyId: json['propertyId'] as int?,
      leaseStartDate: json['leaseStartDate'] != null
          ? DateTime.tryParse(json['leaseStartDate'] as String)
          : null,
      tenantStatus: json['tenantStatus'] as String?,
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenantId': tenantId,
      'userId': userId,
      'propertyId': propertyId,
      'leaseStartDate': leaseStartDate?.toIso8601String(),
      'tenantStatus': tenantStatus,
      'user': user?.toJson(),
    };
  }
}
