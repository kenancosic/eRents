import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/features/home/providers/home_provider.dart';
import 'package:e_rents_desktop/features/home/widgets/kpi_card.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_desktop/utils/constants.dart';
import 'package:e_rents_desktop/widgets/loading_or_error_widget.dart';
import 'package:e_rents_desktop/utils/formatters.dart'; // Keep for kCurrencyFormat
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isAuthenticated) {
        context.read<HomeProvider>().fetchDashboardStatistics();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
        return Consumer2<HomeProvider, AuthProvider>(
            builder: (context, homeProvider, authProvider, _) {
        final user = authProvider.currentUser;
        final theme = Theme.of(context);

        if (!authProvider.isAuthenticated) {
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
                  'Please log in to view your landlord dashboard',
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
            if (authProvider.isAuthenticated) {
              await homeProvider.fetchDashboardStatistics(forceRefresh: true);
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
                      'Welcome back, ${user.firstName}!', // Simplified message
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),

                _buildKPISection(context, homeProvider),

                SizedBox(height: kDefaultPadding * 1.5),

                _buildDashboardContent(context, homeProvider),
              ],
            ),
          ),
        );

        return LoadingOrErrorWidget(
          isLoading: homeProvider.isLoading,
          error: homeProvider.error,
          onRetry: () {
            if (authProvider.isAuthenticated) {
              homeProvider.fetchDashboardStatistics(forceRefresh: true);
            }
          },
          child: mainContent,
        );
      },
    );
  }

  Widget _buildKPISection(
    BuildContext context,
    HomeProvider homeProvider,
  ) {
    // Compact KPI set for the redesigned overview
    final activeToday = homeProvider.activeBookingsToday;
    final upcoming7d = homeProvider.upcomingCheckins7d;
    final monthlyRevenue = homeProvider.monthlyRevenue;
    final emergencyIssues = homeProvider.emergencyMaintenanceIssues;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount =
            constraints.maxWidth > 1200
                ? 4 // 4 KPIs: Active Today, Upcoming 7d, Revenue, Emergency Issues
                : constraints.maxWidth > 900
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
            KpiCard(
              title: 'Active Today',
              value: activeToday.toString(),
              icon: Icons.event_available_outlined,
              color: Colors.blue,
            ),
            KpiCard(
              title: 'Upcoming Check-ins (7d)',
              value: upcoming7d.toString(),
              icon: Icons.login_outlined,
              color: Colors.teal,
            ),
            KpiCard(
              title: 'Monthly Revenue',
              value: kCurrencyFormat.format(monthlyRevenue),
              icon: Icons.attach_money_outlined,
              color: Colors.purple,
            ),
            KpiCard(
              title: 'Emergency Issues',
              value: emergencyIssues.toString(),
              icon: Icons.report_gmailerrorred_outlined,
              color: Colors.red,
            ),
          ],
        );
      },
    );
  }

  Widget _buildDashboardContent(
    BuildContext context,
    HomeProvider homeProvider,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 1200;

        if (isWideScreen) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildEmergencyIssuesCard(context, homeProvider),
                  ],
                ),
              ),
              SizedBox(width: kDefaultPadding),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _buildQuickActionsCard(context),
                  ],
                ),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              _buildEmergencyIssuesCard(context, homeProvider),
              SizedBox(height: kDefaultPadding),
              _buildQuickActionsCard(context),
            ],
          );
        }
      },
    );
  }

  Widget _buildEmergencyIssuesCard(
    BuildContext context,
    HomeProvider homeProvider,
  ) {
    final theme = Theme.of(context);
    final issues = homeProvider.emergencyIssues;

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(kDefaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Emergency Maintenance Issues',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.open_in_new),
                  onPressed: () => context.go('/maintenance'),
                ),
              ],
            ),
            SizedBox(height: kDefaultPadding),
            if (issues.isEmpty)
              Center(
                child: Text(
                  'No emergency maintenance issues',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withAlpha((0.6 * 255).round()),
                  ),
                ),
              )
            else
              ...issues.take(10).map((issue) {
                return ListTile(
                  leading: Icon(Icons.report_problem, color: Colors.redAccent),
                  title: Text(issue.title),
                  subtitle: Text('Property ${issue.propertyId} • ${issue.priority.name} • ${issue.status.name}'),
                  trailing: Text(issue.createdAt.toLocal().toString().split(' ').first),
                  onTap: () => context.go('/maintenance/${issue.maintenanceIssueId}'),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(kDefaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: kDefaultPadding),
            ListTile(
              leading: Icon(Icons.add_business),
              title: Text('Add Property'),
              onTap: () => context.go('/properties/add'),
            ),
            ListTile(
              leading: Icon(Icons.analytics),
              title: Text('View Reports'),
              onTap: () => context.go('/reports'),
            ),
          ],
        ),
      ),
    );
  }
}
