import 'package:e_rents_desktop/base/app_base_screen.dart';
import 'package:e_rents_desktop/features/home/providers/home_provider.dart';
import 'package:e_rents_desktop/features/home/widgets/financial_summary_card.dart';
import 'package:e_rents_desktop/features/home/widgets/kpi_card.dart';
import 'package:e_rents_desktop/features/home/widgets/maintenance_overview_card.dart';
import 'package:e_rents_desktop/features/home/widgets/property_insights_card.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/utils/constants.dart';
import 'package:e_rents_desktop/widgets/loading_or_error_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/utils/formatters.dart';
import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/features/auth/providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Use WidgetsBinding.instance.addPostFrameCallback to ensure that the provider
    // is accessed after the widget tree has been built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HomeProvider>(context, listen: false).loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    final theme = Theme.of(context);

    return AppBaseScreen(
      title: 'Dashboard',
      currentPath: '/',
      child: Consumer<HomeProvider>(
        builder: (context, homeProvider, _) {
          final Widget mainContent = RefreshIndicator(
            onRefresh: () => homeProvider.loadDashboardData(),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(kDefaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (user != null)
                    Padding(
                      padding: EdgeInsets.only(bottom: kDefaultPadding),
                      child: Text(
                        'Welcome back, ${user.firstName ?? 'User'}!',
                        style: theme.textTheme.headlineSmall,
                      ),
                    ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount =
                          constraints.maxWidth > 1200
                              ? 4
                              : constraints.maxWidth > 800
                              ? 2
                              : 1;
                      final childAspectRatio =
                          constraints.maxWidth > 800
                              ? (constraints.maxWidth / crossAxisCount / 150)
                              : 2.5;

                      return GridView.count(
                        crossAxisCount: crossAxisCount,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: kDefaultPadding,
                        mainAxisSpacing: kDefaultPadding,
                        childAspectRatio: childAspectRatio,
                        children: [
                          InkWell(
                            onTap: () => context.go('/properties'),
                            child: KpiCard(
                              title: 'Total Properties',
                              value: homeProvider.propertyCount.toString(),
                              icon: Icons.business_outlined,
                              color: Colors.blue,
                            ),
                          ),
                          InkWell(
                            onTap: () => context.go('/reports'), // Placeholder
                            child: KpiCard(
                              title: 'Occupancy Rate',
                              value:
                                  '${(homeProvider.occupancyRate * 100).toStringAsFixed(1)}%',
                              icon: Icons.people_alt_outlined,
                              color: Colors.green,
                            ),
                          ),
                          InkWell(
                            onTap: () => context.go('/maintenance'),
                            child: KpiCard(
                              title: 'Pending Issues',
                              value: homeProvider.openIssuesCount.toString(),
                              icon: Icons.build_outlined,
                              color: Colors.orange,
                            ),
                          ),
                          InkWell(
                            onTap: () => context.go('/reports'), // Placeholder
                            child: KpiCard(
                              title: 'Net Income (This Month)',
                              value: kCurrencyFormat.format(
                                homeProvider.netIncome,
                              ),
                              icon: Icons.attach_money_outlined,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: kDefaultPadding),
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
                  SizedBox(height: kDefaultPadding),
                  PropertyInsightsCard(
                    properties: homeProvider.properties,
                    currencyFormat: kCurrencyFormat,
                  ),
                  SizedBox(height: kDefaultPadding),
                  MaintenanceOverviewCard(
                    pendingIssues: homeProvider.pendingIssues,
                    highPriorityIssues: homeProvider.highPriorityIssues,
                    tenantComplaints: homeProvider.tenantComplaints,
                  ),
                ],
              ),
            ),
          );

          return LoadingOrErrorWidget(
            isLoading: homeProvider.state == ViewState.Busy,
            error: homeProvider.errorMessage,
            onRetry: () => homeProvider.loadDashboardData(),
            child: mainContent,
          );
        },
      ),
    );
  }
}
