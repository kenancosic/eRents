import 'package:flutter/material.dart';
import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/services/maintenance_service.dart';
import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:e_rents_desktop/services/mock_data_service.dart';

class MaintenanceProvider extends BaseProvider<MaintenanceIssue> {
  final MaintenanceService _maintenanceService;

  MaintenanceProvider(this._maintenanceService) : super(_maintenanceService) {
    enableMockData();
  }

  @override
  String get endpoint => '/maintenance';

  @override
  MaintenanceIssue fromJson(Map<String, dynamic> json) =>
      MaintenanceIssue.fromJson(json);

  @override
  Map<String, dynamic> toJson(MaintenanceIssue item) => item.toJson();

  @override
  List<MaintenanceIssue> getMockItems() =>
      MockDataService.getMockMaintenanceIssues();

  List<MaintenanceIssue> get issues => items;

  Future<void> fetchIssues({Map<String, String>? queryParams}) async {
    await execute(() async {
      if (isMockDataEnabled) {
        items_ = getMockItems();
      } else {
        items_ = await _maintenanceService.getIssues(queryParams: queryParams);
      }
    });
  }

  Future<void> addIssue(MaintenanceIssue issue) async {
    await execute(() async {
      if (isMockDataEnabled) {
        items_.add(
          issue.copyWith(id: DateTime.now().millisecondsSinceEpoch.toString()),
        );
      } else {
        final newItem = await _maintenanceService.createIssue(issue);
        items_.add(newItem);
      }
    });
  }

  Future<void> updateIssue(MaintenanceIssue issue) async {
    await execute(() async {
      if (isMockDataEnabled) {
        final index = items.indexWhere((i) => i.id == issue.id);
        if (index != -1) items_[index] = issue;
      } else {
        final updatedItem = await _maintenanceService.updateIssue(
          issue.id,
          issue,
        );
        final index = items.indexWhere((i) => i.id == updatedItem.id);
        if (index != -1) items_[index] = updatedItem;
      }
    });
  }

  Future<void> deleteIssue(String id) async {
    await execute(() async {
      if (isMockDataEnabled) {
        items_.removeWhere((issue) => issue.id == id);
      } else {
        await _maintenanceService.deleteIssue(id);
        items_.removeWhere((issue) => issue.id == id);
      }
    });
  }

  List<MaintenanceIssue> getIssuesByProperty(String propertyId) {
    return items.where((issue) => issue.propertyId == propertyId).toList();
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
      MaintenanceIssue updatedIssue;
      if (isMockDataEnabled) {
        final index = items.indexWhere((i) => i.id == id);
        if (index != -1) {
          updatedIssue = items[index].copyWith(
            status: status,
            resolvedAt:
                status == IssueStatus.completed
                    ? DateTime.now()
                    : items[index].resolvedAt,
            cost: cost ?? items[index].cost,
            resolutionNotes: resolutionNotes ?? items[index].resolutionNotes,
          );
          items_[index] = updatedIssue;
        } else {
          throw Exception("Mock issue not found for status update");
        }
      } else {
        updatedIssue = await _maintenanceService.updateIssueStatus(
          id,
          status,
          resolutionNotes: resolutionNotes,
          cost: cost,
        );
        final index = items.indexWhere((i) => i.id == updatedIssue.id);
        if (index != -1)
          items_[index] = updatedIssue;
        else
          items_.add(updatedIssue);
      }
    });
  }
}
