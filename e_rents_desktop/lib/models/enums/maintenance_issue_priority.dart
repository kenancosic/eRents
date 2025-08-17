// Domain enum: no Flutter imports
enum MaintenanceIssuePriority {
  low,
  medium,
  high,
  emergency,
}

extension MaintenanceIssuePriorityX on MaintenanceIssuePriority {
  String get displayName {
    switch (this) {
      case MaintenanceIssuePriority.low:
        return 'Low';
      case MaintenanceIssuePriority.medium:
        return 'Medium';
      case MaintenanceIssuePriority.high:
        return 'High';
      case MaintenanceIssuePriority.emergency:
        return 'Emergency';
    }
  }

  String get wireValue => name;

  static MaintenanceIssuePriority parse(Object? input, {MaintenanceIssuePriority fallback = MaintenanceIssuePriority.medium}) {
    if (input == null) return fallback;
    final s = input.toString().trim();
    if (s.isEmpty) return fallback;
    switch (s.toLowerCase()) {
      case 'low':
        return MaintenanceIssuePriority.low;
      case 'medium':
        return MaintenanceIssuePriority.medium;
      case 'high':
        return MaintenanceIssuePriority.high;
      case 'emergency':
        return MaintenanceIssuePriority.emergency;
      default:
        return fallback;
    }
  }
}
