import 'package:e_rents_desktop/features/maintenance/providers/maintenance_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/services/image_service.dart';
import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:e_rents_desktop/presentation/extensions.dart';
import 'package:e_rents_desktop/models/enums/enums.dart';
import 'package:e_rents_desktop/presentation/badges.dart';

import 'package:go_router/go_router.dart';
import 'package:e_rents_desktop/utils/date_utils.dart';
import 'package:e_rents_desktop/base/crud/detail_screen.dart';

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
    final provider = context.read<MaintenanceProvider>();

    return DetailScreen<MaintenanceIssue>(
      title: 'Maintenance Issue',
      item: issue ?? MaintenanceIssue.empty(),
      itemId: issueId,
      fetchItem: (id) async {
        await provider.getById(id);
        final fetched = provider.selectedIssue;
        if (fetched == null) {
          throw Exception('Issue not found');
        }
        return fetched;
      },
      onEdit: (item) => context.push('/maintenance/${item.maintenanceIssueId}/edit'),
      detailBuilder: (ctx, item) => _MaintenanceIssueDetailsView(issue: item),
      additionalActions: [
        TextButton.icon(
          onPressed: () => context.push('/properties/${issue?.propertyId ?? provider.selectedIssue?.propertyId}') ,
          icon: const Icon(Icons.home),
          label: const Text('View Property'),
        ),
      ],
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
    // App bar is provided by DetailScreen; we show a right-aligned status chip
    return Row(
      children: [
        const Spacer(),
        _buildStatusChip(),
      ],
    );
  }

  Widget _buildStatusChip() {
    // Softer badge with icon using shared UI extensions
    return StatusBadge(status: issue.status, showIcon: true, variant: BadgeVariant.solid);
  }

  Widget _buildIssueDetails() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    color: issue.priority.color,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  issue.priority.displayName,
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
              'Reported by ${issue.tenantName} (Tenant ID: ${issue.tenantId}) • ${AppDateUtils.formatRelative(issue.createdAt)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 24),
            Text(
              'Description',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(issue.description!, style: const TextStyle(fontSize: 16)),
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
                      child: GestureDetector(
                        onTap: () => context.push(
                          '/property-images',
                          extra: {
                            'images': issue.imageIds,
                            'initialIndex': index,
                          },
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: context.read<ImageService>().buildImageByIdSimple(
                            imageId,
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                            errorWidget: Container(
                              width: 200,
                              height: 200,
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.broken_image),
                            ),
                          ),
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
  late MaintenanceIssue issue;
  late TextEditingController costController;
  late TextEditingController notesController;
  late FocusNode costFocusNode;
  late FocusNode notesFocusNode;

  late MaintenanceIssueStatus _selectedStatus;

  bool _isLoading = false;
  String? _errorMessage;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    issue = widget.issue;
    costController = TextEditingController();
    notesController = TextEditingController();
    costFocusNode = FocusNode();
    notesFocusNode = FocusNode();

    _selectedStatus = issue.status;
    costController.text = issue.cost?.toString() ?? '';
    notesController.text = issue.resolutionNotes ?? '';

    costController.addListener(_checkForChanges);
    notesController.addListener(_checkForChanges);
  }

  @override
  void dispose() {
    costController.removeListener(_checkForChanges);
    notesController.removeListener(_checkForChanges);
    costController.dispose();
    notesController.dispose();
    costFocusNode.dispose();
    notesFocusNode.dispose();
    super.dispose();
  }

  void _checkForChanges() {
    final costChanged =
        (double.tryParse(costController.text) ?? 0) != (issue.cost ?? 0);
    final notesChanged =
        notesController.text != (issue.resolutionNotes ?? '');
    final statusChanged = _selectedStatus != issue.status;

    if (mounted) {
      setState(() {
        _hasChanges = costChanged || notesChanged || statusChanged;
      });
    }
  }

  void _updateStatus(MaintenanceIssueStatus newStatus) {
    setState(() {
      _selectedStatus = newStatus;
      _checkForChanges();
    });
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await context.read<MaintenanceProvider>().updateIssueStatus(
        issue.maintenanceIssueId.toString(),
        _selectedStatus,
        resolutionNotes: notesController.text.isEmpty ? null : notesController.text,
        cost: costController.text.isEmpty ? null : double.tryParse(costController.text),
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
          SnackBar(content: Text(_errorMessage!), backgroundColor: Colors.red),
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
            if (_selectedStatus == MaintenanceIssueStatus.completed)
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
      children: MaintenanceIssueStatus.values.map((status) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: RadioListTile<MaintenanceIssueStatus>(
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
            onChanged: (MaintenanceIssueStatus? value) {
              if (value != null) {
                _updateStatus(value);
              }
            },
          ),
        );
      }).toList(),
    );
  }

  IconData _getStatusIcon(MaintenanceIssueStatus status) {
    // Use centralized UI extension icon
    return status.icon;
  }

  Color _getStatusColor(MaintenanceIssueStatus status) {
    // Use centralized UI extension color
    return status.color;
  }

  String _getStatusDescription(MaintenanceIssueStatus status) {
    switch (status) {
      case MaintenanceIssueStatus.pending:
        return 'Issue reported, waiting to be addressed';
      case MaintenanceIssueStatus.inProgress:
        return 'Work is currently in progress';
      case MaintenanceIssueStatus.completed:
        return 'Issue has been resolved';
      case MaintenanceIssueStatus.cancelled:
        return 'Issue has been cancelled';
    }
  }

  String _getStatusDisplayName(MaintenanceIssueStatus status) {
    // Use enum display name extension
    return status.displayName;
  }
}
