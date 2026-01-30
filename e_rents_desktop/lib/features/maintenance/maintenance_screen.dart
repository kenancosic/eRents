import 'package:e_rents_desktop/features/maintenance/providers/maintenance_provider.dart';
import 'package:e_rents_desktop/models/enums/maintenance_issue_priority.dart';
import 'package:e_rents_desktop/models/enums/maintenance_issue_status.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:e_rents_desktop/utils/date_utils.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/features/maintenance/ui/maintenance_table_config.dart';
import 'package:e_rents_desktop/features/maintenance/ui/maintenance_filter_panel.dart';
import 'package:e_rents_desktop/presentation/extensions.dart';
import 'package:e_rents_desktop/presentation/badges.dart';
import 'package:e_rents_desktop/base/crud/list_screen.dart';
import 'package:e_rents_desktop/presentation/status_pill.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  // ListController must be preserved across rebuilds to maintain refresh binding
  final ListController _listController = ListController();

  @override
  Widget build(BuildContext context) {
    final provider = context.read<MaintenanceProvider>();
    final listController = _listController;

    return ListScreen<MaintenanceIssue>(
      title: 'Maintenance Issues',
      // Use DataTable mode with our centralized columns
      tableColumns: MaintenanceTableConfig.columns,
      tableRowsBuilder: (ctx, issues) {
        return issues.map((issue) {
          return DataRow(
            cells: [
              DataCell(
                PriorityBadge(
                  priority: issue.priority,
                  showIcon: true,
                  variant: BadgeVariant.solid,
                  size: BadgeSize.sm,
                ),
              ),
              DataCell(Text(issue.title)),
              DataCell(
                StatusBadge(
                  status: issue.status,
                  showIcon: true,
                  variant: BadgeVariant.solid,
                  size: BadgeSize.sm,
                ),
              ),
              DataCell(Text(issue.tenantName)),
              DataCell(Text(AppDateUtils.formatShort(issue.createdAt))),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Details',
                      icon: const Icon(Icons.visibility),
                      onPressed: () async {
                        // Wait for details screen to close, then refresh list
                        await ctx.push('/maintenance/${issue.maintenanceIssueId}');
                        await listController.refresh();
                      },
                    ),
                    PopupMenuButton<MaintenanceIssueStatus>(
                      tooltip: 'Change status',
                      icon: const Icon(Icons.swap_horiz),
                      onSelected: (newStatus) async {
                        final messenger = ScaffoldMessenger.of(ctx);
                        try {
                          await provider.updateIssueStatus(
                            issue.maintenanceIssueId.toString(),
                            newStatus,
                          );
                          // Refresh the table to reflect updated status
                          await listController.refresh();
                          messenger.showSnackBar(
                            SnackBar(content: Text('Status changed to ${newStatus.displayName}')),
                          );
                        } catch (e) {
                          messenger.showSnackBar(
                            SnackBar(content: Text('Failed to change status: $e')),
                          );
                        }
                      },
                      itemBuilder: (context) => MaintenanceIssueStatus.values
                          .map(
                            (s) => PopupMenuItem<MaintenanceIssueStatus>(
                              value: s,
                              child: Row(
                                children: [
                                  Icon(s.icon, size: 18, color: s.color),
                                  const SizedBox(width: 8),
                                  Text(s.displayName),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: ctx,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('Delete maintenance issue'),
                            content: Text('Are you sure you want to delete "${issue.title}"?'),
                            actions: [
                              TextButton(
                                onPressed: () => dialogContext.pop(false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => dialogContext.pop(true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          final messenger = ScaffoldMessenger.of(ctx);
                          try {
                            final ok = await provider.remove(issue.maintenanceIssueId);
                            if (ok) {
                              messenger.showSnackBar(const SnackBar(content: Text('Issue deleted')));
                              // Refresh the table to remove the deleted item
                              await listController.refresh();
                            }
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(content: Text('Failed to delete: $e')),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
            onSelectChanged: (selected) {
              if (selected ?? false) {
                showModalBottomSheet(
                  context: ctx,
                  builder: (_) => MaintenanceQuickActionsSheet(issue: issue),
                );
              }
            },
          );
        }).toList();
      },
      enablePagination: true,
      pageSize: 20,
      inlineSearchBar: true,
      inlineSearchHint: 'Search issues...',
      showFilters: true,
      filterBuilder: (ctx, currentFilters, controller) => MaintenanceFilterPanel(
        initialFilters: currentFilters,
        showSearchField: false,
        controller: controller,
      ),
      // Client-side filtering using the title field
      filterFunction: (item) {
        // When using inlineSearchBar, ListScreen manages 'search' filter via _filters['search']
        // We can't access it here, so provide a permissive filter and rely on server-side later if needed.
        return true;
      },
      // Optional: simple client-side sort by createdAt as default
      sortFunction: (a, b) => a.createdAt.compareTo(b.createdAt),
      actions: [
        ElevatedButton.icon(
          onPressed: () => context.go('/maintenance/new'),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('New Issue'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ],
      fetchItems: ({int page = 1, int pageSize = 20, Map<String, dynamic>? filters}) async {
        // Map ListScreen filters to provider.fetchPaged
        final paged = await provider.fetchPaged(
          page: page,
          pageSize: pageSize,
          filters: filters,
        );
        return paged?.items ?? <MaintenanceIssue>[];
      },
      controller: listController,
      onItemTap: (item) => context.push('/maintenance/${item.maintenanceIssueId}'),
      onItemDoubleTap: (item) => context.push('/maintenance/${item.maintenanceIssueId}'),
      // Fallback itemBuilder (not used when tableRowsBuilder is provided)
      itemBuilder: (ctx, issue) => ListTile(
        title: Text(issue.title),
        subtitle: Text('Reported: ${AppDateUtils.formatShort(issue.createdAt)}'),
        trailing: StatusPill(
          label: issue.status.displayName,
          backgroundColor: issue.status.color,
          iconData: issue.status.icon,
          foregroundColor: Colors.white,
        ),
      ),
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
            issue.priority.displayName,
            Icons.priority_high,
            color: issue.priority.color,
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
              '${issue.cost!.toStringAsFixed(2)} USD',
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

  Widget _buildStatusBadge(MaintenanceIssueStatus status) {
    return StatusBadge(status: status, showIcon: true);
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


  String _formatDate(DateTime date) {
    return AppDateUtils.formatShort(date);
  }
}
