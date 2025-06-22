import '../../../base/base.dart';
import '../../../models/maintenance_issue.dart';
import '../../../utils/date_utils.dart';

/// Detail provider for managing single maintenance issue data
///
/// Replaces part of the old MaintenanceProvider with a cleaner implementation
/// focused only on maintenance issue detail management.
class MaintenanceDetailProvider extends DetailProvider<MaintenanceIssue> {
  MaintenanceDetailProvider(super.repository);

  /// Get the maintenance repository with proper typing
  MaintenanceRepository get maintenanceRepository =>
      repository as MaintenanceRepository;

  // Maintenance-specific convenience getters

  /// Get the current maintenance issue (alias for item)
  MaintenanceIssue? get issue => item;

  /// Check if issue is pending
  bool get isPending => issue?.status == IssueStatus.pending;

  /// Check if issue is in progress
  bool get isInProgress => issue?.status == IssueStatus.inProgress;

  /// Check if issue is completed
  bool get isCompleted => issue?.status == IssueStatus.completed;

  /// Check if issue is emergency priority
  bool get isEmergency => issue?.priority == IssuePriority.emergency;

  /// Check if issue is high priority
  bool get isHighPriority => issue?.priority == IssuePriority.high;

  /// Check if issue is a tenant complaint
  bool get isTenantComplaint => issue?.isTenantComplaint ?? false;

  /// Get issue title safely
  String get title => issue?.title ?? 'Unknown Issue';

  /// Get issue description safely
  String get description => issue?.description ?? '';

  /// Get issue category safely
  String get category => issue?.category ?? 'General';

  /// Get issue cost safely
  double get cost => issue?.cost ?? 0.0;

  /// Get issue status safely
  IssueStatus get status => issue?.status ?? IssueStatus.pending;

  /// Get issue priority safely
  IssuePriority get priority => issue?.priority ?? IssuePriority.medium;

  /// Get property ID safely
  int get propertyId => issue?.propertyId ?? 0;

  /// Get created date safely
  DateTime get createdAt => issue?.createdAt ?? DateTime.now();

  /// Get resolved date safely
  DateTime? get resolvedAt => issue?.resolvedAt;

  /// Get resolution notes safely
  String? get resolutionNotes => issue?.resolutionNotes;

  /// Get images safely
  List<dynamic> get images => issue?.images ?? [];

  // Business logic getters

  /// Check if issue has cost information
  bool get hasCost => cost > 0;

  /// Check if issue has images
  bool get hasImages => images.isNotEmpty;

  /// Check if issue has resolution notes
  bool get hasResolutionNotes =>
      resolutionNotes != null && resolutionNotes!.isNotEmpty;

  /// Check if issue is actionable (pending or in progress)
  bool get isActionable => isPending || isInProgress;

  /// Check if issue requires urgent attention
  bool get requiresUrgentAttention => isEmergency && !isCompleted;

  /// Get days since creation
  int get daysSinceCreation {
    return DateTime.now().difference(createdAt).inDays;
  }

  /// Check if issue is recent (created within last 7 days)
  bool get isRecent => daysSinceCreation <= 7;

  /// Check if issue might be overdue (emergency issues pending for more than 1 day)
  bool get mightBeOverdue => isEmergency && isPending && daysSinceCreation > 1;

  // Formatting methods for UI

  /// Get formatted status text
  String get statusDisplayText {
    switch (status) {
      case IssueStatus.pending:
        return 'Pending';
      case IssueStatus.inProgress:
        return 'In Progress';
      case IssueStatus.completed:
        return 'Completed';
      case IssueStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Get formatted priority text
  String get priorityDisplayText {
    switch (priority) {
      case IssuePriority.low:
        return 'Low Priority';
      case IssuePriority.medium:
        return 'Medium Priority';
      case IssuePriority.high:
        return 'High Priority';
      case IssuePriority.emergency:
        return 'Emergency';
      default:
        return 'Unknown Priority';
    }
  }

  /// Get formatted cost string
  String getFormattedCost({String currency = 'BAM'}) {
    if (!hasCost) return 'No cost recorded';
    return '${cost.toStringAsFixed(2)} $currency';
  }

  /// Get formatted creation date
  String getFormattedCreatedDate() {
    return AppDateUtils.formatShort(createdAt);
  }

  /// Get formatted creation date with time
  String getFormattedCreatedDateTime() {
    return AppDateUtils.formatShortWithTime(createdAt);
  }

  /// Get time ago string (e.g., "2 days ago")
  String getTimeAgo() {
    return AppDateUtils.formatRelative(createdAt);
  }

  /// Get issue summary for display
  String getIssueSummary() {
    final priorityText = isEmergency ? ' (EMERGENCY)' : '';
    return '$title - $statusDisplayText$priorityText';
  }

  // Repository-backed methods

  /// Force reload issue from server (bypass cache)
  Future<void> forceReloadIssue() async {
    if (item != null) {
      await repository.clearCache();
      await loadItem(item!.maintenanceIssueId.toString());
    }
  }

  // Validation methods

  /// Check if issue data is complete
  bool get isDataComplete {
    return issue != null &&
        title.isNotEmpty &&
        description.isNotEmpty &&
        category.isNotEmpty &&
        propertyId > 0;
  }

  /// Get validation errors for issue data
  List<String> get validationErrors {
    final errors = <String>[];

    if (issue == null) {
      errors.add('Maintenance issue data not loaded');
      return errors;
    }

    if (title.isEmpty) errors.add('Issue title is missing');
    if (description.isEmpty) errors.add('Issue description is missing');
    if (category.isEmpty) errors.add('Issue category is missing');
    if (propertyId <= 0) errors.add('Valid property ID is required');

    return errors;
  }

  /// Check if issue is valid for display
  bool get isValidForDisplay => validationErrors.isEmpty;

  // Helper methods for status transitions

  /// Check if issue can be marked as completed
  bool get canMarkAsCompleted => isPending || isInProgress;

  /// Check if issue can be marked as in progress
  bool get canMarkAsInProgress => isPending;

  /// Check if issue can be reopened (marked as pending)
  bool get canReopenIssue => isCompleted;

  /// Get available status transitions
  List<IssueStatus> get availableStatusTransitions {
    final transitions = <IssueStatus>[];

    if (canMarkAsInProgress) transitions.add(IssueStatus.inProgress);
    if (canMarkAsCompleted) transitions.add(IssueStatus.completed);
    if (canReopenIssue) transitions.add(IssueStatus.pending);

    return transitions;
  }

  /// Get status transition description
  String getStatusTransitionDescription(IssueStatus newStatus) {
    switch (newStatus) {
      case IssueStatus.pending:
        return 'Reopen this issue';
      case IssueStatus.inProgress:
        return 'Start working on this issue';
      case IssueStatus.completed:
        return 'Mark this issue as completed';
      default:
        return 'Change status to ${newStatus.name}';
    }
  }
}
