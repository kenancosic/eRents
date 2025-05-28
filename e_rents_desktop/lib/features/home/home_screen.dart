import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/features/home/providers/home_provider.dart';
import 'package:e_rents_desktop/features/home/widgets/financial_summary_card.dart';
import 'package:e_rents_desktop/features/home/widgets/kpi_card.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_desktop/utils/constants.dart';
import 'package:e_rents_desktop/widgets/loading_or_error_widget.dart';
import 'package:e_rents_desktop/utils/formatters.dart';
import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/features/auth/providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticatedState) {
        Provider.of<HomeProvider>(context, listen: false).loadDashboardData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<HomeProvider, AuthProvider>(
      builder: (context, homeProvider, authProvider, _) {
        final user = authProvider.currentUser;
        final theme = Theme.of(context);

        // If not authenticated, show login prompt
        if (!authProvider.isAuthenticatedState) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(height: kDefaultPadding),
                Text(
                  'Please log in to view your dashboard',
                  style: theme.textTheme.headlineSmall,
                ),
                SizedBox(height: kDefaultPadding),
                ElevatedButton(
                  onPressed: () => context.go('/login'),
                  child: Text('Go to Login'),
                ),
              ],
            ),
          );
        }

        final Widget mainContent = RefreshIndicator(
          onRefresh: () async {
            if (authProvider.isAuthenticatedState) {
              await homeProvider.loadDashboardData();
            }
          },
          child: SingleChildScrollView(
            padding: EdgeInsets.all(kDefaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (user != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: kDefaultPadding),
                    child: Text(
                      'Welcome back, ${user.firstName}!',
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
                if (homeProvider.dashboardStatistics != null)
                  FinancialSummaryCard(
                    income: homeProvider.totalRent,
                    expenses: homeProvider.totalMaintenanceCosts,
                    netProfit: homeProvider.netTotal,
                    currencyFormat: kCurrencyFormat,
                  ),
                SizedBox(height: kDefaultPadding),
                // ActivityFeedCard(activities: homeProvider.recentActivities), // Deprecated - RecentActivity model removed
                // Placeholder for activity feed - can be replaced with alternative implementation
              ],
            ),
          ),
        );

        return LoadingOrErrorWidget(
          isLoading: homeProvider.state == ViewState.Busy,
          error: homeProvider.errorMessage,
          onRetry: () {
            if (authProvider.isAuthenticatedState) {
              homeProvider.loadDashboardData();
            }
          },
          child: mainContent,
        );
      },
    );
  }
}
