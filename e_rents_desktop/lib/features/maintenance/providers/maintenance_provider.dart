import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/base/api_service_extensions.dart';
import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:e_rents_desktop/models/paged_result.dart';
import 'package:e_rents_desktop/widgets/table/custom_table.dart';
import 'package:e_rents_desktop/widgets/table/providers/base_table_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MaintenanceProvider extends BaseProvider implements BaseTableProvider<MaintenanceIssue> {
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

  // ─── Public API ─────────────────────────────────────────────────────────

  Future<PagedResult<MaintenanceIssue>> fetchData(TableQuery query) async {
    final result = await executeWithState<PagedResult<MaintenanceIssue>>(() async {
      return await api.getPagedAndDecode(
        '/maintenance${api.buildQueryString(query.toQueryParams())}',
        MaintenanceIssue.fromJson,
        authenticated: true,
      );
    });
    
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
      return await api.getAndDecode('/maintenance/$id', MaintenanceIssue.fromJson, authenticated: true);
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
  Future<PagedResult<MaintenanceIssue>> getPaged([Map<String, dynamic>? params]) async {
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
        return await api.postJson('/maintenance', issue.toJson(), authenticated: true);
      } else {
        return await api.putAndDecode('/maintenance/${issue.maintenanceIssueId}', issue.toJson(), (json) => json, authenticated: true);
      }
    });
    
    return result != null;
  }

  /// Alias for saveIssue - used by maintenance form screen
  Future<bool> save(MaintenanceIssue issue) async {
    return await saveIssue(issue);
  }

  Future<bool> deleteIssue(String id) async {
    final result = await executeWithState<bool>(() async {
      return await api.deleteAndConfirm('/maintenance/$id', authenticated: true);
    });
    
    if (result == true) {
      _issues.removeWhere((i) => i.maintenanceIssueId.toString() == id);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> updateStatus(String id, IssueStatus newStatus, {String? resolutionNotes, double? cost}) async {
    final body = {
      'status': newStatus.toString(),
      'resolutionNotes': resolutionNotes,
      'cost': cost,
    };
    
    final result = await executeWithState<Map<String, dynamic>>(() async {
      return await api.putAndDecode('/maintenance/$id/status', body, (json) => json, authenticated: true);
    });
    
    return result != null;
  }

  // ─── UI State Management ───────────────────────────────────────────────

  void startEditing(MaintenanceIssue issue) {
    _editingIssue = issue;
    _selectedStatus = issue.status;
    costController.text = issue.cost?.toString() ?? '';
    notesController.text = issue.resolutionNotes ?? '';
    notifyListeners();
  }

  void cancelEditing() {
    _editingIssue = null;
    notifyListeners();
  }

  void updateSelectedStatus(IssueStatus newStatus) {
    _selectedStatus = newStatus;
    notifyListeners();
  }

  // ─── Table Provider Implementation ────────────────────────────────────

  List<TableColumnConfig<MaintenanceIssue>> get columns =>
      context != null ? getTableColumns(context!) : _getBasicTableColumns();

  List<TableFilter> get availableFilters => getTableFilters();

  String get emptyStateMessage => 'No maintenance issues found';

  List<TableColumnConfig<MaintenanceIssue>> getTableColumns(
    BuildContext tableContext,
  ) {
    return [
      ..._getBasicTableColumns(),
      TableColumnConfig(
        key: 'actions',
        label: 'Actions',
        cellBuilder:
            (issue) => _actionCell([
              _iconActionCell(
                icon: Icons.edit,
                tooltip: 'Edit',
                onPressed:
                    () => tableContext.push(
                      '/maintenance/${issue.maintenanceIssueId}',
                    ),
              ),
            ]),
      ),
    ];
  }

  List<TableFilter> getTableFilters() {
    return [
      TableFilter(
        key: 'status',
        label: 'Status',
        type: FilterType.dropdown,
        options:
            IssueStatus.values
                .map((s) => FilterOption(value: s.name, label: s.name))
                .toList(),
      ),
      TableFilter(
        key: 'priority',
        label: 'Priority',
        type: FilterType.dropdown,
        options:
            IssuePriority.values
                .map((p) => FilterOption(value: p.name, label: p.name))
                .toList(),
      ),
    ];
  }

  // ─── Private Helpers & UI Builders ──────────────────────────────────

  List<TableColumnConfig<MaintenanceIssue>> _getBasicTableColumns() {
    return [
      TableColumnConfig(
        key: 'priority',
        label: 'Priority',
        cellBuilder:
            (issue) => _priorityCell(
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
        cellBuilder:
            (issue) => _statusCell(
              issue.status.name,
              color: _getStatusColor(issue.status),
            ),
      ),
      TableColumnConfig(
        key: 'createdAt',
        label: 'Reported',
        cellBuilder: (issue) => _dateCell(issue.createdAt),
      ),
    ];
  }

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
      case IssuePriority.high:
        return Colors.red.shade100;
      case IssuePriority.medium:
        return Colors.orange.shade100;
      default:
        return Colors.green.shade100;
    }
  }

  Color _getStatusColor(IssueStatus status) {
    switch (status) {
      case IssueStatus.pending:
        return Colors.blue.shade100;
      case IssueStatus.inProgress:
        return Colors.yellow.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  @override
  void dispose() {
    costController.dispose();
    notesController.dispose();
    super.dispose();
  }
}
