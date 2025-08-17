// Domain enum: no Flutter imports
enum MaintenanceIssueStatus {
  pending,
  inProgress,
  completed,
  cancelled,
}

extension MaintenanceIssueStatusX on MaintenanceIssueStatus {
  String get displayName {
    switch (this) {
      case MaintenanceIssueStatus.pending:
        return 'Pending';
      case MaintenanceIssueStatus.inProgress:
        return 'In Progress';
      case MaintenanceIssueStatus.completed:
        return 'Completed';
      case MaintenanceIssueStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get wireValue => name; // prefer stable lowercase camelcase

  static MaintenanceIssueStatus parse(Object? input, {MaintenanceIssueStatus fallback = MaintenanceIssueStatus.pending}) {
    if (input == null) return fallback;
    final s = input.toString().trim();
    if (s.isEmpty) return fallback;
    switch (s.toLowerCase()) {
      case 'pending':
        return MaintenanceIssueStatus.pending;
      case 'inprogress':
      case 'in_progress':
      case 'in progress':
        return MaintenanceIssueStatus.inProgress;
      case 'completed':
      case 'complete':
        return MaintenanceIssueStatus.completed;
      case 'cancelled':
      case 'canceled':
        return MaintenanceIssueStatus.cancelled;
      default:
        return fallback;
    }
  }
}
