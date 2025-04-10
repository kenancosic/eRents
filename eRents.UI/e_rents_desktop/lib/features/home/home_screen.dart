import 'package:flutter/material.dart';
import 'package:e_rents_desktop/base/app_base_screen.dart';
import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:e_rents_desktop/features/maintenance/providers/maintenance_provider.dart';
import 'package:e_rents_desktop/features/properties/providers/property_provider.dart';
import 'package:e_rents_desktop/features/home/widgets/maintenance_overview_card.dart';
import 'package:e_rents_desktop/features/home/widgets/property_stats_card.dart';
import 'package:e_rents_desktop/features/home/widgets/property_list_card.dart';
import 'package:e_rents_desktop/features/home/widgets/recent_issues_card.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBaseScreen(
      title: 'Home',
      currentPath: '/',
      child: Consumer2<MaintenanceProvider, PropertyProvider>(
        builder: (context, maintenanceProvider, propertyProvider, child) {
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
                // Statistics Section
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 1000) {
                      // Stack cards vertically on smaller screens
                      return Column(
                        children: [
                          PropertyStatsCard(
                            properties: propertyProvider.properties,
                          ),
                          const SizedBox(height: 24),
                          MaintenanceOverviewCard(
                            pendingIssues: pendingIssues,
                            highPriorityIssues: highPriorityIssues,
                            tenantComplaints: tenantComplaints,
                          ),
                        ],
                      );
                    } else {
                      // Use row layout on larger screens
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: PropertyStatsCard(
                              properties: propertyProvider.properties,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: MaintenanceOverviewCard(
                              pendingIssues: pendingIssues,
                              highPriorityIssues: highPriorityIssues,
                              tenantComplaints: tenantComplaints,
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 24),
                // Property List and Recent Issues Section
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 1200) {
                      // Stack cards vertically on smaller screens
                      return Column(
                        children: [
                          PropertyListCard(
                            properties: propertyProvider.properties,
                          ),
                          const SizedBox(height: 24),
                          RecentIssuesCard(issues: issues),
                        ],
                      );
                    } else {
                      // Use row layout on larger screens
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: PropertyListCard(
                              properties: propertyProvider.properties,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(child: RecentIssuesCard(issues: issues)),
                        ],
                      );
                    }
                  },
                ),
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
}
