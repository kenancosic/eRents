import 'package:flutter/foundation.dart';
import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/base/api_service_extensions.dart';
import 'package:e_rents_mobile/core/models/maintenance_issue.dart';
import 'package:e_rents_mobile/core/providers/current_user_provider.dart';

/// Provider for managing maintenance issues (tenant-facing)
/// 
/// Features:
/// - View maintenance issues for current tenant's properties
/// - Report new maintenance issues
/// - Track issue status
class MaintenanceProvider extends BaseProvider {
  MaintenanceProvider(super.api);

  // ─── State ─────────────────────────────────────────────────────────────────
  List<MaintenanceIssue> _issues = [];
  MaintenanceIssue? _selectedIssue;

  // ─── Getters ───────────────────────────────────────────────────────────────
  
  List<MaintenanceIssue> get issues => _issues;
  MaintenanceIssue? get selectedIssue => _selectedIssue;
  bool get isEmpty => _issues.isEmpty;
  
  /// Get pending issues only
  List<MaintenanceIssue> get pendingIssues => 
      _issues.where((i) => !i.isResolved).toList();
  
  /// Get resolved issues only
  List<MaintenanceIssue> get resolvedIssues => 
      _issues.where((i) => i.isResolved).toList();
  
  /// Count of unresolved issues
  int get pendingCount => pendingIssues.length;

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Load maintenance issues for current user
  /// 
  /// For tenants: loads issues they reported
  /// Uses CurrentUserProvider to get user ID
  Future<void> loadIssues(CurrentUserProvider currentUserProvider) async {
    final issues = await executeWithState<List<MaintenanceIssue>?>(() async {
      final user = await currentUserProvider.ensureLoaded();
      if (user == null) throw Exception('User not authenticated');
      
      debugPrint('MaintenanceProvider: Loading issues for user ${user.userId}');
      
      // Load issues reported by current user
      final queryString = api.buildQueryString({
        'ReportedByUserId': user.userId.toString(),
        'SortBy': 'createdAt',
        'SortDirection': 'desc',
      });
      
      return await api.getListAndDecode(
        '/maintenanceissues$queryString',
        MaintenanceIssue.fromJson,
        authenticated: true,
      );
    });

    if (issues != null) {
      _issues = issues;
      debugPrint('MaintenanceProvider: Loaded ${issues.length} issues');
      notifyListeners();
    }
  }

  /// Load issues for a specific property
  Future<void> loadIssuesForProperty(int propertyId) async {
    final issues = await executeWithState<List<MaintenanceIssue>?>(() async {
      debugPrint('MaintenanceProvider: Loading issues for property $propertyId');
      
      final queryString = api.buildQueryString({
        'PropertyId': propertyId.toString(),
        'SortBy': 'createdAt',
        'SortDirection': 'desc',
      });
      
      return await api.getListAndDecode(
        '/maintenanceissues$queryString',
        MaintenanceIssue.fromJson,
        authenticated: true,
      );
    });

    if (issues != null) {
      _issues = issues;
      notifyListeners();
    }
  }

  /// Get a single issue by ID
  Future<MaintenanceIssue?> getIssue(int issueId) async {
    return await executeWithState<MaintenanceIssue?>(() async {
      debugPrint('MaintenanceProvider: Loading issue $issueId');
      return await api.getAndDecode(
        '/maintenanceissues/$issueId',
        MaintenanceIssue.fromJson,
        authenticated: true,
      );
    });
  }

  /// Report a new maintenance issue
  Future<MaintenanceIssue?> reportIssue({
    required int propertyId,
    required String title,
    required String description,
    required int priorityId,
    bool isTenantComplaint = true,
  }) async {
    final newIssue = await executeWithState<MaintenanceIssue?>(() async {
      debugPrint('MaintenanceProvider: Reporting new issue for property $propertyId');
      
      final request = {
        'propertyId': propertyId,
        'title': title,
        'description': description,
        'priorityId': priorityId,
        'isTenantComplaint': isTenantComplaint,
      };
      
      return await api.postAndDecode(
        '/maintenanceissues',
        request,
        MaintenanceIssue.fromJson,
        authenticated: true,
      );
    });

    if (newIssue != null) {
      _issues.insert(0, newIssue);
      notifyListeners();
      debugPrint('MaintenanceProvider: Issue reported successfully');
    }

    return newIssue;
  }

  /// Update an existing issue
  Future<bool> updateIssue(int issueId, Map<String, dynamic> updates) async {
    final success = await executeWithStateForSuccess(() async {
      debugPrint('MaintenanceProvider: Updating issue $issueId');
      await api.put('/maintenanceissues/$issueId', updates, authenticated: true);
      
      // Refresh the issue
      final updated = await getIssue(issueId);
      if (updated != null) {
        final index = _issues.indexWhere((i) => i.maintenanceIssueId == issueId);
        if (index != -1) {
          _issues[index] = updated;
        }
      }
    }, errorMessage: 'Failed to update maintenance issue');

    if (success) {
      notifyListeners();
    }

    return success;
  }

  /// Select an issue for detail view
  void selectIssue(MaintenanceIssue issue) {
    _selectedIssue = issue;
    notifyListeners();
  }

  /// Clear selection
  void clearSelection() {
    _selectedIssue = null;
    notifyListeners();
  }

  /// Clear all data on logout
  void clearOnLogout() {
    _issues = [];
    _selectedIssue = null;
    notifyListeners();
  }
}
