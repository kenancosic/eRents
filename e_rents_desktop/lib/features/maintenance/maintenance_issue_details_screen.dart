import 'package:e_rents_desktop/features/maintenance/state/maintenance_status_update_state.dart';
import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:e_rents_desktop/features/maintenance/providers/maintenance_detail_provider.dart';
import 'package:e_rents_desktop/base/base.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_desktop/utils/date_utils.dart';
import 'package:e_rents_desktop/services/api_service.dart';

class MaintenanceIssueDetailsScreen extends StatelessWidget {
  final MaintenanceIssue? issue;
  final String issueId;

  const MaintenanceIssueDetailsScreen({
    super.key,
    this.issue,
    required this.issueId,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MaintenanceDetailProvider>(
      builder: (context, provider, child) {
        if (provider.state == ProviderState.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  provider.error!.message,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.loadItem(issueId),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final issue = provider.item;
        if (issue == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Maintenance issue not found'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go('/maintenance'),
                  child: const Text('Back to Maintenance'),
                ),
              ],
            ),
          );
        }

        return _MaintenanceIssueDetailsView(issue: issue);
      },
    );
  }
}

class _MaintenanceIssueDetailsView extends StatelessWidget {
  final MaintenanceIssue issue;

  const _MaintenanceIssueDetailsView({required this.issue});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildIssueDetails(),
          const SizedBox(height: 24),
          ChangeNotifierProvider(
            create:
                (_) => MaintenanceStatusUpdateState(
                  getService<MaintenanceRepository>(),
                  issue,
                ),
            child: _ActionCard(
              onStatusUpdated: (updatedIssue) {
                // Refresh the details provider with the new data
                context.read<MaintenanceDetailProvider>().updateItem(
                  updatedIssue,
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  context.go('/properties/${issue.propertyId}');
                },
                icon: const Icon(Icons.home),
                label: const Text('View Property'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final router = GoRouter.of(context);
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (router.canPop()) {
              router.pop();
            } else {
              router.go('/maintenance');
            }
          },
          tooltip: 'Go back',
        ),
        const Spacer(),
        _buildStatusChip(),
      ],
    );
  }

  Widget _buildStatusChip() {
    return Chip(
      label: Text(
        issue.status.toString().split('.').last,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: issue.statusColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    );
  }

  Widget _buildIssueDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: issue.priorityColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  issue.priority.toString().split('.').last,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              issue.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Reported by ${issue.tenantName ?? "Tenant ID ${issue.tenantId}"} • ${AppDateUtils.formatRelative(issue.createdAt)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 24),
            Text(
              'Description',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(issue.description, style: const TextStyle(fontSize: 16)),
            if (issue.imageIds.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Attached Images',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: issue.imageIds.length,
                  itemBuilder: (context, index) {
                    final imageId = issue.imageIds[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          getService<ApiService>().makeAbsoluteUrl(
                            'Image/$imageId',
                          ),
                          width: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            if (issue.resolutionNotes != null) ...[
              const SizedBox(height: 24),
              Text(
                'Resolution Notes',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                issue.resolutionNotes!,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final Function(MaintenanceIssue) onStatusUpdated;
  const _ActionCard({required this.onStatusUpdated});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MaintenanceStatusUpdateState>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Change Status',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatusSelection(context, state),
            const SizedBox(height: 16),
            if (state.selectedStatus == IssueStatus.completed) ...[
              TextField(
                controller: state.costController,
                decoration: const InputDecoration(
                  labelText: 'Resolution Cost',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => (context as Element).markNeedsBuild(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: state.notesController,
                decoration: const InputDecoration(
                  labelText: 'Resolution Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (_) => (context as Element).markNeedsBuild(),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed:
                      state.isLoading || !state.hasChanges
                          ? null
                          : () async {
                            final updatedIssue = await state.saveChanges();
                            if (updatedIssue != null) {
                              onStatusUpdated(updatedIssue);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Status updated successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else if (state.errorMessage != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(state.errorMessage!),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                  icon:
                      state.isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.save),
                  label: const Text('Save Changes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSelection(
    BuildContext context,
    MaintenanceStatusUpdateState state,
  ) {
    return Column(
      children:
          IssueStatus.values.map((status) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: RadioListTile<IssueStatus>(
                title: Row(
                  children: [
                    Icon(
                      _getStatusIcon(status),
                      color: _getStatusColor(status),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(_getStatusDisplayName(status)),
                  ],
                ),
                subtitle: Text(_getStatusDescription(status)),
                value: status,
                groupValue: state.selectedStatus,
                onChanged: (IssueStatus? value) {
                  if (value != null) {
                    state.updateStatus(value);
                  }
                },
              ),
            );
          }).toList(),
    );
  }

  IconData _getStatusIcon(IssueStatus status) {
    switch (status) {
      case IssueStatus.pending:
        return Icons.pending_actions_outlined;
      case IssueStatus.inProgress:
        return Icons.construction_outlined;
      case IssueStatus.completed:
        return Icons.check_circle_outline_rounded;
      case IssueStatus.cancelled:
        return Icons.cancel_outlined;
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

  String _getStatusDescription(IssueStatus status) {
    switch (status) {
      case IssueStatus.pending:
        return 'Issue reported, waiting to be addressed';
      case IssueStatus.inProgress:
        return 'Work is currently in progress';
      case IssueStatus.completed:
        return 'Issue has been resolved';
      case IssueStatus.cancelled:
        return 'Issue has been cancelled';
    }
  }

  String _getStatusDisplayName(IssueStatus status) {
    switch (status) {
      case IssueStatus.pending:
        return 'Pending';
      case IssueStatus.inProgress:
        return 'In Progress';
      case IssueStatus.completed:
        return 'Completed';
      case IssueStatus.cancelled:
        return 'Cancelled';
    }
  }
}
