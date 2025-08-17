import 'package:e_rents_desktop/models/payment.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/user.dart';

enum TenantStatus {
  active,
  inactive,
  evicted,
  leaseEnded;

  static TenantStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return TenantStatus.active;
      case 'inactive':
        return TenantStatus.inactive;
      case 'evicted':
        return TenantStatus.evicted;
      case 'leaseended':
      case 'lease_ended':
        return TenantStatus.leaseEnded;
      default:
        throw ArgumentError('Unknown tenant status: $status');
    }
  }

  String get displayName {
    switch (this) {
      case TenantStatus.active:
        return 'Active';
      case TenantStatus.inactive:
        return 'Inactive';
      case TenantStatus.evicted:
        return 'Evicted';
      case TenantStatus.leaseEnded:
        return 'Lease Ended';
    }
  }

  String get statusName => name;
}

class Tenant {
  final int tenantId;
  final int userId;
  final int? propertyId;
  final DateTime? leaseStartDate;
  final DateTime? leaseEndDate;
  final TenantStatus tenantStatus;

  // BaseEntity fields
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? createdBy;
  final int? modifiedBy;

  // Navigation properties - excluded from JSON serialization
  final User? user;
  final Property? property;
  final List<Payment>? payments;

  const Tenant({
    required this.tenantId,
    required this.userId,
    this.propertyId,
    this.leaseStartDate,
    this.leaseEndDate,
    this.tenantStatus = TenantStatus.active,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.modifiedBy,
    this.user,
    this.property,
    this.payments,
  });

  factory Tenant.fromJson(Map<String, dynamic> json) {
    DateTime? _parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      final s = v.toString();
      return s.isEmpty ? null : DateTime.tryParse(s);
    }
    TenantStatus _parseStatus(dynamic v) {
      if (v == null) return TenantStatus.active;
      try {
        return TenantStatus.fromString(v.toString());
      } catch (_) {
        return TenantStatus.active;
      }
    }
    return Tenant(
      tenantId: (json['tenantId'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      propertyId: (json['propertyId'] as num?)?.toInt(),
      leaseStartDate: _parseDate(json['leaseStartDate']),
      leaseEndDate: _parseDate(json['leaseEndDate']),
      tenantStatus: _parseStatus(json['tenantStatus'] ?? json['status']),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']) ?? (_parseDate(json['createdAt']) ?? DateTime.now()),
      createdBy: (json['createdBy'] as num?)?.toInt(),
      modifiedBy: (json['modifiedBy'] as num?)?.toInt(),
      // Navigation properties are not parsed from JSON
      user: null,
      property: null,
      payments: null,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'tenantId': tenantId,
        'userId': userId,
        'propertyId': propertyId,
        'leaseStartDate': leaseStartDate?.toIso8601String(),
        'leaseEndDate': leaseEndDate?.toIso8601String(),
        'tenantStatus': tenantStatus.statusName,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'createdBy': createdBy,
        'modifiedBy': modifiedBy,
      };
}