import '../base/base.dart';
import '../models/maintenance_issue.dart';
import '../services/maintenance_service.dart';
import '../widgets/table/custom_table.dart';

/// Repository for managing maintenance issues with caching and business logic.
///
/// Provides CRUD operations and maintenance-specific filtering and statistics.
/// Uses 5-minute cache TTL for maintenance data which changes frequently.
class MaintenanceRepository
    extends BaseRepository<MaintenanceIssue, MaintenanceService> {
  MaintenanceRepository({required super.service, required super.cacheManager});

  @override
  String get resourceName => 'maintenance_issues';

  Duration get defaultCacheTTL => const Duration(minutes: 5);

  @override
  Future<List<MaintenanceIssue>> fetchAllFromService([
    Map<String, dynamic>? params,
  ]) async {
    // Convert map parameters to string parameters for MaintenanceService
    Map<String, String>? queryParams;
    if (params != null) {
      queryParams = params.map((key, value) => MapEntry(key, value.toString()));
    }
    return await service.getMaintenanceIssues(queryParams: queryParams);
  }

  @override
  Future<MaintenanceIssue> fetchByIdFromService(String id) async {
    return await service.getMaintenanceIssueById(id);
  }

  @override
  Future<MaintenanceIssue> createInService(MaintenanceIssue item) async {
    return await service.createMaintenanceIssue(item);
  }

  @override
  Future<MaintenanceIssue> updateInService(
    String id,
    MaintenanceIssue item,
  ) async {
    return await service.updateMaintenanceIssue(id, item);
  }

  @override
  Future<void> deleteInService(String id) async {
    await service.deleteMaintenanceIssue(id);
  }

  @override
  Future<bool> existsInService(String id) async {
    try {
      await service.getMaintenanceIssueById(id);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<int> countInService([Map<String, dynamic>? params]) async {
    final items = await fetchAllFromService(params);
    return items.length;
  }

  @override
  String? extractIdFromItem(MaintenanceIssue item) =>
      item.maintenanceIssueId.toString();

  // Business Logic Methods

  /// Get issues filtered by status
  Future<List<MaintenanceIssue>> getIssuesByStatus(IssueStatus status) async {
    final issues = await getAll();
    return issues.where((issue) => issue.status == status).toList();
  }

  /// Get issues filtered by priority
  Future<List<MaintenanceIssue>> getIssuesByPriority(
    IssuePriority priority,
  ) async {
    final issues = await getAll();
    return issues.where((issue) => issue.priority == priority).toList();
  }

  /// Get issues for a specific property
  Future<List<MaintenanceIssue>> getIssuesByProperty(int propertyId) async {
    final issues = await getAll();
    return issues.where((issue) => issue.propertyId == propertyId).toList();
  }

  /// Get pending issues (most common filter)
  Future<List<MaintenanceIssue>> getPendingIssues() async {
    return await getIssuesByStatus(IssueStatus.pending);
  }

  /// Get completed issues
  Future<List<MaintenanceIssue>> getCompletedIssues() async {
    return await getIssuesByStatus(IssueStatus.completed);
  }

  /// Get emergency issues requiring immediate attention
  Future<List<MaintenanceIssue>> getEmergencyIssues() async {
    return await getIssuesByPriority(IssuePriority.emergency);
  }

  /// Get high priority issues
  Future<List<MaintenanceIssue>> getHighPriorityIssues() async {
    return await getIssuesByPriority(IssuePriority.high);
  }

  /// Update issue status with additional data
  Future<MaintenanceIssue> updateIssueStatus(
    String issueId,
    IssueStatus newStatus, {
    String? resolutionNotes,
    double? cost,
  }) async {
    try {
      final updatedIssue = await service.updateMaintenanceIssueStatus(
        issueId,
        newStatus,
        resolutionNotes: resolutionNotes,
        cost: cost,
      );

      // Invalidate caches since status has changed
      await refreshItem(issueId);
      await clearCache();

      return updatedIssue;
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Get total maintenance cost for a property
  Future<double> getTotalMaintenanceCost(int propertyId) async {
    final issues = await getIssuesByProperty(propertyId);
    return issues
        .where((issue) => issue.cost != null)
        .fold<double>(0.0, (sum, issue) => sum + (issue.cost ?? 0.0));
  }

  /// Get maintenance statistics for a property
  Future<MaintenanceStats> getMaintenanceStats(int propertyId) async {
    final issues = await getIssuesByProperty(propertyId);

    final completed =
        issues.where((i) => i.status == IssueStatus.completed).length;
    final pending = issues.where((i) => i.status == IssueStatus.pending).length;
    final inProgress =
        issues.where((i) => i.status == IssueStatus.inProgress).length;
    final emergency =
        issues.where((i) => i.priority == IssuePriority.emergency).length;

    final totalCost = issues
        .where((issue) => issue.cost != null)
        .fold(0.0, (sum, issue) => sum + (issue.cost ?? 0.0));

    return MaintenanceStats(
      totalIssues: issues.length,
      completedIssues: completed,
      pendingIssues: pending,
      inProgressIssues: inProgress,
      emergencyIssues: emergency,
      totalCost: totalCost,
    );
  }

  /// Search issues by title or description
  Future<List<MaintenanceIssue>> searchIssues(String query) async {
    final issues = await getAll();
    final lowercaseQuery = query.toLowerCase();

    return issues
        .where(
          (issue) =>
              issue.title.toLowerCase().contains(lowercaseQuery) ||
              issue.description.toLowerCase().contains(lowercaseQuery) ||
              (issue.category?.toLowerCase().contains(lowercaseQuery) ?? false),
        )
        .toList();
  }

  /// Get recent issues (last 30 days)
  Future<List<MaintenanceIssue>> getRecentIssues() async {
    final issues = await getAll();
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    return issues
        .where((issue) => issue.createdAt.isAfter(thirtyDaysAgo))
        .toList();
  }

  /// ✅ UNIVERSAL TABLE: Get paginated maintenance issues from backend Universal System
  Future<PagedResult<MaintenanceIssue>> getPagedMaintenanceIssues(
    Map<String, dynamic> params,
  ) async {
    try {
      // For now, use the existing getAll method and implement local pagination
      // TODO: Update when backend supports Universal System pagination for maintenance
      final allIssues = await getAll();

      final page = (params['page'] ?? 1) - 1; // Convert to 0-based
      final pageSize = params['pageSize'] ?? 25;
      final searchTerm = params['searchTerm'] as String?;

      // Apply search filter
      List<MaintenanceIssue> filteredIssues = List.from(allIssues);
      if (searchTerm != null && searchTerm.isNotEmpty) {
        final lowercaseQuery = searchTerm.toLowerCase();
        filteredIssues =
            filteredIssues
                .where(
                  (issue) =>
                      issue.title.toLowerCase().contains(lowercaseQuery) ||
                      issue.description.toLowerCase().contains(
                        lowercaseQuery,
                      ) ||
                      (issue.category?.toLowerCase().contains(lowercaseQuery) ??
                          false),
                )
                .toList();
      }

      // Apply sorting
      final sortBy = params['sortBy'] as String?;
      final sortDesc = params['sortDesc'] as bool? ?? false;

      if (sortBy != null) {
        filteredIssues.sort((a, b) {
          int comparison = 0;
          switch (sortBy) {
            case 'priority':
              comparison = a.priority.index.compareTo(b.priority.index);
              break;
            case 'status':
              comparison = a.status.index.compareTo(b.status.index);
              break;
            case 'title':
              comparison = a.title.compareTo(b.title);
              break;
            case 'createdAt':
              comparison = a.createdAt.compareTo(b.createdAt);
              break;
            default:
              comparison = 0;
          }
          return sortDesc ? -comparison : comparison;
        });
      }

      // Apply pagination
      final totalCount = filteredIssues.length;
      final totalPages = (totalCount / pageSize).ceil();
      final startIndex = page * pageSize;
      final endIndex = (startIndex + pageSize).clamp(0, totalCount);

      final pageItems =
          startIndex < totalCount
              ? filteredIssues.sublist(startIndex, endIndex)
              : <MaintenanceIssue>[];

      return PagedResult<MaintenanceIssue>(
        items: pageItems,
        totalCount: totalCount,
        page: page,
        pageSize: pageSize,
        totalPages: totalPages,
      );
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }
}

/// Data class for maintenance statistics
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
}
