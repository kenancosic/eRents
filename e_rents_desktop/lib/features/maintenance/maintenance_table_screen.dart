import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_desktop/utils/date_utils.dart';
import '../../repositories/maintenance_repository.dart';
import '../../models/maintenance_issue.dart';
import '../../base/service_locator.dart';
import 'providers/maintenance_universal_table_provider.dart';

class MaintenanceTableScreen extends StatefulWidget {
  const MaintenanceTableScreen({super.key});

  @override
  State<MaintenanceTableScreen> createState() => _MaintenanceTableScreenState();
}

class _MaintenanceTableScreenState extends State<MaintenanceTableScreen> {
  late MaintenanceRepository _maintenanceRepository;

  @override
  void initState() {
    super.initState();
    // ✅ CLEAN: Use service locator to get repository dependency
    _maintenanceRepository = getService<MaintenanceRepository>();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ CLEAN: Remove redundant Scaffold - ContentWrapper handles layout
    return MaintenanceTableFactory.create(
      repository: _maintenanceRepository,
      context: context,
      title: '', // Remove title - ContentWrapper provides it
      headerActions: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildSummaryStats(),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () => _refreshData(),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
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
      onRowTap: (issue) {
        // Handle row selection
        _showMaintenanceQuickActions(issue);
      },
      onRowDoubleTap: (issue) {
        // Navigate to issue details
        context.push('/maintenance/${issue.maintenanceIssueId}');
      },
    );
  }

  Widget _buildSummaryStats() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 14,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 6),
          Text(
            'Smart Table',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  void _refreshData() {
    // ✅ CLEAN: Simply trigger rebuild
    // The Universal Table Widget handles its own data refresh
    setState(() {
      // This will cause the table widget to rebuild and fetch fresh data
    });
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
                    Navigator.of(context).pop();
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
                    Navigator.of(context).pop();
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
