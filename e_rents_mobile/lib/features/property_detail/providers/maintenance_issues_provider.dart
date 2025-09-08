import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/enums/maintenance_issue_enums.dart';
import 'package:e_rents_mobile/core/models/maintenance_issue.dart';
import 'package:e_rents_mobile/core/base/api_service_extensions.dart';

/// Provider for managing maintenance issues
/// Handles maintenance issues reporting and tracking for properties
class MaintenanceIssuesProvider extends BaseProvider {
  MaintenanceIssuesProvider(super.api);

  // ─── State ──────────────────────────────────────────────────────────────
  List<MaintenanceIssue> _maintenanceIssues = [];
  List<MaintenanceIssue> _allMaintenanceIssues = [];
  
  // Maintenance search/filter state
  String _maintenanceSearchQuery = '';
  Map<String, dynamic> _maintenanceFilters = {};

  // ─── Getters ────────────────────────────────────────────────────────────
  List<MaintenanceIssue> get maintenanceIssues => _maintenanceIssues;
  List<MaintenanceIssue> get allMaintenanceIssues => _allMaintenanceIssues;
  String get maintenanceSearchQuery => _maintenanceSearchQuery;
  Map<String, dynamic> get maintenanceFilters => _maintenanceFilters;

  // ─── Public API ─────────────────────────────────────────────────────────
  
  /// Fetch maintenance issues for a property
  Future<void> fetchMaintenanceIssues(int propertyId) async {
    final issues = await executeWithState(() async {
      final qs = api.buildQueryString({'PropertyId': propertyId.toString()});
      return await api.getListAndDecode('/maintenanceissues$qs', MaintenanceIssue.fromJson, authenticated: true);
    });

    if (issues != null) {
      _allMaintenanceIssues = issues;
      _maintenanceIssues = List.from(_allMaintenanceIssues);
      _applyMaintenanceSearchAndFilters();
    }
  }

  /// Report a new maintenance issue
  Future<bool> reportMaintenanceIssue(int propertyId, String title, String description) async {
    final success = await executeWithStateForSuccess(() async {
      final newIssue = await api.postAndDecode('/maintenanceissues', 
        {
          'propertyId': propertyId,
          'title': title,
          'description': description,
          // Mark as tenant-originated; backend may still require ReportedByUserId
          'isTenantComplaint': true,
        }, 
        MaintenanceIssue.fromJson, authenticated: true);
      _allMaintenanceIssues.insert(0, newIssue);
      _applyMaintenanceSearchAndFilters();
    }, errorMessage: 'Failed to report issue');

    return success;
  }

  /// Update maintenance issue status
  Future<bool> updateMaintenanceIssueStatus(String issueId, MaintenanceIssueStatus newStatus) async {
    final success = await executeWithStateForSuccess(() async {
      final updatedIssue = await api.putAndDecode('/maintenanceissues/$issueId', {
        'status': newStatus.toString().split('.').last,
        'statusId': _getStatusId(newStatus),
      }, MaintenanceIssue.fromJson, authenticated: true);
      
      final index = _allMaintenanceIssues.indexWhere((issue) => issue.maintenanceIssueId.toString() == issueId);
      if (index != -1) {
        _allMaintenanceIssues[index] = updatedIssue;
        _applyMaintenanceSearchAndFilters();
      }
    }, errorMessage: 'Failed to update maintenance issue');

    return success;
  }

  int _getStatusId(MaintenanceIssueStatus status) {
    switch (status) {
      case MaintenanceIssueStatus.pending:
        return 1;
      case MaintenanceIssueStatus.inProgress:
        return 2;
      case MaintenanceIssueStatus.completed:
        return 3;
      case MaintenanceIssueStatus.cancelled:
        return 4;
    }
  }

  /// Search maintenance issues
  void searchMaintenanceIssues(String query) {
    _maintenanceSearchQuery = query;
    _applyMaintenanceSearchAndFilters();
  }

  /// Apply filters to maintenance issues
  void applyMaintenanceFilters(Map<String, dynamic> filters) {
    _maintenanceFilters = Map.from(filters);
    _applyMaintenanceSearchAndFilters();
  }

  /// Clear maintenance search and filters
  void clearMaintenanceSearchAndFilters() {
    _maintenanceSearchQuery = '';
    _maintenanceFilters.clear();
    _maintenanceIssues = List.from(_allMaintenanceIssues);
    notifyListeners();
  }

  void _applyMaintenanceSearchAndFilters() {
    _maintenanceIssues = _allMaintenanceIssues.where((issue) {
      // Apply search filter
      if (_maintenanceSearchQuery.isNotEmpty) {
        final query = _maintenanceSearchQuery.toLowerCase();
        if (!issue.title.toLowerCase().contains(query) &&
            !issue.description.toLowerCase().contains(query) &&
            !(issue.category?.toLowerCase().contains(query) ?? false)) {
          return false;
        }
      }

      // Apply other filters
      return _matchesMaintenanceFilters(issue, _maintenanceFilters);
    }).toList();
    
    notifyListeners();
  }

  bool _matchesMaintenanceFilters(MaintenanceIssue issue, Map<String, dynamic> filters) {
    // Status filter
    if (filters.containsKey('status')) {
      final status = filters['status'] as MaintenanceIssueStatus?;
      if (status != null && issue.status != status) return false;
    }

    // Priority filter
    if (filters.containsKey('priority')) {
      final priority = filters['priority'] as MaintenanceIssuePriority?;
      if (priority != null && issue.priority != priority) return false;
    }

    // Category filter
    if (filters.containsKey('category')) {
      final category = filters['category'] as String?;
      if (category != null && issue.category != category) return false;
    }

    return true;
  }
}
