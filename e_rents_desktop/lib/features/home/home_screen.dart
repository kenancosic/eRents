import 'package:flutter/material.dart';
import 'package:e_rents_desktop/base/app_base_screen.dart';
import 'package:e_rents_desktop/base/base_provider.dart';
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
import 'package:e_rents_desktop/features/home/providers/home_provider.dart';
import 'package:e_rents_desktop/widgets/loading_or_error_widget.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load initial data using the new HomeProvider
      Provider.of<HomeProvider>(context, listen: false).loadDashboardData();
    });
  }

  void _navigateToProperties(BuildContext context) {
    context.go('/properties');
  }

  void _navigateToMaintenance(BuildContext context) {
    context.go('/maintenance');
  }

  void _navigateToReports(BuildContext context) {
    context.go('/reports');
  }

  void _viewPropertyDetails(BuildContext context, String propertyId) {
    context.go('/properties/$propertyId');
  }

  void _viewMaintenanceIssue(BuildContext context, String issueId) {
    context.go('/maintenance/$issueId');
  }

  @override
  Widget build(BuildContext context) {
    final homeProvider = Provider.of<HomeProvider>(context);

    // Determine the current path for AppBaseScreen
    final currentPath =
        GoRouter.of(context).routerDelegate.currentConfiguration.uri.toString();

    return AppBaseScreen(
      title: 'Dashboard',
      currentPath: currentPath,
      child: LoadingOrErrorWidget(
        isLoading: homeProvider.state == ViewState.Busy,
        error: homeProvider.errorMessage,
        onRetry: () => homeProvider.loadDashboardData(),
        child: RefreshIndicator(
          onRefresh: () => homeProvider.loadDashboardData(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // KPIs Section
                Row(
                  children: <Widget>[
                    Expanded(
                      child: InkWell(
                        onTap: () => _navigateToProperties(context),
                        child: KpiCard(
                          title: 'Total Properties',
                          value: homeProvider.propertyCount.toString(),
                          icon: Icons.home_work_outlined,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () => _navigateToProperties(context),
                        child: KpiCard(
                          title: 'Occupancy Rate',
                          value:
                              '${(homeProvider.occupancyRate * 100).toStringAsFixed(1)}%',
                          icon: Icons.people_alt_outlined,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () => _navigateToMaintenance(context),
                        child: KpiCard(
                          title: 'Open Issues',
                          value: homeProvider.openIssuesCount.toString(),
                          icon: Icons.build_circle_outlined,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () => _navigateToReports(context),
                        child: KpiCard(
                          title: 'Monthly Revenue',
                          value:
                              '\$${homeProvider.currentMonthRevenueForKpi.toStringAsFixed(2)}',
                          icon: Icons.attach_money_outlined,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Financial Summary
                if (homeProvider.uiFinancialStatistics != null)
                  FinancialSummaryCard(
                    income: homeProvider.uiFinancialStatistics!.totalRent,
                    expenses:
                        homeProvider
                            .uiFinancialStatistics!
                            .totalMaintenanceCosts,
                    netProfit: homeProvider.uiFinancialStatistics!.netTotal,
                    currencyFormat: kCurrencyFormat,
                  ),
                const SizedBox(height: 24),

                // Property and Maintenance Insights (Side-by-Side)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: PropertyInsightsCard(
                        properties: homeProvider.properties,
                        currencyFormat: kCurrencyFormat,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: MaintenanceOverviewCard(
                        pendingIssues: homeProvider.pendingIssues,
                        highPriorityIssues: homeProvider.highPriorityIssues,
                        tenantComplaints: homeProvider.tenantComplaints,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // TODO: Consider adding recent activity or tenant communication snippets if applicable
              ],
            ),
          ),
        ),
      ),
    );
  }
}
