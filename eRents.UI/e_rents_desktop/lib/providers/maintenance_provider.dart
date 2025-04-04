import 'package:flutter/material.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:e_rents_desktop/services/mock_data_service.dart';
import 'dart:convert';

class MaintenanceProvider extends ChangeNotifier {
  final ApiService _apiService;
  List<MaintenanceIssue> _issues = [];
  bool _isLoading = false;
  String? _error;
  bool _useMockData = true; // Flag to toggle between mock and real data

  MaintenanceProvider(this._apiService);

  List<MaintenanceIssue> get issues => _issues;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get issues for a specific property
  List<MaintenanceIssue> getIssuesForProperty(String propertyId) {
    return _issues.where((issue) => issue.propertyId == propertyId).toList();
  }

  // Get issues by status
  List<MaintenanceIssue> getIssuesByStatus(IssueStatus status) {
    return _issues.where((issue) => issue.status == status).toList();
  }

  // Get issues by priority
  List<MaintenanceIssue> getIssuesByPriority(IssuePriority priority) {
    return _issues.where((issue) => issue.priority == priority).toList();
  }

  // Get tenant complaints
  List<MaintenanceIssue> getTenantComplaints() {
    return _issues.where((issue) => issue.isTenantComplaint).toList();
  }

  Future<void> fetchIssues() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_useMockData) {
        // Simulate network delay
        await Future.delayed(const Duration(seconds: 1));
        _issues = MockDataService.getMockMaintenanceIssues();
      } else {
        final response = await _apiService.get('/maintenance-issues');
        _issues =
            (json.decode(response.body) as List)
                .map((json) => MaintenanceIssue.fromJson(json))
                .toList();
      }
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

      if (_useMockData) {
        // Simulate network delay
        await Future.delayed(const Duration(seconds: 1));
        _issues.add(issue);
      } else {
        final response = await _apiService.post(
          '/maintenance-issues',
          issue.toJson(),
        );
        _issues.add(MaintenanceIssue.fromJson(json.decode(response.body)));
      }
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

      if (_useMockData) {
        // Simulate network delay
        await Future.delayed(const Duration(seconds: 1));
        final index = _issues.indexWhere((i) => i.id == issue.id);
        if (index != -1) {
          _issues[index] = issue;
        }
      } else {
        await _apiService.put(
          '/maintenance-issues/${issue.id}',
          issue.toJson(),
        );
        final index = _issues.indexWhere((i) => i.id == issue.id);
        if (index != -1) {
          _issues[index] = issue;
        }
      }
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

      if (_useMockData) {
        // Simulate network delay
        await Future.delayed(const Duration(seconds: 1));
        _issues.removeWhere((issue) => issue.id == id);
      } else {
        await _apiService.delete('/maintenance-issues/$id');
        _issues.removeWhere((issue) => issue.id == id);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
