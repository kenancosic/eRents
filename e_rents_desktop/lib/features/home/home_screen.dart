import 'package:flutter/material.dart';
import 'package:e_rents_desktop/base/app_base_screen.dart';
import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/features/maintenance/providers/maintenance_provider.dart';
import 'package:e_rents_desktop/features/properties/providers/property_provider.dart';
import 'package:e_rents_desktop/features/statistics/providers/statistics_provider.dart';
import 'package:e_rents_desktop/features/home/widgets/maintenance_overview_card.dart';
import 'package:e_rents_desktop/features/home/widgets/kpi_card.dart';
import 'package:e_rents_desktop/features/home/widgets/financial_summary_card.dart';
import 'package:e_rents_desktop/features/home/widgets/property_insights_card.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:e_rents_desktop/models/statistics/financial_statistics.dart';
import 'package:e_rents_desktop/utils/formatters.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const double _padding = 16.0;
  static const double _cardSpacing = 16.0;

  @override
  Widget build(BuildContext context) {
    return AppBaseScreen(
      title: 'Dashboard',
      currentPath: '/',
      child:
          Consumer3<MaintenanceProvider, PropertyProvider, StatisticsProvider>(
            builder: (
              context,
              maintenanceProvider,
              propertyProvider,
              statsProvider,
              child,
            ) {
              final pendingIssues = maintenanceProvider.getIssuesByStatus(
                IssueStatus.pending,
              );
              final highPriorityIssues = maintenanceProvider
                  .getIssuesByPriority(IssuePriority.high);
              final tenantComplaints =
                  maintenanceProvider.getTenantComplaints();
              final properties = propertyProvider.properties;
              final financialStats = statsProvider.statistics;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(_padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeSection(context),
                    const SizedBox(height: _padding),

                    _buildKpiSection(
                      context: context,
                      propertyCount: properties.length,
                      occupancyRate: _calculateOccupancy(properties),
                      openIssues: pendingIssues.length,
                      netIncome: financialStats?.netTotal ?? 0.0,
                    ),
                    const SizedBox(height: _padding),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        const double breakPoint = 1100.0;

                        final maintenanceSection = _buildMaintenanceSection(
                          context,
                          pendingIssues,
                          highPriorityIssues,
                          tenantComplaints,
                        );
                        final financialSection = _buildFinancialSection(
                          context,
                          financialStats,
                        );

                        if (constraints.maxWidth < breakPoint) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              maintenanceSection,
                              const SizedBox(height: _padding),
                              financialSection,
                            ],
                          );
                        } else {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: maintenanceSection),
                              const SizedBox(width: _padding),
                              Expanded(child: financialSection),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: _padding),

                    _buildSectionHeader(context, 'Property Insights'),
                    const SizedBox(height: _cardSpacing / 2),
                    PropertyInsightsCard(
                      properties: properties,
                      currencyFormat: kCurrencyFormat,
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
          style: Theme.of(
            context,
          ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Here\'s your property management dashboard overview.',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildKpiSection({
    required BuildContext context,
    required int propertyCount,
    required double occupancyRate,
    required int openIssues,
    required double netIncome,
  }) {
    return Wrap(
      spacing: _cardSpacing,
      runSpacing: _cardSpacing,
      children: [
        KpiCard(
          title: 'Total Properties',
          value: propertyCount.toString(),
          icon: Icons.business_rounded,
        ),
        KpiCard(
          title: 'Occupancy Rate',
          value: '${kCurrencyFormat.format(occupancyRate * 100)}%',
          icon: Icons.people_alt_rounded,
        ),
        KpiCard(
          title: 'Open Issues',
          value: openIssues.toString(),
          icon: Icons.build_circle_outlined,
        ),
        KpiCard(
          title: 'Net Income (Period)',
          value: kCurrencyFormat.format(netIncome),
          icon: Icons.money_rounded,
          color: netIncome >= 0 ? Colors.green.shade700 : Colors.red.shade700,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildMaintenanceSection(
    BuildContext context,
    List<MaintenanceIssue> pending,
    List<MaintenanceIssue> highPriority,
    List<MaintenanceIssue> complaints,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Maintenance Overview'),
        const SizedBox(height: _cardSpacing / 2),
        MaintenanceOverviewCard(
          pendingIssues: pending,
          highPriorityIssues: highPriority,
          tenantComplaints: complaints,
        ),
      ],
    );
  }

  Widget _buildFinancialSection(
    BuildContext context,
    FinancialStatistics? stats,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Financial Snapshot'),
        const SizedBox(height: _cardSpacing / 2),
        FinancialSummaryCard(
          income: stats?.totalRent ?? 0.0,
          expenses: stats?.totalMaintenanceCosts ?? 0.0,
          netProfit: stats?.netTotal ?? 0.0,
          currencyFormat: kCurrencyFormat,
        ),
      ],
    );
  }

  double _calculateOccupancy(List<Property> properties) {
    if (properties.isEmpty) return 0.0;
    final rentedCount =
        properties.where((p) => p.status != PropertyStatus.available).length;
    return rentedCount / properties.length;
  }
}
