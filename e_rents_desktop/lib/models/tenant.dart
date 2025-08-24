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
    // Try parse nested user/property if backend sends them
    User? _parseUser() {
      final u = json['user'];
      if (u is Map<String, dynamic>) {
        return User.fromJson(u);
      }
      // Fallback: synthesize from lightweight flat fields if present
      final username = json['username']?.toString();
      final email = json['email']?.toString();
      final firstName = json['firstName']?.toString();
      final lastName = json['lastName']?.toString();
      if (username != null || email != null || firstName != null || lastName != null) {
        return User(
          userId: (json['userId'] as num).toInt(),
          email: email ?? '',
          username: username ?? '',
          firstName: firstName,
          lastName: lastName,
          createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
          updatedAt: _parseDate(json['updatedAt']) ?? DateTime.now(),
        );
      }
      return null;
    }

    Property? _parseProperty() {
      final p = json['property'];
      if (p is Map<String, dynamic>) {
        return Property.fromJson(p);
      }
      // Fallback: synthesize minimal property from flat fields
      final name = json['propertyName']?.toString();
      final city = json['city']?.toString();
      if (name != null || city != null) {
        return Property.fromJson({
          'propertyId': (json['propertyId'] as num?)?.toInt() ?? 0,
          'ownerId': 0,
          'price': 0,
          'currency': 'BAM',
          'name': name ?? '-',
          'imageIds': const <int>[],
          'amenityIds': const <int>[],
          'address': {
            'city': city,
          },
        });
      }
      return null;
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
      user: _parseUser(),
      property: _parseProperty(),
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