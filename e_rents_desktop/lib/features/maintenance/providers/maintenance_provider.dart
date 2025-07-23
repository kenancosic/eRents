import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/maintenance_issue.dart';
import '../../../models/paged_result.dart';
import '../../../services/api_service.dart';
import '../../../widgets/table/custom_table.dart';

class MaintenanceProvider extends ChangeNotifier implements BaseTableProvider<MaintenanceIssue> {
  final ApiService _api;
  final String _endpoint = '/maintenance';
  final BuildContext? context;

  MaintenanceProvider(this._api, {this.context});

  // ─── API Access ────────────────────────────────────────────────────────
  ApiService get apiService => _api;

  // ─── State ──────────────────────────────────────────────────────────────
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  List<MaintenanceIssue> _issues = [];
  List<MaintenanceIssue> get issues => _issues;

  MaintenanceIssue? _selectedIssue;
  MaintenanceIssue? get selectedIssue => _selectedIssue;

  PagedResult<MaintenanceIssue> _pagedResult = PagedResult(
    items: [],
    totalCount: 0,
    page: 1,
    pageSize: 10,
  );
  PagedResult<MaintenanceIssue> get pagedResult => _pagedResult;
  
  // Status update state (migrated from MaintenanceStatusUpdateState)
  MaintenanceIssue? _editingIssue;
  MaintenanceIssue? get editingIssue => _editingIssue;
  
  IssueStatus? _selectedStatus;
  IssueStatus? get selectedStatus => _selectedStatus;
  
  final TextEditingController costController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  
  bool get hasStatusChanges => _editingIssue != null && 
      (_selectedStatus != _editingIssue!.status || 
       costController.text != (_editingIssue!.cost?.toString() ?? '') || 
       notesController.text != (_editingIssue!.resolutionNotes ?? ''));

  // ─── Convenience Getters (from old providers) ──────────────────────────
  List<MaintenanceIssue> get pendingIssues =>
      _issues.where((i) => i.status == IssueStatus.pending).toList();
  List<MaintenanceIssue> get inProgressIssues =>
      _issues.where((i) => i.status == IssueStatus.inProgress).toList();
  List<MaintenanceIssue> get completedIssues =>
      _issues.where((i) => i.status == IssueStatus.completed).toList();
  int get totalIssues => _pagedResult.totalCount;
  double get completionRate => totalIssues > 0 ? completedIssues.length / totalIssues : 0.0;

  // ─── Public API ─────────────────────────────────────────────────────────

  Future<void> getPaged({Map<String, dynamic>? params}) async {
    _setLoading(true);
    try {
      String queryString = '';
      if (params != null && params.isNotEmpty) {
        queryString =
            '?' + params.entries.map((e) => '${e.key}=${e.value}').join('&');
      }
      final fullEndpoint = '$_endpoint$queryString';

      final response = await _api.get(fullEndpoint, authenticated: true);
      final data = json.decode(response.body);
      _pagedResult = PagedResult<MaintenanceIssue>.fromJson(
          data, (json) => MaintenanceIssue.fromJson(json as Map<String, dynamic>));
      _issues = _pagedResult.items;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> getById(String id) async {
    _setLoading(true);
    try {
      final response = await _api.get('$_endpoint/$id', authenticated: true);
      final data = json.decode(response.body);
      _selectedIssue = MaintenanceIssue.fromJson(data);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> save(MaintenanceIssue issue) async {
    _setLoading(true);
    try {
      final isUpdate = issue.maintenanceIssueId > 0;
      final url = isUpdate ? '$_endpoint/${issue.maintenanceIssueId}' : _endpoint;
      final payload = issue.toJson();

      final response = isUpdate
          ? await _api.put(url, payload, authenticated: true)
          : await _api.post(url, payload, authenticated: true);

      if (response.statusCode == 200 || response.statusCode == 201) {
        await getPaged(); // Refresh the list
        return true;
      }
      _setError('Failed to save issue. Status code: ${response.statusCode}');
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> delete(String id) async {
    _setLoading(true);
    try {
      final response = await _api.delete('$_endpoint/$id', authenticated: true);
      if (response.statusCode == 204 || response.statusCode == 200) {
        await getPaged(); // Refresh the list
        return true;
      }
      _setError('Failed to delete issue. Status code: ${response.statusCode}');
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateStatus(String id, IssueStatus newStatus, {String? resolutionNotes, double? cost}) async {
    _setLoading(true);
    try {
      final payload = <String, dynamic>{
        'status': newStatus.name,
        if (resolutionNotes != null) 'resolutionNotes': resolutionNotes,
        if (cost != null) 'cost': cost,
        if (newStatus == IssueStatus.completed) 'resolvedAt': DateTime.now().toIso8601String(),
      };

      final response = await _api.put('$_endpoint/$id/status', payload, authenticated: true);
      if (response.statusCode == 200) {
        await getById(id); // Refresh selected issue
        await getPaged(); // Refresh list
        return true;
      }
      _setError('Failed to update status. Status code: ${response.statusCode}');
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Status Update Methods ────────────────────────────────────────
  
  void startEditing(MaintenanceIssue issue) {
    _editingIssue = issue;
    _selectedStatus = issue.status;
    costController.text = issue.cost?.toString() ?? '';
    notesController.text = issue.resolutionNotes ?? '';
    notifyListeners();
  }
  
  void updateSelectedStatus(IssueStatus newStatus) {
    if (_selectedStatus == newStatus) return;
    _selectedStatus = newStatus;
    if (newStatus == IssueStatus.completed && notesController.text.isEmpty) {
      notesController.text = 'Work completed.';
    }
    notifyListeners();
  }
  
  Future<bool> saveStatusChanges() async {
    if (!hasStatusChanges || _editingIssue == null || _selectedStatus == null) return false;

    _setLoading(true);
    _error = null;
    notifyListeners();

    try {
      final success = await updateStatus(
        _editingIssue!.maintenanceIssueId.toString(),
        _selectedStatus!,
        resolutionNotes: notesController.text.isNotEmpty ? notesController.text : null,
        cost: double.tryParse(costController.text),
      );
      return success;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  void cancelEditing() {
    _editingIssue = null;
    _selectedStatus = null;
    costController.clear();
    notesController.clear();
    _error = null;
    notifyListeners();
  }
  
  // ─── Table Configuration ───────────────────────────────────────
  
  // Helper methods for table cells
  Widget _priorityCell(String text, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color?.withAlpha(51),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
  
  Widget _statusCell(String text, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color?.withAlpha(51),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
  
  Widget _linkCell({required String text, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.blue)),
        ],
      ),
    );
  }
  
  Widget _textCell(String text) {
    return Text(text);
  }
  
  Widget _dateCell(DateTime? date) {
    return Text(
      date != null
        ? '${date.day}/${date.month}/${date.year}'
        : 'N/A',
    );
  }
  
  Widget _actionCell(List<Widget> actions) {
    return Row(children: actions);
  }
  
  Widget _iconActionCell({required IconData icon, required String tooltip, required VoidCallback onPressed}) {
    return IconButton(
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }
  
  Color _getPriorityColor(IssuePriority priority) {
    switch (priority) {
      case IssuePriority.low: return Colors.green;
      case IssuePriority.medium: return Colors.orange;
      case IssuePriority.high: return Colors.red;
      case IssuePriority.emergency: return Colors.purple;
    }
  }
  
  Color _getStatusColor(IssueStatus status) {
    switch (status) {
      case IssueStatus.pending: return Colors.orange;
      case IssueStatus.inProgress: return Colors.blue;
      case IssueStatus.completed: return Colors.green;
      default: return Colors.grey;
    }
  }
  
  // Table configuration for maintenance issues
  List<TableColumnConfig<MaintenanceIssue>> getTableColumns(BuildContext tableContext) {
    return [
      TableColumnConfig<MaintenanceIssue>(
        key: 'priority',
        label: 'Priority',
        cellBuilder: (issue) => _priorityCell(
          issue.priority.toString().split('.').last,
          color: _getPriorityColor(issue.priority),
        ),
        width: const FlexColumnWidth(0.8),
      ),
      TableColumnConfig<MaintenanceIssue>(
        key: 'title',
        label: 'Title',
        cellBuilder: (issue) => _textCell(issue.title),
        width: const FlexColumnWidth(2.0),
      ),
      TableColumnConfig<MaintenanceIssue>(
        key: 'propertyId',
        label: 'Property',
        cellBuilder: (issue) => _linkCell(
          text: 'Property ${issue.propertyId}',
          icon: Icons.apartment,
          onTap: () => tableContext.push('/properties/${issue.propertyId}'),
        ),
        width: const FlexColumnWidth(1.2),
      ),
      TableColumnConfig<MaintenanceIssue>(
        key: 'status',
        label: 'Status',
        cellBuilder: (issue) => _statusCell(
          issue.status.toString().split('.').last,
          color: _getStatusColor(issue.status),
        ),
        width: const FlexColumnWidth(1.0),
      ),
      TableColumnConfig<MaintenanceIssue>(
        key: 'createdAt',
        label: 'Reported',
        cellBuilder: (issue) => _dateCell(issue.createdAt),
        width: const FlexColumnWidth(1.0),
      ),
      TableColumnConfig<MaintenanceIssue>(
        key: 'actions',
        label: 'Actions',
        cellBuilder: (issue) => _actionCell([
          _iconActionCell(
            icon: Icons.visibility,
            tooltip: 'View Details',
            onPressed: () => tableContext.push('/maintenance/${issue.maintenanceIssueId}'),
          ),
        ]),
        sortable: false,
        width: const FlexColumnWidth(0.6),
      ),
    ];
  }
  
  // Get table filters
  List<TableFilter> getTableFilters() {
    return [
      TableFilter(
        key: 'Status',
        label: 'Status',
        type: FilterType.dropdown,
        options: IssueStatus.values
            .map((s) => FilterOption(label: s.toString().split('.').last, value: s.toString()))
            .toList(),
      ),
      TableFilter(
        key: 'Priority',
        label: 'Priority',
        type: FilterType.dropdown,
        options: IssuePriority.values
            .map((p) => FilterOption(label: p.toString().split('.').last, value: p.toString()))
            .toList(),
      ),
    ];
  }
  
  // ─── BaseTableProvider Implementation ──────────────────────────────────
  
  @override
  Future<PagedResult<MaintenanceIssue>> fetchData(TableQuery query) async {
    // Convert TableQuery to our internal pagination format
    final page = query.page + 1; // TableQuery uses 0-based, our API uses 1-based
    final pageSize = query.pageSize;
    final searchTerm = query.searchTerm;
    final filters = query.filters;
    
    // Build query parameters
    final queryParams = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };
    
    if (searchTerm != null && searchTerm.isNotEmpty) {
      queryParams['search'] = searchTerm;
    }
    
    // Add filters
    filters.forEach((key, value) {
      if (value != null) {
        queryParams[key.toLowerCase()] = value.toString();
      }
    });
    
    try {
      // Build endpoint with query parameters
      final uri = Uri.parse('$_endpoint').replace(queryParameters: queryParams);
      final response = await _api.get(uri.toString(), authenticated: true);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final pagedResult = PagedResult<MaintenanceIssue>.fromJson(
          data,
          (json) => MaintenanceIssue.fromJson(json),
        );
        
        // Update internal state
        _issues = pagedResult.items;
        _pagedResult = pagedResult;
        notifyListeners();
        
        return pagedResult;
      } else {
        throw Exception('Failed to fetch maintenance issues: ${response.statusCode}');
      }
    } catch (e) {
      _setError(e.toString());
      throw e;
    }
  }
  
  @override
  List<TableColumnConfig<MaintenanceIssue>> get columns {
    // Use a simple context-free approach for columns when context is not available
    if (context != null) {
      return getTableColumns(context!);
    }
    // Return basic columns without navigation when context is null
    return _getBasicTableColumns();
  }
  
  @override
  List<TableFilter> get availableFilters => getTableFilters();
  
  @override
  String get emptyStateMessage => 'No maintenance issues found';
  
  // Basic table columns without navigation (for when context is null)
  List<TableColumnConfig<MaintenanceIssue>> _getBasicTableColumns() {
    return [
      TableColumnConfig<MaintenanceIssue>(
        key: 'priority',
        label: 'Priority',
        cellBuilder: (issue) => _priorityCell(
          issue.priority.toString().split('.').last,
          color: _getPriorityColor(issue.priority),
        ),
        width: const FlexColumnWidth(0.8),
      ),
      TableColumnConfig<MaintenanceIssue>(
        key: 'title',
        label: 'Title',
        cellBuilder: (issue) => _textCell(issue.title),
        width: const FlexColumnWidth(2.0),
      ),
      TableColumnConfig<MaintenanceIssue>(
        key: 'propertyId',
        label: 'Property',
        cellBuilder: (issue) => _textCell('Property ${issue.propertyId}'),
        width: const FlexColumnWidth(1.2),
      ),
      TableColumnConfig<MaintenanceIssue>(
        key: 'status',
        label: 'Status',
        cellBuilder: (issue) => _statusCell(
          issue.status.toString().split('.').last,
          color: _getStatusColor(issue.status),
        ),
        width: const FlexColumnWidth(1.0),
      ),
      TableColumnConfig<MaintenanceIssue>(
        key: 'createdAt',
        label: 'Reported',
        cellBuilder: (issue) => _dateCell(issue.createdAt),
        width: const FlexColumnWidth(1.0),
      ),
    ];
  }
  
  // Get full table configuration
  UniversalTableConfig<MaintenanceIssue> getTableConfig(BuildContext tableContext) {
    // Prepare column labels, cell builders, and column widths from column configs
    final Map<String, String> columnLabels = {};
    final Map<String, Widget Function(MaintenanceIssue)> customCellBuilders = {};
    final Map<String, TableColumnWidth> columnWidths = {};
    
    // Convert our column configs to the format expected by UniversalTableConfig
    for (var column in getTableColumns(tableContext)) {
      columnLabels[column.key] = column.label;
      customCellBuilders[column.key] = column.cellBuilder;
      columnWidths[column.key] = column.width;
    }
    
    return UniversalTableConfig<MaintenanceIssue>(
      title: 'Maintenance Issues',
      searchHint: 'Search maintenance issues...',
      emptyStateMessage: 'No maintenance issues found',
      columnLabels: columnLabels,
      customCellBuilders: customCellBuilders,
      columnWidths: columnWidths,
      customFilters: getTableFilters(),
      onRowTap: (issue) {
        if (tableContext.mounted) {
          tableContext.push('/maintenance/${issue.maintenanceIssueId}');
        }
      },
    );
  }
  
  // ─── Helpers ────────────────────────────────────────────────────────

  void clearError() {
    _error = null;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _error = message;
    notifyListeners();
  }
  
  @override
  void dispose() {
    costController.dispose();
    notesController.dispose();
    super.dispose();
  }
}
