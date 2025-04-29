import 'package:flutter/material.dart';
import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:e_rents_desktop/services/mock_data_service.dart';

class MaintenanceProvider extends BaseProvider<MaintenanceIssue> {
  final ApiService _apiService;
  bool _isLoading = false;
  String? _error;
  final bool _useMockData = true; // Flag to toggle between mock and real data

  MaintenanceProvider(this._apiService) : super(_apiService) {
    // Enable mock data for development
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
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch maintenance issues using the base provider's fetch method
  Future<void> fetchIssues() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await fetchItems();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addIssue(MaintenanceIssue issue) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await addItem(issue);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateIssue(MaintenanceIssue issue) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await updateItem(issue);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteIssue(String id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await deleteItem(id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Additional maintenance-specific methods
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

  Future<void> updateIssueStatus(String id, IssueStatus status) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final issue = items.firstWhere((i) => i.id == id);
      final updatedIssue = issue.copyWith(
        status: status,
        resolvedAt: status == IssueStatus.completed ? DateTime.now() : null,
      );
      await updateItem(updatedIssue);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
