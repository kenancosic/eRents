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
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      // Use less vertical padding than FinancialSummaryCard to make it less tall
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          // No need for internal Column if using ListTiles directly
          children: [
            // Removed internal header, handled by _buildSectionHeader in home_screen
            _buildOverviewTile(
              context: context,
              icon: Icons.pending_actions_outlined,
              iconColor: Colors.orange.shade700,
              title: 'Pending Issues',
              value: pendingIssues.length.toString(),
              valueColor:
                  pendingIssues.isNotEmpty ? Colors.orange.shade800 : null,
              // Optional: Add onTap to navigate
              // onTap: () => print('Navigate to Pending Issues'),
            ),
            const Divider(height: 1), // Use thin dividers
            _buildOverviewTile(
              context: context,
              icon: Icons.warning_amber_rounded,
              iconColor: Colors.red.shade700,
              title: 'High Priority Issues',
              value: highPriorityIssues.length.toString(),
              valueColor:
                  highPriorityIssues.isNotEmpty ? Colors.red.shade800 : null,
              // onTap: () => print('Navigate to High Priority Issues'),
            ),
            const Divider(height: 1),
            _buildOverviewTile(
              context: context,
              icon: Icons.chat_bubble_outline_rounded,
              iconColor: Colors.blue.shade700,
              title: 'Tenant Complaints/Feedback',
              value: tenantComplaints.length.toString(),
              valueColor:
                  tenantComplaints.isNotEmpty ? Colors.blue.shade800 : null,
              // onTap: () => print('Navigate to Tenant Complaints'),
            ),
            // Can add more tiles here if needed (e.g., Overdue Issues)
          ],
        ),
      ),
    );
  }

  // Helper to build consistent ListTile style rows
  Widget _buildOverviewTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    Color? valueColor,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: textTheme.bodyLarge),
      trailing: Text(
        value,
        style: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: valueColor ?? textTheme.bodyMedium?.color?.withOpacity(0.8),
        ),
      ),
      onTap: onTap, // Add tap functionality
      dense: true, // Make tiles slightly more compact
      contentPadding: const EdgeInsets.symmetric(
        vertical: 4.0,
        horizontal: 8.0,
      ), // Adjust padding
    );
  }

  // Removed the old _buildStatItem method
}
