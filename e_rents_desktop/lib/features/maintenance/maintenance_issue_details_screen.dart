import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:e_rents_desktop/features/maintenance/providers/maintenance_detail_provider.dart';
import 'package:e_rents_desktop/base/base.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_desktop/utils/date_utils.dart';

class MaintenanceIssueDetailsScreen extends StatefulWidget {
  final MaintenanceIssue? issue;
  final String issueId;

  const MaintenanceIssueDetailsScreen({
    super.key,
    this.issue,
    required this.issueId,
  });

  @override
  State<MaintenanceIssueDetailsScreen> createState() =>
      _MaintenanceIssueDetailsScreenState();
}

class _MaintenanceIssueDetailsScreenState
    extends State<MaintenanceIssueDetailsScreen> {
  late MaintenanceIssue? _issue;
  late String _issueId;
  late TextEditingController _costController;
  late TextEditingController _notesController;
  late IssueStatus _selectedStatus;
  late IssueStatus _originalStatus;

  @override
  void initState() {
    super.initState();
    _issue = widget.issue;
    _issueId = widget.issueId;
    _costController = TextEditingController();
    _notesController = TextEditingController(text: 'Work completed.');
    _selectedStatus = _issue?.status ?? IssueStatus.pending;
    _originalStatus = _selectedStatus;
  }

  @override
  void dispose() {
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent(context);
  }

  Widget _buildContent(BuildContext context) {
    // Use Consumer to get issue from DetailProvider (loaded by router factory method)
    return Consumer<MaintenanceDetailProvider>(
      builder: (context, provider, child) {
        // Show loading state if provider is loading
        if (provider.state == ProviderState.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Show error state if there's an error
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
                  onPressed: () => provider.loadItem(_issueId),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Get issue from provider
        final issue = provider.item;
        if (issue != null) {
          return _buildIssueContent(context, issue);
        } else {
          // If issue not found, show not found error
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Maintenance issue not found',
                  style: TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go('/maintenance'),
                  child: const Text('Back to Maintenance'),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildIssueContent(BuildContext context, MaintenanceIssue issue) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, issue),
          const SizedBox(height: 24),
          _buildIssueDetails(issue),
          const SizedBox(height: 24),
          _buildActions(context, issue),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, MaintenanceIssue issue) {
    final router = GoRouter.of(context);
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (router.canPop()) {
              router.pop();
            } else {
              // Fallback navigation if cannot pop
              router.go('/maintenance');
            }
          },
          tooltip: 'Go back',
        ),
        const Spacer(),
        _buildStatusChip(issue),
      ],
    );
  }

  Widget _buildStatusChip(MaintenanceIssue issue) {
    return Chip(
      label: Text(
        issue.status.toString().split('.').last,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: issue.statusColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    );
  }

  Widget _buildIssueDetails(MaintenanceIssue issue) {
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
              'Reported by ${issue.reportedBy} • ${_formatTimeAgo(issue.createdAt)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 24),
            Text(
              'Description',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(issue.description, style: const TextStyle(fontSize: 16)),
            if (issue.images.isNotEmpty) ...[
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
                  itemCount: issue.images.length,
                  itemBuilder: (context, index) {
                    final image = issue.images[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child:
                            image.url != null && image.url!.isNotEmpty
                                ? Image.network(
                                  image.url!,
                                  width: 200,
                                  fit: BoxFit.cover,
                                )
                                : Image.asset(
                                  'assets/images/placeholder.jpg',
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

  Widget _buildActions(BuildContext context, MaintenanceIssue issue) {
    final provider = Provider.of<MaintenanceDetailProvider>(
      context,
      listen: false,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Change Status',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatusSelection(issue),
                const SizedBox(height: 16),
                if (_selectedStatus == IssueStatus.completed) ...[
                  TextField(
                    controller: _costController,
                    decoration: const InputDecoration(
                      labelText: 'Resolution Cost',
                      prefixText: '\$',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Resolution Notes',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed:
                          _canSaveChanges(issue)
                              ? () => _saveChanges(provider, issue)
                              : null,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Changes'),
                    ),
                    const SizedBox(width: 16),
                    if (_canSaveChanges(issue))
                      TextButton(
                        onPressed: _resetChanges,
                        child: const Text('Reset'),
                      ),
                  ],
                ),
                if (issue.maintenanceIssueId == 0 && _hasChanges()) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Note: Status changes can only be saved for existing issues.',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
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
    );
  }

  Widget _buildStatusSelection(MaintenanceIssue issue) {
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
                groupValue: _selectedStatus,
                onChanged: (IssueStatus? value) {
                  if (value != null) {
                    setState(() {
                      _selectedStatus = value;
                      if (value == IssueStatus.completed &&
                          _notesController.text.isEmpty) {
                        _notesController.text = 'Work completed.';
                      }
                    });
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

  bool _hasChanges() {
    return _selectedStatus != _originalStatus ||
        (_selectedStatus == IssueStatus.completed &&
            _costController.text.isNotEmpty);
  }

  bool _canSaveChanges(MaintenanceIssue issue) {
    return _hasChanges() && issue.maintenanceIssueId != 0;
  }

  void _resetChanges() {
    setState(() {
      _selectedStatus = _originalStatus;
      _costController.clear();
      _notesController.text = 'Work completed.';
    });
  }

  void _saveChanges(
    MaintenanceDetailProvider provider,
    MaintenanceIssue issue,
  ) {
    // Validate that we have a valid issue ID
    if (issue.maintenanceIssueId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot update status for unsaved issue. Please save the issue first and try again.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _saveChangesForIssue(provider, issue);
  }

  void _saveChangesForIssue(
    MaintenanceDetailProvider provider,
    MaintenanceIssue issue,
  ) {
    final cost =
        _selectedStatus == IssueStatus.completed
            ? double.tryParse(_costController.text)
            : null;
    final notes =
        _selectedStatus == IssueStatus.completed &&
                _notesController.text.isNotEmpty
            ? _notesController.text
            : null;

    provider.updateIssueStatus(
      _selectedStatus,
      resolutionNotes: notes,
      cost: cost,
    );

    setState(() {
      _originalStatus = _selectedStatus;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Status updated to ${_getStatusDisplayName(_selectedStatus)}',
        ),
        backgroundColor: Colors.green,
      ),
    );
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

  String _formatTimeAgo(DateTime dateTime) {
    return AppDateUtils.formatRelative(dateTime);
  }
}
