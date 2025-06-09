import 'package:flutter/foundation.dart';
import 'package:e_rents_mobile/core/base/collection_provider.dart';
import 'package:e_rents_mobile/core/repositories/maintenance_repository.dart';
import 'package:e_rents_mobile/core/models/maintenance_issue.dart';

/// Concrete collection provider for MaintenanceIssue entities
/// Manages maintenance issues with automatic caching, search, and filtering
class MaintenanceCollectionProvider
    extends CollectionProvider<MaintenanceIssue> {
  MaintenanceCollectionProvider(MaintenanceRepository super.repository);

  // Get the maintenance repository with proper typing
  MaintenanceRepository get maintenanceRepository =>
      repository as MaintenanceRepository;

  // Convenience getters for different issue types
  List<MaintenanceIssue> get pendingIssues {
    return items
        .where((issue) => issue.status == MaintenanceIssueStatus.pending)
        .toList();
  }

  List<MaintenanceIssue> get inProgressIssues {
    return items
        .where((issue) => issue.status == MaintenanceIssueStatus.inProgress)
        .toList();
  }

  List<MaintenanceIssue> get completedIssues {
    return items
        .where((issue) => issue.status == MaintenanceIssueStatus.completed)
        .toList();
  }

  List<MaintenanceIssue> get cancelledIssues {
    return items
        .where((issue) => issue.status == MaintenanceIssueStatus.cancelled)
        .toList();
  }

  List<MaintenanceIssue> get urgentIssues {
    return items
        .where((issue) => issue.priority == MaintenanceIssuePriority.emergency)
        .toList();
  }

  List<MaintenanceIssue> get tenantComplaints {
    return items.where((issue) => issue.isTenantComplaint == true).toList();
  }

  List<MaintenanceIssue> get inspectionRequired {
    return items.where((issue) => issue.requiresInspection == true).toList();
  }

  @override
  bool matchesSearch(MaintenanceIssue item, String query) {
    final lowerQuery = query.toLowerCase();
    return item.title.toLowerCase().contains(lowerQuery) ||
        item.description.toLowerCase().contains(lowerQuery) ||
        (item.category?.toLowerCase().contains(lowerQuery) ?? false) ||
        (item.resolutionNotes?.toLowerCase().contains(lowerQuery) ?? false) ||
        item.priority.name.toLowerCase().contains(lowerQuery) ||
        item.status.name.toLowerCase().contains(lowerQuery);
  }

  @override
  bool matchesFilters(MaintenanceIssue item, Map<String, dynamic> filters) {
    // Status filter
    if (filters.containsKey('status')) {
      final statusFilter = filters['status'] as String?;
      if (statusFilter != null && item.status.name != statusFilter) {
        return false;
      }
    }

    // Priority filter
    if (filters.containsKey('priority')) {
      final priorityFilter = filters['priority'] as String?;
      if (priorityFilter != null && item.priority.name != priorityFilter) {
        return false;
      }
    }

    // Property filter
    if (filters.containsKey('propertyId')) {
      final propertyId = filters['propertyId'] as int?;
      if (propertyId != null && item.propertyId != propertyId) {
        return false;
      }
    }

    // Reported by user filter
    if (filters.containsKey('reportedByUserId')) {
      final reportedByUserId = filters['reportedByUserId'] as int?;
      if (reportedByUserId != null &&
          item.reportedByUserId != reportedByUserId) {
        return false;
      }
    }

    // Assigned to user filter
    if (filters.containsKey('assignedToUserId')) {
      final assignedToUserId = filters['assignedToUserId'] as int?;
      if (assignedToUserId != null &&
          item.assignedToUserId != assignedToUserId) {
        return false;
      }
    }

    // Category filter
    if (filters.containsKey('category')) {
      final category = filters['category'] as String?;
      if (category != null && item.category != category) {
        return false;
      }
    }

    // Cost range filter
    if (filters.containsKey('minCost')) {
      final minCost = filters['minCost'] as double?;
      if (minCost != null && (item.cost ?? 0) < minCost) {
        return false;
      }
    }

    if (filters.containsKey('maxCost')) {
      final maxCost = filters['maxCost'] as double?;
      if (maxCost != null && (item.cost ?? 0) > maxCost) {
        return false;
      }
    }

    // Date range filters
    if (filters.containsKey('fromDate')) {
      final fromDate = filters['fromDate'] as DateTime?;
      if (fromDate != null && item.createdAt.isBefore(fromDate)) {
        return false;
      }
    }

    if (filters.containsKey('toDate')) {
      final toDate = filters['toDate'] as DateTime?;
      if (toDate != null && item.createdAt.isAfter(toDate)) {
        return false;
      }
    }

    // Requires inspection filter
    if (filters.containsKey('requiresInspection')) {
      final requiresInspection = filters['requiresInspection'] as bool?;
      if (requiresInspection != null &&
          item.requiresInspection != requiresInspection) {
        return false;
      }
    }

    // Is tenant complaint filter
    if (filters.containsKey('isTenantComplaint')) {
      final isTenantComplaint = filters['isTenantComplaint'] as bool?;
      if (isTenantComplaint != null &&
          item.isTenantComplaint != isTenantComplaint) {
        return false;
      }
    }

    return true;
  }

  // Maintenance-specific convenience methods

  /// Load maintenance issues for a specific property
  Future<void> loadPropertyIssues(int propertyId,
      {bool forceRefresh = false}) async {
    await loadItems({'propertyId': propertyId});
  }

  /// Load maintenance issues reported by a specific user
  Future<void> loadIssuesReportedBy(int userId,
      {bool forceRefresh = false}) async {
    await loadItems({'reportedByUserId': userId});
  }

  /// Load maintenance issues assigned to a specific user
  Future<void> loadIssuesAssignedTo(int userId,
      {bool forceRefresh = false}) async {
    await loadItems({'assignedToUserId': userId});
  }

  /// Create a new maintenance issue
  Future<void> createMaintenanceIssue({
    required int propertyId,
    required String title,
    required String description,
    required int reportedByUserId,
    MaintenanceIssuePriority priority = MaintenanceIssuePriority.medium,
    String? category,
    bool? requiresInspection,
    bool? isTenantComplaint,
  }) async {
    await execute(() async {
      debugPrint(
          'MaintenanceCollectionProvider: Creating new maintenance issue');

      final issue = MaintenanceIssue(
        propertyId: propertyId,
        title: title,
        description: description,
        reportedByUserId: reportedByUserId,
        priority: priority,
        category: category,
        requiresInspection: requiresInspection,
        isTenantComplaint: isTenantComplaint,
        createdAt: DateTime.now(),
      );

      final createdIssue = await repository.create(issue);

      // Add to local collection and refresh search/filters
      allItems.add(createdIssue);
      searchItems(
          searchQuery); // This triggers _applySearchAndFilters internally

      debugPrint(
          'MaintenanceCollectionProvider: Maintenance issue created successfully');
    });
  }

  /// Update maintenance issue status
  Future<void> updateIssueStatus(
      String issueId, MaintenanceIssueStatus newStatus) async {
    await execute(() async {
      debugPrint('MaintenanceCollectionProvider: Updating issue status');

      final issueIndex = allItems
          .indexWhere((issue) => repository.getItemId(issue) == issueId);

      if (issueIndex != -1) {
        final updatedIssue = allItems[issueIndex].copyWith(
          status: newStatus,
          resolvedAt: newStatus == MaintenanceIssueStatus.completed
              ? DateTime.now()
              : null,
        );

        final result = await repository.update(issueId, updatedIssue);
        allItems[issueIndex] = result;
        searchItems(searchQuery); // Refresh search/filters

        debugPrint(
            'MaintenanceCollectionProvider: Issue status updated successfully');
      }
    });
  }

  /// Assign maintenance issue to a user
  Future<void> assignIssue(String issueId, int assignedToUserId) async {
    await execute(() async {
      debugPrint('MaintenanceCollectionProvider: Assigning issue');

      final issueIndex = allItems
          .indexWhere((issue) => repository.getItemId(issue) == issueId);

      if (issueIndex != -1) {
        final updatedIssue = allItems[issueIndex].copyWith(
          assignedToUserId: assignedToUserId,
          status: MaintenanceIssueStatus.inProgress,
        );

        final result = await repository.update(issueId, updatedIssue);
        allItems[issueIndex] = result;
        searchItems(searchQuery); // Refresh search/filters

        debugPrint(
            'MaintenanceCollectionProvider: Issue assigned successfully');
      }
    });
  }

  /// Filter issues by status
  void filterByStatus(MaintenanceIssueStatus status) {
    applyFilters({'status': status.name});
  }

  /// Filter issues by priority
  void filterByPriority(MaintenanceIssuePriority priority) {
    applyFilters({'priority': priority.name});
  }

  /// Filter issues by property
  void filterByProperty(int propertyId) {
    applyFilters({'propertyId': propertyId});
  }

  /// Filter issues by category
  void filterByCategory(String category) {
    applyFilters({'category': category});
  }

  /// Filter issues by date range
  void filterByDateRange(DateTime? fromDate, DateTime? toDate) {
    final filters = <String, dynamic>{};
    if (fromDate != null) filters['fromDate'] = fromDate;
    if (toDate != null) filters['toDate'] = toDate;
    applyFilters(filters);
  }

  /// Get total cost of filtered issues
  double get totalCost {
    return items
        .where((issue) => issue.cost != null)
        .fold(0.0, (sum, issue) => sum + (issue.cost ?? 0));
  }

  /// Get issue statistics
  Map<String, int> get statusStatistics {
    final stats = <String, int>{};
    for (final issue in items) {
      final statusName = issue.status.name;
      stats[statusName] = (stats[statusName] ?? 0) + 1;
    }
    return stats;
  }

  /// Get priority statistics
  Map<String, int> get priorityStatistics {
    final stats = <String, int>{};
    for (final issue in items) {
      final priorityName = issue.priority.name;
      stats[priorityName] = (stats[priorityName] ?? 0) + 1;
    }
    return stats;
  }
}
