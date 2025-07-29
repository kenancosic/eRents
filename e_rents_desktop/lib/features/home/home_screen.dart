import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/features/home/providers/home_provider.dart';
import 'package:e_rents_desktop/features/home/widgets/financial_summary_card.dart';
import 'package:e_rents_desktop/features/home/widgets/kpi_card.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_desktop/utils/constants.dart';
import 'package:e_rents_desktop/widgets/loading_or_error_widget.dart';
import 'package:e_rents_desktop/utils/formatters.dart';
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

        // If not authenticated, show login prompt
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
                // Welcome Message for Landlords
                if (user != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: kDefaultPadding),
                    child: Text(
                      'Welcome back, ${user.firstName}! Here\'s your property management overview.',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),

                // Key Performance Indicators
                _buildKPISection(context, homeProvider),

                SizedBox(height: kDefaultPadding * 1.5),

                // Dashboard Content Grid
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
    final stats = homeProvider.stats;
    return LayoutBuilder(
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
                value: stats?.totalProperties.toString() ?? '0',
                icon: Icons.business_outlined,
                color: Colors.blue,
              ),
            ),
            InkWell(
              onTap: () => context.go('/properties'),
              child: KpiCard(
                title: 'Occupancy Rate',
                value: '${((stats?.occupancyRate ?? 0.0) * 100).toStringAsFixed(1)}%',
                icon: Icons.people_alt_outlined,
                color: Colors.green,
              ),
            ),
            InkWell(
              onTap: () => context.go('/maintenance'),
              child: KpiCard(
                title: 'Pending Issues',
                value: stats?.pendingMaintenanceIssues.toString() ?? '0',
                icon: Icons.build_outlined,
                color: Colors.orange,
              ),
            ),
            InkWell(
              onTap: () => context.go('/reports'),
              child: KpiCard(
                title: 'Monthly Revenue',
                value: kCurrencyFormat.format(stats?.monthlyRevenue ?? 0.0),
                icon: Icons.attach_money_outlined,
                color: Colors.purple,
              ),
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
          // Two-column layout for wide screens
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildPortfolioOverviewCard(context, homeProvider),
                    SizedBox(height: kDefaultPadding),
                    _buildTopPropertiesCard(context, homeProvider),
                  ],
                ),
              ),
              SizedBox(width: kDefaultPadding),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _buildFinancialSummaryCard(context, homeProvider),
                    SizedBox(height: kDefaultPadding),
                    _buildQuickActionsCard(context),
                  ],
                ),
              ),
            ],
          );
        } else {
          // Single-column layout for smaller screens
          return Column(
            children: [
              _buildPortfolioOverviewCard(context, homeProvider),
              SizedBox(height: kDefaultPadding),
              _buildFinancialSummaryCard(context, homeProvider),
              SizedBox(height: kDefaultPadding),
              _buildTopPropertiesCard(context, homeProvider),
              SizedBox(height: kDefaultPadding),
              _buildQuickActionsCard(context),
            ],
          );
        }
      },
    );
  }

  Widget _buildPortfolioOverviewCard(
    BuildContext context,
    HomeProvider homeProvider,
  ) {
    final stats = homeProvider.stats;
    final available = (stats?.totalProperties ?? 0) - (stats?.occupiedProperties ?? 0);
    final theme = Theme.of(context);

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
                  'Portfolio Overview',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward),
                  onPressed: () => context.go('/properties'),
                ),
              ],
            ),
            SizedBox(height: kDefaultPadding),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  'Occupied',
                  stats?.occupiedProperties.toString() ?? '0',
                  Colors.green,
                ),
                _buildStatColumn(
                  'Available',
                  available.toString(),
                  Colors.blue,
                ),
                _buildStatColumn(
                  'Avg. Rating',
                  stats?.averageRating.toStringAsFixed(1) ?? '0.0',
                  Colors.amber,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildTopPropertiesCard(
    BuildContext context,
    HomeProvider homeProvider,
  ) {
    final theme = Theme.of(context);
    final topProperties = homeProvider.stats?.topProperties ?? [];

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
                  'Top Performing Properties',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward),
                  onPressed: () => context.go('/reports'),
                ),
              ],
            ),
            SizedBox(height: kDefaultPadding),
            if (topProperties.isEmpty)
              Center(
                child: Text(
                  'No property data available',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.6,
                    ),
                  ),
                ),
              )
            else
              ...topProperties
                  .take(3)
                  .map(
                    (property) => ListTile(
                      title: Text(property.name),
                      subtitle: Text('${property.bookingCount} bookings'),
                      trailing: Text(
                        kCurrencyFormat.format(property.totalRevenue),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialSummaryCard(
    BuildContext context,
    HomeProvider homeProvider,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(kDefaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial Summary',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: kDefaultPadding),
            FinancialSummaryCard(
              income: homeProvider.stats?.totalRentIncome ?? 0.0,
              expenses: homeProvider.stats?.totalMaintenanceCosts ?? 0.0,
              netProfit: homeProvider.stats?.netTotal ?? 0.0,
              currencyFormat: kCurrencyFormat,
            ),
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
              leading: Icon(Icons.people),
              title: Text('Manage Tenants'),
              onTap: () => context.go('/tenants'),
            ),
            ListTile(
              leading: Icon(Icons.analytics),
              title: Text('View Reports'),
              onTap: () => context.go('/reports'),
            ),
            ListTile(
              leading: Icon(Icons.build),
              title: Text('Maintenance Issues'),
              onTap: () => context.go('/maintenance'),
            ),
          ],
        ),
      ),
    );
  }
}
