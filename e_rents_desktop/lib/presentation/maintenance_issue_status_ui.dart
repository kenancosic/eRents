import 'package:flutter/material.dart';

import 'package:e_rents_desktop/models/enums/maintenance_issue_status.dart';

/// UI extensions for MaintenanceIssueStatus
extension MaintenanceIssueStatusUiX on MaintenanceIssueStatus {
  Color get color {
    switch (this) {
      case MaintenanceIssueStatus.pending:
        return Colors.orange;
      case MaintenanceIssueStatus.inProgress:
        return Colors.blue;
      case MaintenanceIssueStatus.completed:
        return Colors.green;
      case MaintenanceIssueStatus.cancelled:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case MaintenanceIssueStatus.pending:
        return Icons.hourglass_bottom;
      case MaintenanceIssueStatus.inProgress:
        return Icons.build;
      case MaintenanceIssueStatus.completed:
        return Icons.check_circle;
      case MaintenanceIssueStatus.cancelled:
        return Icons.cancel;
    }
  }
}
