import 'package:flutter/material.dart';
import 'package:e_rents_desktop/base/app_base_screen.dart';
import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:e_rents_desktop/providers/maintenance_provider.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBaseScreen(
      title: 'Home',
      currentPath: '/',
      child: Consumer<MaintenanceProvider>(
        builder: (context, maintenanceProvider, child) {
          final issues = maintenanceProvider.issues;
          final pendingIssues = maintenanceProvider.getIssuesByStatus(
            IssueStatus.pending,
          );
          final highPriorityIssues = maintenanceProvider.getIssuesByPriority(
            IssuePriority.high,
          );
          final tenantComplaints = maintenanceProvider.getTenantComplaints();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeSection(context),
                const SizedBox(height: 24),
                _buildMaintenanceOverview(
                  context,
                  pendingIssues,
                  highPriorityIssues,
                  tenantComplaints,
                ),
                const SizedBox(height: 24),
                _buildRecentIssues(context, issues),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back!',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Here\'s what\'s happening with your properties',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildMaintenanceOverview(
    BuildContext context,
    List<MaintenanceIssue> pendingIssues,
    List<MaintenanceIssue> highPriorityIssues,
    List<MaintenanceIssue> tenantComplaints,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Maintenance Overview',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard(
                  context,
                  'Pending Issues',
                  pendingIssues.length.toString(),
                  Colors.orange,
                  Icons.pending_actions,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  context,
                  'High Priority',
                  highPriorityIssues.length.toString(),
                  Colors.red,
                  Icons.warning,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  context,
                  'Tenant Complaints',
                  tenantComplaints.length.toString(),
                  Colors.blue,
                  Icons.message,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentIssues(
    BuildContext context,
    List<MaintenanceIssue> issues,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Maintenance Issues',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to full maintenance issues screen
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (issues.isEmpty)
              const Center(child: Text('No maintenance issues found'))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: issues.length > 5 ? 5 : issues.length,
                itemBuilder: (context, index) {
                  final issue = issues[index];
                  return _buildIssueItem(context, issue);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssueItem(BuildContext context, MaintenanceIssue issue) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: issue.priorityColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            _getIssueIcon(issue.category),
            color: issue.priorityColor,
          ),
        ),
        title: Text(issue.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(issue.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: issue.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    issue.status.toString().split('.').last,
                    style: TextStyle(color: issue.statusColor, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                if (issue.isTenantComplaint)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Tenant Complaint',
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: Text(
          _formatDate(issue.createdAt),
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        onTap: () {
          // TODO: Navigate to issue details
        },
      ),
    );
  }

  IconData _getIssueIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'plumbing':
        return Icons.plumbing;
      case 'electrical':
        return Icons.electric_bolt;
      case 'structural':
        return Icons.home_repair_service;
      default:
        return Icons.build;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
