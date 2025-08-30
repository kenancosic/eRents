import 'package:flutter/material.dart';

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

/// UI extensions for TenantStatus
extension TenantStatusUiX on TenantStatus {
  Color get color {
    switch (this) {
      case TenantStatus.active:
        return Colors.green;
      case TenantStatus.inactive:
        return Colors.grey;
      case TenantStatus.evicted:
        return Colors.red;
      case TenantStatus.leaseEnded:
        return Colors.orange;
    }
  }

  IconData get icon {
    switch (this) {
      case TenantStatus.active:
        return Icons.check_circle;
      case TenantStatus.inactive:
        return Icons.pause_circle;
      case TenantStatus.evicted:
        return Icons.cancel;
      case TenantStatus.leaseEnded:
        return Icons.event_busy;
    }
  }
}
