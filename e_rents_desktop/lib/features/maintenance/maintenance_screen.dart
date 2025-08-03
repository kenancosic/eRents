import 'package:e_rents_desktop/features/maintenance/providers/maintenance_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/maintenance_issue.dart';
import 'package:e_rents_desktop/utils/date_utils.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/widgets/desktop_data_table.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  int? _sortColumnIndex;
  bool _sortAscending = true;
  List<MaintenanceIssue> _issues = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadIssues();
  }

  Future<void> _loadIssues({String? sortBy, bool? ascending}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final maintenanceProvider = Provider.of<MaintenanceProvider>(
        context,
        listen: false,
      );
      
      final params = <String, dynamic>{};
      if (sortBy != null) {
        params['sortBy'] = sortBy;
        params['sortDescending'] = !(ascending ?? true);
      }
      
      final result = await maintenanceProvider.loadPagedIssues(params: params);

      setState(() {
        _issues = result?.items ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    String? sortBy;
    if (_sortColumnIndex != null) {
      final sortFields = ['priority', 'title', 'status', 'createdAt'];
      if (_sortColumnIndex! < sortFields.length) {
        sortBy = sortFields[_sortColumnIndex!];
      }
    }

    await _loadIssues(sortBy: sortBy, ascending: _sortAscending);
  }

  void _handleSort(int? columnIndex, bool ascending) {
    if (columnIndex == null) return;
    
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });

    // Map column index to sort field
    final sortFields = ['priority', 'title', 'status', 'createdAt'];
    if (columnIndex < sortFields.length) {
      _loadIssues(sortBy: sortFields[columnIndex], ascending: ascending);
    }
  }

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance Issues'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () => context.go('/maintenance/new'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New Issue'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
      body: DesktopDataTable<MaintenanceIssue>(
        items: _issues,
        loading: _isLoading,
        errorMessage: _errorMessage,
        onRefresh: _refresh,
        sortColumnIndex: _sortColumnIndex,
        sortAscending: _sortAscending,
        onSort: _handleSort,
        columns: const [
          DataColumn(label: Text('Priority')),
          DataColumn(label: Text('Title')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Reported')),
        ],
        rowsBuilder: (context, issues) {
          return issues.map((issue) {
            return DataRow(
              cells: [
                DataCell(
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: _getPriorityColor(issue.priority),
                    child: Text(issue.priority.name),
                  ),
                ),
                DataCell(Text(issue.title)),
                DataCell(
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: _getStatusColor(issue.status),
                    child: Text(issue.status.name),
                  ),
                ),
                DataCell(Text(AppDateUtils.formatShort(issue.createdAt))),
              ],
              onSelectChanged: (selected) {
                if (selected ?? false) {
                  _showMaintenanceQuickActions(issue);
                }
              },
            );
          }).toList();
        },
      ),
    );
  }

  void _showMaintenanceQuickActions(MaintenanceIssue issue) {
    showModalBottomSheet(
      context: context,
      builder: (context) => MaintenanceQuickActionsSheet(issue: issue),
    );
  }
}

class MaintenanceQuickActionsSheet extends StatelessWidget {
  final MaintenanceIssue issue;

  const MaintenanceQuickActionsSheet({super.key, required this.issue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      issue.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Issue #${issue.maintenanceIssueId} • Property ${issue.propertyId}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(issue.status),
            ],
          ),

          const SizedBox(height: 24),

          // Issue Details
          _buildDetailRow(
            context,
            'Priority',
            issue.priority.toString().split('.').last,
            Icons.priority_high,
            color: _getPriorityColor(issue.priority),
          ),
          _buildDetailRow(
            context,
            'Category',
            issue.category ?? 'General',
            Icons.category,
          ),
          _buildDetailRow(
            context,
            'Reported',
            _formatDate(issue.createdAt),
            Icons.schedule,
          ),
          if (issue.cost != null && issue.cost! > 0)
            _buildDetailRow(
              context,
              'Cost',
              '${issue.cost!.toStringAsFixed(2)} BAM',
              Icons.attach_money,
            ),

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.pop();
                    context.push('/maintenance/${issue.maintenanceIssueId}');
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text('View Details'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.pop();
                    context.push('/properties/${issue.propertyId}');
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('View Property'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(IssueStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toString().split('.').last,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

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

  String _formatDate(DateTime date) {
    return AppDateUtils.formatShort(date);
  }
}
