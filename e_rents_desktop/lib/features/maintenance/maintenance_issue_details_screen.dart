import 'package:flutter/material.dart';
import 'package:e_rents_desktop/base/app_base_screen.dart';
import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:e_rents_desktop/features/maintenance/providers/maintenance_provider.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_desktop/base/base_provider.dart';

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
    return AppBaseScreen(
      title: 'Maintenance Issue',
      currentPath: '/maintenance',
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    // If issue was passed directly, show it
    if (issue != null) {
      return _buildIssueContent(context, issue!);
    }

    // Otherwise, use Consumer to listen for changes in the provider
    return Consumer<MaintenanceProvider>(
      builder: (context, provider, child) {
        // Show loading state if provider is loading
        if (provider.state == ViewState.Busy) {
          return const Center(child: CircularProgressIndicator());
        }

        // Show error state if there's an error
        if (provider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  provider.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.fetchIssues(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Try to find issue in provider
        try {
          final foundIssue = provider.issues.firstWhere((i) => i.id == issueId);
          return _buildIssueContent(context, foundIssue);
        } catch (_) {
          // If issue not found and provider is not loading, show not found error
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
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
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

  Widget _buildActions(BuildContext context, MaintenanceIssue issue) {
    final provider = Provider.of<MaintenanceProvider>(context, listen: false);

    return Row(
      children: [
        if (issue.status == IssueStatus.pending) ...[
          ElevatedButton.icon(
            onPressed: () {
              provider.updateIssueStatus(issue.id, IssueStatus.inProgress);
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Work'),
          ),
          const SizedBox(width: 16),
        ],
        if (issue.status == IssueStatus.inProgress) ...[
          ElevatedButton.icon(
            onPressed: () {
              // Potentially show a dialog to enter cost and resolution notes
              // For now, just mark as complete.
              provider.updateIssueStatus(
                issue.id,
                IssueStatus.completed,
                resolutionNotes: "Work completed.",
              );
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
              provider.updateIssueStatus(issue.id, IssueStatus.cancelled);
            },
            icon: const Icon(Icons.cancel),
            label: const Text('Cancel Issue'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
        const Spacer(),
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
