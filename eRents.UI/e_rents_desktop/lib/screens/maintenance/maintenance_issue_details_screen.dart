import 'package:flutter/material.dart';
import 'package:e_rents_desktop/base/app_base_screen.dart';
import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:e_rents_desktop/screens/properties/property_details_screen.dart';
import 'package:go_router/go_router.dart';

class MaintenanceIssueDetailsScreen extends StatelessWidget {
  final MaintenanceIssue issue;

  const MaintenanceIssueDetailsScreen({super.key, required this.issue});

  @override
  Widget build(BuildContext context) {
    return AppBaseScreen(
      title: 'Maintenance Issue',
      currentPath: '/maintenance',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            _buildIssueDetails(),
            const SizedBox(height: 24),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Go back',
        ),
        const SizedBox(width: 8),
        Text(
          'Back to ${issue.propertyId == null ? 'Maintenance' : 'Property'}',
          style: Theme.of(context).textTheme.titleMedium,
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
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          issue.images[index],
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

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        if (issue.status == IssueStatus.pending) ...[
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement start work action
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Work'),
          ),
          const SizedBox(width: 16),
        ],
        if (issue.status == IssueStatus.inProgress) ...[
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement complete action
            },
            icon: const Icon(Icons.check),
            label: const Text('Mark as Complete'),
          ),
          const SizedBox(width: 16),
        ],
        if (issue.status != IssueStatus.completed &&
            issue.status != IssueStatus.cancelled) ...[
          TextButton.icon(
            onPressed: () {
              // TODO: Implement cancel action
            },
            icon: const Icon(Icons.cancel),
            label: const Text('Cancel Issue'),
          ),
        ],
        const Spacer(),
        if (issue.propertyId != null)
          TextButton.icon(
            onPressed: () {
              context.go('/properties/${issue.propertyId}');
            },
            icon: const Icon(Icons.home),
            label: const Text('View Property'),
          ),
      ],
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inMinutes} minutes ago';
    }
  }
}
