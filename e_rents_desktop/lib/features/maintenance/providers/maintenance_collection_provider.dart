import '../../../base/base.dart';
import '../../../base/providers/base_collection_provider_mixin.dart';
import '../../../models/maintenance_issue.dart';
import '../../../widgets/table/core/table_query.dart';

/// Collection provider for managing maintenance issues
///
/// Replaces the old MaintenanceProvider with a cleaner, more focused implementation
/// that separates concerns and uses the repository pattern for data access.
///
/// ✅ UNIVERSAL SYSTEM INTEGRATION - Updated for Universal System pagination
class MaintenanceCollectionProvider extends CollectionProvider<MaintenanceIssue>
    with PaginationProviderMixin<MaintenanceIssue> {
  MaintenanceCollectionProvider(super.repository);

  /// Get the maintenance repository with proper typing
  MaintenanceRepository get maintenanceRepository =>
      repository as MaintenanceRepository;

  // ✅ UNIVERSAL SYSTEM - New pagination-first method using mixin
  /// Get paged maintenance issues using Universal System
  /// Default method for table components and large data sets
  Future<Map<String, dynamic>> getPagedMaintenanceIssues([
    Map<String, dynamic>? params,
  ]) async {
    return getPagedData(
      maintenanceRepository.getPagedMaintenanceIssues,
      params,
    );
  }

  // Maintenance-specific convenience getters

  /// Get all maintenance issues (alias for items)
  List<MaintenanceIssue> get issues => items;

  /// Get pending maintenance issues
  List<MaintenanceIssue> get pendingIssues {
    return filterItems((issue) => issue.status == IssueStatus.pending);
  }

  /// Get in-progress maintenance issues
  List<MaintenanceIssue> get inProgressIssues {
    return filterItems((issue) => issue.status == IssueStatus.inProgress);
  }

  /// Get completed maintenance issues
  List<MaintenanceIssue> get completedIssues {
    return filterItems((issue) => issue.status == IssueStatus.completed);
  }

  /// Get emergency priority issues
  List<MaintenanceIssue> get emergencyIssues {
    return filterItems((issue) => issue.priority == IssuePriority.emergency);
  }

  /// Get high priority issues
  List<MaintenanceIssue> get highPriorityIssues {
    return filterItems((issue) => issue.priority == IssuePriority.high);
  }

  /// Get issues by status
  List<MaintenanceIssue> getIssuesByStatus(IssueStatus status) {
    return filterItems((issue) => issue.status == status);
  }

  /// Get issues by priority
  List<MaintenanceIssue> getIssuesByPriority(IssuePriority priority) {
    return filterItems((issue) => issue.priority == priority);
  }

  /// Get issues for a specific property
  List<MaintenanceIssue> getIssuesByProperty(int propertyId) {
    return filterItems((issue) => issue.propertyId == propertyId);
  }

  /// Get issues by category
  List<MaintenanceIssue> getIssuesByCategory(String category) {
    return filterItems(
      (issue) => issue.category?.toLowerCase() == category.toLowerCase(),
    );
  }

  // Maintenance-specific business logic

  /// Get total number of maintenance issues
  int get totalIssues => length;

  /// Get count of pending issues
  int get pendingIssuesCount => pendingIssues.length;

  /// Get count of in-progress issues
  int get inProgressIssuesCount => inProgressIssues.length;

  /// Get count of completed issues
  int get completedIssuesCount => completedIssues.length;

  /// Get count of emergency issues
  int get emergencyIssuesCount => emergencyIssues.length;

  /// Get completion rate (completed / total)
  double get completionRate {
    if (totalIssues == 0) return 0.0;
    return completedIssuesCount / totalIssues;
  }

  /// Get percentage of issues that are emergency priority
  double get emergencyRate {
    if (totalIssues == 0) return 0.0;
    return emergencyIssuesCount / totalIssues;
  }

  /// Get average cost of maintenance issues (where cost is available)
  double get averageCost {
    final issuesWithCost = items.where(
      (issue) => issue.cost != null && issue.cost! > 0,
    );
    if (issuesWithCost.isEmpty) return 0.0;

    final totalCost = issuesWithCost.fold(
      0.0,
      (sum, issue) => sum + issue.cost!,
    );
    return totalCost / issuesWithCost.length;
  }

  /// Get total cost of all maintenance issues
  double get totalCost {
    return items
        .where((issue) => issue.cost != null)
        .fold(0.0, (sum, issue) => sum + (issue.cost ?? 0.0));
  }

  /// Get issues that are overdue (no due date handling in current model)
  List<MaintenanceIssue> get overdueIssues {
    // For now, consider emergency issues that are still pending as "overdue"
    return filterItems(
      (issue) =>
          issue.priority == IssuePriority.emergency &&
          issue.status == IssueStatus.pending,
    );
  }

  /// Get recent issues (last 30 days)
  List<MaintenanceIssue> get recentIssues {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return filterItems((issue) => issue.createdAt.isAfter(thirtyDaysAgo));
  }

  // Repository-backed methods (use repository for server operations)

  /// Fetch issues for a specific property from server
  Future<List<MaintenanceIssue>> fetchIssuesByProperty(int propertyId) async {
    final params = {'propertyId': propertyId.toString()};
    await fetchItems(params);
    return getIssuesByProperty(propertyId);
  }

  /// Fetch issues by status from server
  Future<List<MaintenanceIssue>> fetchIssuesByStatus(IssueStatus status) async {
    final params = {'status': status.name};
    await fetchItems(params);
    return getIssuesByStatus(status);
  }

  /// Update issue status with additional data
  Future<void> updateIssueStatus(
    String issueId,
    IssueStatus newStatus, {
    String? resolutionNotes,
    double? cost,
  }) async {
    // Find the issue in current list
    final currentIssue = getItemById(issueId);
    if (currentIssue == null) {
      throw AppError(
        type: ErrorType.notFound,
        message: 'Maintenance issue not found: $issueId',
      );
    }

    // Use repository method for status update
    await maintenanceRepository.updateIssueStatus(
      issueId,
      newStatus,
      resolutionNotes: resolutionNotes,
      cost: cost,
    );

    // Refresh the item to get updated data
    await refreshItems();
  }

  /// Search issues by title, description, or category
  List<MaintenanceIssue> searchIssues(String query) {
    if (query.isEmpty) return items;

    final lowercaseQuery = query.toLowerCase();
    return filterItems(
      (issue) =>
          issue.title.toLowerCase().contains(lowercaseQuery) ||
          issue.description.toLowerCase().contains(lowercaseQuery) ||
          (issue.category?.toLowerCase().contains(lowercaseQuery) ?? false),
    );
  }

  /// Filter issues by multiple criteria
  List<MaintenanceIssue> filterIssues({
    IssueStatus? status,
    IssuePriority? priority,
    int? propertyId,
    String? category,
    bool? isTenantComplaint,
    String? searchQuery,
  }) {
    List<MaintenanceIssue> filtered = List.from(items);

    if (status != null) {
      filtered = filtered.where((issue) => issue.status == status).toList();
    }

    if (priority != null) {
      filtered = filtered.where((issue) => issue.priority == priority).toList();
    }

    if (propertyId != null) {
      filtered =
          filtered.where((issue) => issue.propertyId == propertyId).toList();
    }

    if (category != null && category.isNotEmpty) {
      filtered =
          filtered
              .where(
                (issue) =>
                    issue.category?.toLowerCase() == category.toLowerCase(),
              )
              .toList();
    }

    if (isTenantComplaint != null) {
      filtered =
          filtered
              .where((issue) => issue.isTenantComplaint == isTenantComplaint)
              .toList();
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final lowercaseQuery = searchQuery.toLowerCase();
      filtered =
          filtered
              .where(
                (issue) =>
                    issue.title.toLowerCase().contains(lowercaseQuery) ||
                    issue.description.toLowerCase().contains(lowercaseQuery) ||
                    (issue.category?.toLowerCase().contains(lowercaseQuery) ??
                        false),
              )
              .toList();
    }

    return filtered;
  }

  /// Sort issues by different criteria
  List<MaintenanceIssue> sortIssues({
    required MaintenanceSortCriteria criteria,
    bool ascending = true,
  }) {
    final sortedList = List<MaintenanceIssue>.from(items);

    switch (criteria) {
      case MaintenanceSortCriteria.dateCreated:
        sortedList.sort(
          (a, b) =>
              ascending
                  ? a.createdAt.compareTo(b.createdAt)
                  : b.createdAt.compareTo(a.createdAt),
        );
        break;
      case MaintenanceSortCriteria.priority:
        sortedList.sort(
          (a, b) =>
              ascending
                  ? a.priority.index.compareTo(b.priority.index)
                  : b.priority.index.compareTo(a.priority.index),
        );
        break;
      case MaintenanceSortCriteria.status:
        sortedList.sort(
          (a, b) =>
              ascending
                  ? a.status.index.compareTo(b.status.index)
                  : b.status.index.compareTo(a.status.index),
        );
        break;
      case MaintenanceSortCriteria.title:
        sortedList.sort(
          (a, b) =>
              ascending
                  ? a.title.compareTo(b.title)
                  : b.title.compareTo(a.title),
        );
        break;
      case MaintenanceSortCriteria.cost:
        sortedList.sort((a, b) {
          final aCost = a.cost ?? 0.0;
          final bCost = b.cost ?? 0.0;
          return ascending ? aCost.compareTo(bCost) : bCost.compareTo(aCost);
        });
        break;
    }

    return sortedList;
  }

  /// Get maintenance statistics for all issues
  MaintenanceStats getMaintenanceStats() {
    return MaintenanceStats(
      totalIssues: totalIssues,
      completedIssues: completedIssuesCount,
      pendingIssues: pendingIssuesCount,
      inProgressIssues: inProgressIssuesCount,
      emergencyIssues: emergencyIssuesCount,
      totalCost: totalCost,
    );
  }

  /// Get maintenance statistics for a specific property
  MaintenanceStats getMaintenanceStatsForProperty(int propertyId) {
    final propertyIssues = getIssuesByProperty(propertyId);

    final completed =
        propertyIssues.where((i) => i.status == IssueStatus.completed).length;
    final pending =
        propertyIssues.where((i) => i.status == IssueStatus.pending).length;
    final inProgress =
        propertyIssues.where((i) => i.status == IssueStatus.inProgress).length;
    final emergency =
        propertyIssues
            .where((i) => i.priority == IssuePriority.emergency)
            .length;

    final cost = propertyIssues
        .where((issue) => issue.cost != null)
        .fold(0.0, (sum, issue) => sum + (issue.cost ?? 0.0));

    return MaintenanceStats(
      totalIssues: propertyIssues.length,
      completedIssues: completed,
      pendingIssues: pending,
      inProgressIssues: inProgress,
      emergencyIssues: emergency,
      totalCost: cost,
    );
  }
}

/// Enum for maintenance sorting criteria
enum MaintenanceSortCriteria { dateCreated, priority, status, title, cost }

/// Data class for maintenance statistics (moved here from repository for consistency)
class MaintenanceStats {
  final int totalIssues;
  final int completedIssues;
  final int pendingIssues;
  final int inProgressIssues;
  final int emergencyIssues;
  final double totalCost;

  const MaintenanceStats({
    required this.totalIssues,
    required this.completedIssues,
    required this.pendingIssues,
    required this.inProgressIssues,
    required this.emergencyIssues,
    required this.totalCost,
  });

  double get completionRate =>
      totalIssues > 0 ? completedIssues / totalIssues : 0.0;

  double get averageCostPerIssue =>
      totalIssues > 0 ? totalCost / totalIssues : 0.0;

  bool get hasEmergencyIssues => emergencyIssues > 0;

  bool get hasOutstandingIssues => pendingIssues > 0 || inProgressIssues > 0;
}
