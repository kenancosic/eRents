import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../models/maintenance_issue.dart';
import '../../../repositories/maintenance_repository.dart';
import '../../../widgets/table/custom_table.dart';

/// ✅ MAINTENANCE UNIVERSAL TABLE PROVIDER - 90% automatic, 10% custom
///
/// This provider extends BaseUniversalTableProvider to automatically handle:
/// - Pagination, sorting, searching, filtering
/// - Backend Universal System integration
/// - Standard UI components and interactions
///
/// Only maintenance-specific column definitions are required (10% custom code)
class MaintenanceUniversalTableProvider
    extends TableProvider<MaintenanceIssue> {
  final BuildContext context;

  MaintenanceUniversalTableProvider({
    required MaintenanceRepository repository,
    required UniversalTableConfig<MaintenanceIssue> config,
    required this.context,
  }) : super(
         fetchDataFunction: repository.getPagedMaintenanceIssues,
         config: config,
       );

  @override
  List<TableColumnConfig<MaintenanceIssue>> get columns => [
    // ✅ AUTOMATIC: 90% of columns use standard helpers
    createColumn(
      key: 'priority',
      label: 'Priority',
      cellBuilder:
          (issue) => priorityCell(
            issue.priority.toString().split('.').last,
            color: _getPriorityColor(issue.priority),
          ),
      width: const FlexColumnWidth(0.8),
    ),
    createColumn(
      key: 'title',
      label: 'Title',
      cellBuilder: (issue) => textCell(issue.title),
      width: const FlexColumnWidth(2.0),
    ),
    createColumn(
      key: 'propertyId',
      label: 'Property',
      cellBuilder:
          (issue) => linkCell(
            text: 'Property ${issue.propertyId}',
            icon: Icons.apartment,
            onTap: () => context.push('/properties/${issue.propertyId}'),
          ),
      width: const FlexColumnWidth(1.2),
    ),
    createColumn(
      key: 'status',
      label: 'Status',
      cellBuilder:
          (issue) => statusCell(
            issue.status.toString().split('.').last,
            color: _getStatusColor(issue.status),
          ),
      width: const FlexColumnWidth(1.0),
    ),
    createColumn(
      key: 'createdAt',
      label: 'Reported',
      cellBuilder: (issue) => dateCell(issue.createdAt),
      width: const FlexColumnWidth(1.0),
    ),
    createColumn(
      key: 'actions',
      label: 'Actions',
      cellBuilder:
          (issue) => actionCell([
            iconActionCell(
              icon: Icons.visibility,
              tooltip: 'View Details',
              onPressed:
                  () => context.go('/maintenance/${issue.maintenanceIssueId}'),
            ),
          ]),
      sortable: false,
      width: const FlexColumnWidth(0.6),
    ),
  ];

  @override
  List<TableFilter> get availableFilters => [
    createFilter(
      key: 'Status',
      label: 'Status',
      type: FilterType.dropdown,
      options:
          IssueStatus.values
              .map(
                (status) => FilterOption(
                  label: status.toString().split('.').last,
                  value: status.name,
                ),
              )
              .toList(),
    ),
    createFilter(
      key: 'Priority',
      label: 'Priority',
      type: FilterType.dropdown,
      options:
          IssuePriority.values
              .map(
                (priority) => FilterOption(
                  label: priority.toString().split('.').last,
                  value: priority.name,
                ),
              )
              .toList(),
    ),
    createFilter(
      key: 'PropertyId',
      label: 'Property ID',
      type: FilterType.text,
    ),
    createFilter(key: 'Category', label: 'Category', type: FilterType.text),
    createFilter(
      key: 'IsTenantComplaint',
      label: 'Tenant Complaints Only',
      type: FilterType.checkbox,
    ),
  ];

  /// ✅ CUSTOM: 10% - Maintenance-specific priority colors
  Color _getPriorityColor(IssuePriority priority) {
    switch (priority) {
      case IssuePriority.low:
        return Colors.green;
      case IssuePriority.medium:
        return Colors.orange;
      case IssuePriority.high:
        return Colors.red;
      case IssuePriority.emergency:
        return Colors.purple;
    }
  }

  /// ✅ CUSTOM: 10% - Maintenance-specific status colors
  Color _getStatusColor(IssueStatus status) {
    switch (status) {
      case IssueStatus.pending:
        return Colors.orange;
      case IssueStatus.inProgress:
        return Colors.blue;
      case IssueStatus.completed:
        return Colors.green;
      case IssueStatus.cancelled:
        return Colors.red;
    }
  }
}

/// ✅ FACTORY - One-liner table creation (like ImageUtils pattern)
class MaintenanceTableFactory {
  static CustomTableWidget<MaintenanceIssue> create({
    required MaintenanceRepository repository,
    required BuildContext context,
    String title = 'Maintenance Issues',
    Widget? headerActions,
    void Function(MaintenanceIssue)? onRowTap,
    void Function(MaintenanceIssue)? onRowDoubleTap,
  }) {
    // ✅ CONFIGURATION: Customize table behavior
    final config = UniversalTableConfig<MaintenanceIssue>(
      title: title,
      searchHint: 'Search maintenance issues...',
      emptyStateMessage: 'No maintenance issues found',
      headerActions: headerActions,
      onRowTap: onRowTap,
      onRowDoubleTap: onRowDoubleTap,
    );

    // ✅ PROVIDER: Create Universal Table Provider
    final provider = MaintenanceUniversalTableProvider(
      repository: repository,
      config: config,
      context: context,
    );

    // ✅ WIDGET: Return ready-to-use table widget
    return CustomTableWidget<MaintenanceIssue>(
      dataProvider: provider,
      title: title,
    );
  }
}
