import 'package:e_rents_desktop/features/maintenance/providers/maintenance_provider.dart';
import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/maintenance_issue.dart';

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
    return Consumer<MaintenanceProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  provider.error!,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.getById(issueId),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final issue = provider.selectedIssue;
        if (issue == null) {
          // Trigger a fetch if the issue is not in the provider
          // This can happen if the user navigates directly to the page
          Future.microtask(() => provider.getById(issueId));
          return const Center(child: CircularProgressIndicator());
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
          _ActionCard(issue: issue), // Pass the issue directly
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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                          context.read<ApiService>().makeAbsoluteUrl(
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

// Converted to StatefulWidget to manage its own state
class _ActionCard extends StatefulWidget {
  final MaintenanceIssue issue;
  const _ActionCard({required this.issue});

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  late IssueStatus _selectedStatus;
  final TextEditingController costController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.issue.status;
    costController.text = widget.issue.cost?.toString() ?? '';
    notesController.text = widget.issue.resolutionNotes ?? '';

    costController.addListener(_checkForChanges);
    notesController.addListener(_checkForChanges);
  }

  @override
  void dispose() {
    costController.removeListener(_checkForChanges);
    notesController.removeListener(_checkForChanges);
    costController.dispose();
    notesController.dispose();
    super.dispose();
  }

  void _checkForChanges() {
    final costChanged = (double.tryParse(costController.text) ?? 0) != (widget.issue.cost ?? 0);
    final notesChanged = notesController.text != (widget.issue.resolutionNotes ?? '');
    final statusChanged = _selectedStatus != widget.issue.status;

    if (mounted) {
      setState(() {
        _hasChanges = costChanged || notesChanged || statusChanged;
      });
    }
  }

  void _updateStatus(IssueStatus newStatus) {
    if (mounted) {
      setState(() {
        _selectedStatus = newStatus;
        _checkForChanges();
      });
    }
  }

  Future<void> _saveChanges() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      await context.read<MaintenanceProvider>().updateStatus(
        widget.issue.maintenanceIssueId.toString(),
        _selectedStatus,
        resolutionNotes: notesController.text.isNotEmpty ? notesController.text : null,
        cost: double.tryParse(costController.text),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Status updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        _hasChanges = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Change Status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatusSelection(context),
            const SizedBox(height: 16),
            if (_selectedStatus == IssueStatus.completed)
              Column(
                children: [
                  TextFormField(
                    controller: costController,
                    decoration: const InputDecoration(
                      labelText: 'Resolution Cost',
                      prefixText: '\$',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Resolution Notes',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading || !_hasChanges ? null : _saveChanges,
                  icon: _isLoading
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

  Widget _buildStatusSelection(BuildContext context) {
    return Column(
      children: IssueStatus.values.map((status) {
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
            groupValue: _selectedStatus,
            onChanged: (IssueStatus? value) {
              if (value != null) {
                _updateStatus(value);
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
