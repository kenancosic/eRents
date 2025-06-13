import "package:e_rents_mobile/core/base/base_repository.dart";
import "package:e_rents_mobile/core/models/maintenance_issue.dart";
import "package:e_rents_mobile/core/services/maintenance_service.dart";
import "package:e_rents_mobile/core/services/cache_manager.dart";

/// Concrete repository for MaintenanceIssue entities
/// Implements BaseRepository pattern with MaintenanceIssue-specific logic and full CRUD operations
class MaintenanceRepository
    extends BaseRepository<MaintenanceIssue, MaintenanceService> {
  MaintenanceRepository({
    required MaintenanceService service,
    required CacheManager cacheManager,
  }) : super(service: service, cacheManager: cacheManager);

  @override
  String get resourceName => "maintenance";

  @override
  Duration get cacheTtl =>
      const Duration(minutes: 10); // Maintenance issues change frequently

  @override
  Future<MaintenanceIssue?> fetchFromService(String id) async {
    final issueId = int.tryParse(id);
    if (issueId == null) {
      throw ArgumentError("Invalid maintenance issue ID: $id");
    }
    return await service.getMaintenanceIssueById(issueId);
  }

  @override
  Future<List<MaintenanceIssue>> fetchAllFromService(
      [Map<String, dynamic>? params]) async {
    return await service.getMaintenanceIssues(params);
  }

  @override
  Future<MaintenanceIssue> createInService(MaintenanceIssue item) async {
    return await service.createMaintenanceIssue(item);
  }

  @override
  Future<MaintenanceIssue> updateInService(
      String id, MaintenanceIssue item) async {
    final issueId = int.tryParse(id);
    if (issueId == null) {
      throw ArgumentError("Invalid maintenance issue ID: $id");
    }
    return await service.updateMaintenanceIssue(issueId, item);
  }

  @override
  Future<bool> deleteInService(String id) async {
    final issueId = int.tryParse(id);
    if (issueId == null) {
      throw ArgumentError("Invalid maintenance issue ID: $id");
    }
    return await service.deleteMaintenanceIssue(issueId);
  }

  @override
  Map<String, dynamic> toJson(MaintenanceIssue item) {
    return item.toJson();
  }

  @override
  MaintenanceIssue fromJson(Map<String, dynamic> json) {
    return MaintenanceIssue.fromJson(json);
  }

  @override
  String getItemId(MaintenanceIssue item) {
    return item.maintenanceIssueId.toString();
  }

  // MaintenanceIssue-specific methods with backend universal filtering support

  /// Search maintenance issues with filters compatible with backend universal filtering
  Future<List<MaintenanceIssue>> searchMaintenanceIssues({
    int? propertyId,
    int? reportedByUserId,
    int? assignedToUserId,
    int? priorityId,
    int? statusId,
    String? category,
    bool? requiresInspection,
    bool? isTenantComplaint,
    double? minCost,
    double? maxCost,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final searchParams = <String, dynamic>{};

    // Add non-null parameters for backend universal filtering
    if (propertyId != null) searchParams['propertyId'] = propertyId;
    if (reportedByUserId != null)
      searchParams['reportedByUserId'] = reportedByUserId;
    if (assignedToUserId != null)
      searchParams['assignedToUserId'] = assignedToUserId;
    if (priorityId != null) searchParams['priorityId'] = priorityId;
    if (statusId != null) searchParams['statusId'] = statusId;
    if (category != null) searchParams['category'] = category;
    if (requiresInspection != null)
      searchParams['requiresInspection'] = requiresInspection;
    if (isTenantComplaint != null)
      searchParams['isTenantComplaint'] = isTenantComplaint;

    // Range filtering for cost
    if (minCost != null) searchParams['minCost'] = minCost;
    if (maxCost != null) searchParams['maxCost'] = maxCost;

    // Date range filtering
    if (fromDate != null) searchParams['fromDate'] = fromDate.toIso8601String();
    if (toDate != null) searchParams['toDate'] = toDate.toIso8601String();

    return await getAll(searchParams);
  }

  /// Get maintenance issues for a specific property
  Future<List<MaintenanceIssue>> getPropertyMaintenanceIssues(
      int propertyId) async {
    return await searchMaintenanceIssues(propertyId: propertyId);
  }

  /// Get maintenance issues reported by a specific user
  Future<List<MaintenanceIssue>> getMaintenanceIssuesByReporter(
      int userId) async {
    return await searchMaintenanceIssues(reportedByUserId: userId);
  }

  /// Get maintenance issues assigned to a specific user
  Future<List<MaintenanceIssue>> getMaintenanceIssuesByAssignee(
      int userId) async {
    return await searchMaintenanceIssues(assignedToUserId: userId);
  }

  /// Get maintenance issues by priority
  Future<List<MaintenanceIssue>> getMaintenanceIssuesByPriority(
      int priorityId) async {
    return await searchMaintenanceIssues(priorityId: priorityId);
  }

  /// Get maintenance issues by status
  Future<List<MaintenanceIssue>> getMaintenanceIssuesByStatus(
      int statusId) async {
    return await searchMaintenanceIssues(statusId: statusId);
  }

  /// Get emergency maintenance issues
  Future<List<MaintenanceIssue>> getEmergencyMaintenanceIssues() async {
    return await searchMaintenanceIssues(priorityId: 4); // Emergency priority
  }

  /// Get pending maintenance issues
  Future<List<MaintenanceIssue>> getPendingMaintenanceIssues() async {
    return await searchMaintenanceIssues(statusId: 1); // Pending status
  }

  /// Get maintenance issues by category
  Future<List<MaintenanceIssue>> getMaintenanceIssuesByCategory(
      String category) async {
    return await searchMaintenanceIssues(category: category);
  }

  /// Get tenant complaints only
  Future<List<MaintenanceIssue>> getTenantComplaints() async {
    return await searchMaintenanceIssues(isTenantComplaint: true);
  }

  /// Get maintenance issues requiring inspection
  Future<List<MaintenanceIssue>>
      getMaintenanceIssuesRequiringInspection() async {
    return await searchMaintenanceIssues(requiresInspection: true);
  }

  /// Get maintenance issues within cost range
  Future<List<MaintenanceIssue>> getMaintenanceIssuesByCostRange(
      double minCost, double maxCost) async {
    return await searchMaintenanceIssues(
      minCost: minCost,
      maxCost: maxCost,
    );
  }
}

/// Search object for MaintenanceIssue filtering - matches backend SearchObject exactly
class MaintenanceIssueSearchObject {
  // Direct entity field matches (automatic filtering)
  final int? propertyId;
  final int? reportedByUserId;
  final int? assignedToUserId;
  final int? priorityId;
  final int? statusId;
  final String? category;
  final bool? requiresInspection;
  final bool? isTenantComplaint;

  // Range filtering (Min/Max pairs)
  final double? minCost;
  final double? maxCost;
  final DateTime? fromDate; // → createdAt >=
  final DateTime? toDate; // → createdAt <=

  // Pagination and sorting (standard fields)
  final int? page;
  final int? pageSize;
  final String? sortBy;
  final String? sortDirection;

  MaintenanceIssueSearchObject({
    this.propertyId,
    this.reportedByUserId,
    this.assignedToUserId,
    this.priorityId,
    this.statusId,
    this.category,
    this.requiresInspection,
    this.isTenantComplaint,
    this.minCost,
    this.maxCost,
    this.fromDate,
    this.toDate,
    this.page,
    this.pageSize,
    this.sortBy,
    this.sortDirection,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (propertyId != null) json['propertyId'] = propertyId;
    if (reportedByUserId != null) json['reportedByUserId'] = reportedByUserId;
    if (assignedToUserId != null) json['assignedToUserId'] = assignedToUserId;
    if (priorityId != null) json['priorityId'] = priorityId;
    if (statusId != null) json['statusId'] = statusId;
    if (category != null) json['category'] = category;
    if (requiresInspection != null)
      json['requiresInspection'] = requiresInspection;
    if (isTenantComplaint != null)
      json['isTenantComplaint'] = isTenantComplaint;
    if (minCost != null) json['minCost'] = minCost;
    if (maxCost != null) json['maxCost'] = maxCost;
    if (fromDate != null) json['fromDate'] = fromDate!.toIso8601String();
    if (toDate != null) json['toDate'] = toDate!.toIso8601String();
    if (page != null) json['page'] = page! + 1; // Convert 0-based to 1-based
    if (pageSize != null) json['pageSize'] = pageSize;
    if (sortBy != null) json['sortBy'] = sortBy;
    if (sortDirection != null) json['sortDirection'] = sortDirection;

    return json;
  }
}
