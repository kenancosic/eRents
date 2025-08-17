import 'package:flutter/material.dart';

import 'package:e_rents_desktop/models/enums/maintenance_issue_priority.dart';

/// UI extensions for MaintenanceIssuePriority
extension MaintenanceIssuePriorityUiX on MaintenanceIssuePriority {
  Color get color {
    switch (this) {
      case MaintenanceIssuePriority.low:
        return Colors.green;
      case MaintenanceIssuePriority.medium:
        return Colors.orange;
      case MaintenanceIssuePriority.high:
        return Colors.red;
      case MaintenanceIssuePriority.emergency:
        return Colors.deepPurple;
    }
  }

  IconData get icon {
    switch (this) {
      case MaintenanceIssuePriority.low:
        return Icons.low_priority;
      case MaintenanceIssuePriority.medium:
        return Icons.priority_high;
      case MaintenanceIssuePriority.high:
        return Icons.report_problem;
      case MaintenanceIssuePriority.emergency:
        return Icons.warning_amber_rounded;
    }
  }

  /// Numeric severity for sorting (higher means more severe)
  int get severityWeight {
    switch (this) {
      case MaintenanceIssuePriority.low:
        return 1;
      case MaintenanceIssuePriority.medium:
        return 2;
      case MaintenanceIssuePriority.high:
        return 3;
      case MaintenanceIssuePriority.emergency:
        return 4;
    }
  }
}
