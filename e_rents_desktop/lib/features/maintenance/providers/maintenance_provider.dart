import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/services/maintenance_service.dart';
import 'package:e_rents_desktop/models/maintenance_issue.dart';

class MaintenanceProvider extends BaseProvider<MaintenanceIssue> {
  final MaintenanceService _maintenanceService;

  MaintenanceProvider(this._maintenanceService) : super(_maintenanceService);

  @override
  String get endpoint => '/maintenance';

  @override
  MaintenanceIssue fromJson(Map<String, dynamic> json) =>
      MaintenanceIssue.fromJson(json);

  @override
  Map<String, dynamic> toJson(MaintenanceIssue item) => item.toJson();

  @override
  List<MaintenanceIssue> getMockItems() => []; // Not using mock data

  List<MaintenanceIssue> get issues => items;

  Future<void> fetchIssues({Map<String, String>? queryParams}) async {
    await execute(() async {
      items_ = await _maintenanceService.getIssues(queryParams: queryParams);
    });
  }

  Future<void> addIssue(MaintenanceIssue issue) async {
    await execute(() async {
      final newIssue = await _maintenanceService.createIssue(issue);
      items_.add(newIssue);

      // Update the provider to notify listeners so the UI can refresh with the new issue ID
      notifyListeners();
    });
  }

  Future<void> updateIssue(MaintenanceIssue issue) async {
    await execute(() async {
      final updatedIssue = await _maintenanceService.updateIssue(
        issue.id.toString(),
        issue,
      );
      final index = items.indexWhere((i) => i.id == updatedIssue.id);
      if (index != -1) {
        items_[index] = updatedIssue;
      }
    });
  }

  Future<void> deleteIssue(String id) async {
    await execute(() async {
      await _maintenanceService.deleteIssue(id);
      final idInt = int.tryParse(id);
      if (idInt != null) {
        items_.removeWhere((issue) => issue.id == idInt);
      }
    });
  }

  List<MaintenanceIssue> getIssuesByProperty(String propertyId) {
    final propertyIdInt = int.tryParse(propertyId);
    if (propertyIdInt == null) return [];
    return items.where((issue) => issue.propertyId == propertyIdInt).toList();
  }

  List<MaintenanceIssue> getIssuesByStatus(IssueStatus status) {
    return items.where((issue) => issue.status == status).toList();
  }

  List<MaintenanceIssue> getIssuesByPriority(IssuePriority priority) {
    return items.where((issue) => issue.priority == priority).toList();
  }

  List<MaintenanceIssue> getTenantComplaints() {
    return items.where((issue) => issue.isTenantComplaint).toList();
  }

  Future<void> updateIssueStatus(
    String id,
    IssueStatus status, {
    double? cost,
    String? resolutionNotes,
  }) async {
    await execute(() async {
      final updatedIssue = await _maintenanceService.updateIssueStatus(
        id,
        status,
        resolutionNotes: resolutionNotes,
        cost: cost,
      );
      final index = items.indexWhere((i) => i.id == updatedIssue.id);
      if (index != -1) {
        items_[index] = updatedIssue;
      } else {
        items_.add(updatedIssue);
      }
    });
  }

  // Additional utility methods for better data management
  int get totalIssues => items.length;

  int get pendingIssuesCount =>
      items.where((i) => i.status == IssueStatus.pending).length;

  int get inProgressIssuesCount =>
      items.where((i) => i.status == IssueStatus.inProgress).length;

  int get completedIssuesCount =>
      items.where((i) => i.status == IssueStatus.completed).length;

  int get highPriorityIssuesCount =>
      items
          .where(
            (i) =>
                i.priority == IssuePriority.high ||
                i.priority == IssuePriority.emergency,
          )
          .length;

  // Filter issues by multiple criteria
  List<MaintenanceIssue> filterIssues({
    IssueStatus? status,
    IssuePriority? priority,
    String? propertyId,
    bool? isTenantComplaint,
    String? searchQuery,
  }) {
    final propertyIdInt = propertyId != null ? int.tryParse(propertyId) : null;

    return items.where((issue) {
      bool matchesStatus = status == null || issue.status == status;
      bool matchesPriority = priority == null || issue.priority == priority;
      bool matchesProperty =
          propertyIdInt == null || issue.propertyId == propertyIdInt;
      bool matchesComplaint =
          isTenantComplaint == null ||
          issue.isTenantComplaint == isTenantComplaint;
      bool matchesSearch =
          searchQuery == null ||
          searchQuery.isEmpty ||
          issue.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          issue.description.toLowerCase().contains(searchQuery.toLowerCase());

      return matchesStatus &&
          matchesPriority &&
          matchesProperty &&
          matchesComplaint &&
          matchesSearch;
    }).toList();
  }
}
