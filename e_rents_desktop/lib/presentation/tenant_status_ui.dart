import 'package:flutter/material.dart';

import 'package:e_rents_desktop/models/tenant.dart';

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
