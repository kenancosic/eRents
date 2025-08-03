import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/base/api_service_extensions.dart';
import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:e_rents_desktop/models/paged_result.dart';
import 'package:e_rents_desktop/widgets/table/table_config.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MaintenanceProvider extends BaseProvider {
  final BuildContext? context;

  MaintenanceProvider(super.api, {this.context});

  // ─── State ──────────────────────────────────────────────────────────────
  List<MaintenanceIssue> _issues = [];
  List<MaintenanceIssue> get issues => _issues;

  MaintenanceIssue? _selectedIssue;
  MaintenanceIssue? get selectedIssue => _selectedIssue;

  PagedResult<MaintenanceIssue> _pagedResult = PagedResult.empty();
  PagedResult<MaintenanceIssue> get pagedResult => _pagedResult;

  // Status update state
  MaintenanceIssue? _editingIssue;
  MaintenanceIssue? get editingIssue => _editingIssue;

  IssueStatus? _selectedStatus;
  IssueStatus? get selectedStatus => _selectedStatus;

  final TextEditingController costController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  // ─── Getters ────────────────────────────────────────────────────────────

  /// Expose ApiService for backward compatibility with form screens
  get apiService => api;

  // ─── Public API - CRUD Operations ──────────────────────────────────────

  /// Load paged maintenance issues
  Future<PagedResult<MaintenanceIssue>?> loadPagedIssues({
    Map<String, dynamic>? params,
  }) async {
    final query = TableQuery(
      page: params?['page'] ?? 1,
      pageSize: params?['pageSize'] ?? 25,
      searchTerm: params?['searchTerm'],
      filters: params?['filters'] ?? {},
      sortBy: params?['sortBy'],
      sortDescending: params?['sortDescending'] ?? false,
    );

    final queryString = api.buildQueryString(query.toQueryParams());

    return executeWithState(
      () => api.getPagedAndDecode(
        'api/maintenance$queryString',
        MaintenanceIssue.fromJson,
        authenticated: true,
      ),
    );
  }

  /// Load a specific maintenance issue by ID
  Future<MaintenanceIssue?> loadIssueById(String id) async {
    return executeWithState(
      () => api.getAndDecode(
        'api/maintenance/$id',
        MaintenanceIssue.fromJson,
        authenticated: true,
      ),
    );
  }

  /// Create a new maintenance issue
  Future<MaintenanceIssue?> createIssue(MaintenanceIssue issue) async {
    return executeWithState(
      () => api.postAndDecode(
        'api/maintenance',
        issue.toJson(),
        MaintenanceIssue.fromJson,
        authenticated: true,
      ),
    );
  }

  /// Update an existing maintenance issue
  Future<MaintenanceIssue?> updateIssue(MaintenanceIssue issue) async {
    return executeWithState(() async {
      final result = await api.putAndDecode(
        'api/maintenance/${issue.maintenanceIssueId}',
        issue.toJson(),
        MaintenanceIssue.fromJson,
        authenticated: true,
      );

      return result;
    });
  }

  /// Delete a maintenance issue by ID
  Future<bool> deleteIssue(String id) async {
    final success = await executeWithState(() async {
      await api.deleteAndConfirm('api/maintenance/$id', authenticated: true);
    });

    if (success) {
      _issues.removeWhere((issue) => issue.maintenanceIssueId.toString() == id);
      if (_selectedIssue?.maintenanceIssueId.toString() == id) {
        _selectedIssue = null;
      }
      notifyListeners();
    }

    return success;
  }

  /// Update the status of a maintenance issue
  Future<bool> updateIssueStatus(
    String id,
    IssueStatus newStatus, {
    String? resolutionNotes,
    double? cost,
  }) async {
    final data = <String, dynamic>{'status': newStatus.name};

    if (resolutionNotes != null) {
      data['resolutionNotes'] = resolutionNotes;
    }

    if (cost != null) {
      data['cost'] = cost;
    }

    final success = await executeWithStateForSuccess(() async {
      await api.putJson(
        'api/maintenance/$id/status',
        data,
        authenticated: true,
      );
    });

    return success;
  }

  // ─── Legacy Methods for Backward Compatibility ──────────────────────────

  // These methods maintain backward compatibility with existing code

  Future<PagedResult<MaintenanceIssue>> fetchData(TableQuery query) async {
    final result = await executeWithState<PagedResult<MaintenanceIssue>>(
      () async {
        return await api.getPagedAndDecode(
          'api/maintenance${api.buildQueryString(query.toQueryParams())}',
          MaintenanceIssue.fromJson,
          authenticated: true,
        );
      },
    );

    if (result != null) {
      _pagedResult = result;
      _issues = result.items;
      notifyListeners();
      return result;
    }
    return PagedResult.empty();
  }

  Future<void> getIssueById(String id) async {
    final result = await executeWithState<MaintenanceIssue>(() async {
      return await api.getAndDecode(
        'api/maintenance/$id',
        MaintenanceIssue.fromJson,
        authenticated: true,
      );
    });

    if (result != null) {
      _selectedIssue = result;
      notifyListeners();
    }
  }

  /// Alias for getIssueById - used by router
  Future<void> getById(String id) async {
    await getIssueById(id);
  }

  /// Get paged maintenance issues - used by router
  Future<PagedResult<MaintenanceIssue>> getPaged([
    Map<String, dynamic>? params,
  ]) async {
    // Create default TableQuery if no params provided
    final query = TableQuery(
      page: params?['page'] ?? 1,
      pageSize: params?['pageSize'] ?? 25,
      searchTerm: params?['searchTerm'],
      filters: params?['filters'] ?? {},
      sortBy: params?['sortBy'],
      sortDescending: params?['sortDescending'] ?? false,
    );
    return await fetchData(query);
  }

  Future<bool> saveIssue(MaintenanceIssue issue) async {
    final result = await executeWithState<Map<String, dynamic>>(() async {
      if (issue.maintenanceIssueId == 0) {
        return await api.postJson(
          'api/maintenance',
          issue.toJson(),
          authenticated: true,
        );
      } else {
        return await api.putAndDecode(
          'api/maintenance/${issue.maintenanceIssueId}',
          issue.toJson(),
          (json) => json,
          authenticated: true,
        );
      }
    });

    if (result != null) {
      // Refresh the issues list
      await getPaged();
      return true;
    }
    return false;
  }

  /// Alias for saveIssue - used by maintenance form screen
  Future<bool> save(MaintenanceIssue issue) async {
    return await saveIssue(issue);
  }

  // ─── Editing State Management ──────────────────────────────────────────

  void startEditing(MaintenanceIssue issue) {
    _editingIssue = issue;
    _selectedStatus = issue.status;
    costController.text = issue.cost?.toString() ?? '';
    notesController.text = issue.resolutionNotes ?? '';
    notifyListeners();
  }

  void cancelEditing() {
    _editingIssue = null;
    _selectedStatus = null;
    costController.clear();
    notesController.clear();
    notifyListeners();
  }

  void updateSelectedStatus(IssueStatus newStatus) {
    _selectedStatus = newStatus;
    notifyListeners();
  }

  // ─── Table Configuration (for DesktopDataTable integration) ─────────────

  List<TableColumnConfig<MaintenanceIssue>> getTableColumns(
    BuildContext tableContext,
  ) {
    return [
      TableColumnConfig(
        key: 'priority',
        label: 'Priority',
        cellBuilder: (issue) => _priorityCell(
          issue.priority.name,
          color: _getPriorityColor(issue.priority),
        ),
      ),
      TableColumnConfig(
        key: 'title',
        label: 'Title',
        cellBuilder: (issue) => _textCell(issue.title),
        width: const FlexColumnWidth(2.0),
      ),
      TableColumnConfig(
        key: 'status',
        label: 'Status',
        cellBuilder: (issue) => _statusCell(
          issue.status.name,
          color: _getStatusColor(issue.status),
        ),
      ),
      TableColumnConfig(
        key: 'createdAt',
        label: 'Reported',
        cellBuilder: (issue) => _dateCell(issue.createdAt),
      ),
      TableColumnConfig(
        key: 'actions',
        label: 'Actions',
        cellBuilder: (issue) => _actionCell([
          _iconActionCell(
            icon: Icons.edit,
            tooltip: 'Edit',
            onPressed: () =>
                tableContext.push('/maintenance/${issue.maintenanceIssueId}'),
          ),
        ]),
      ),
    ];
  }

  // ─── Private Helpers & UI Builders ──────────────────────────────────

  Widget _priorityCell(String text, {Color? color}) => Container(
    padding: const EdgeInsets.all(8),
    color: color,
    child: Text(text),
  );

  Widget _statusCell(String text, {Color? color}) => Container(
    padding: const EdgeInsets.all(8),
    color: color,
    child: Text(text),
  );

  Widget _textCell(String text) => Text(text);

  Widget _dateCell(DateTime? date) =>
      Text(date?.toLocal().toString().split(' ')[0] ?? 'N/A');

  Widget _actionCell(List<Widget> actions) => Row(children: actions);

  Widget _iconActionCell({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) => IconButton(icon: Icon(icon), tooltip: tooltip, onPressed: onPressed);

  Color _getPriorityColor(IssuePriority priority) {
    switch (priority) {
      case IssuePriority.low:
        return Colors.green.shade100;
      case IssuePriority.medium:
        return Colors.orange.shade100;
      case IssuePriority.high:
        return Colors.red.shade100;
      case IssuePriority.emergency:
        return Colors.purple.shade100;
    }
  }

  Color _getStatusColor(IssueStatus status) {
    switch (status) {
      case IssueStatus.pending:
        return Colors.blue.shade100;
      case IssueStatus.inProgress:
        return Colors.yellow.shade100;
      case IssueStatus.completed:
        return Colors.green.shade100;
      case IssueStatus.cancelled:
        return Colors.red.shade100;
    }
  }

  @override
  void dispose() {
    costController.dispose();
    notesController.dispose();
    super.dispose();
  }
}
