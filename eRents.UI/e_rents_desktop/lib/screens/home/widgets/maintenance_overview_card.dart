import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/maintenance_issue.dart';

class MaintenanceOverviewCard extends StatelessWidget {
  final List<MaintenanceIssue> pendingIssues;
  final List<MaintenanceIssue> highPriorityIssues;
  final List<MaintenanceIssue> tenantComplaints;

  const MaintenanceOverviewCard({
    super.key,
    required this.pendingIssues,
    required this.highPriorityIssues,
    required this.tenantComplaints,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Maintenance Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Pending Issues',
                    pendingIssues.length.toString(),
                    Colors.orange,
                    Icons.pending_actions,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'High Priority',
                    highPriorityIssues.length.toString(),
                    Colors.red,
                    Icons.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatItem(
              context,
              'Tenant Complaints',
              tenantComplaints.length.toString(),
              Colors.blue,
              Icons.message,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}
