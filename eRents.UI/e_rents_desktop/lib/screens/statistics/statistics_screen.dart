import 'package:flutter/material.dart';
import 'package:e_rents_desktop/base/app_base_screen.dart';
import 'package:e_rents_desktop/screens/statistics/widgets/stat_card.dart';
import 'package:e_rents_desktop/screens/statistics/widgets/stat_chart.dart';
import 'package:e_rents_desktop/screens/statistics/widgets/recent_activity.dart';
import 'package:e_rents_desktop/screens/statistics/widgets/performance_metrics.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBaseScreen(
      title: 'Statistics & Reports',
      currentPath: '/statistics',
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Stats Cards
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: const [
                StatCard(
                  title: 'Total Properties',
                  value: '156',
                  change: '+12%',
                  isPositive: true,
                  icon: Icons.apartment,
                ),
                StatCard(
                  title: 'Active Rentals',
                  value: '89',
                  change: '+5%',
                  isPositive: true,
                  icon: Icons.home,
                ),
                StatCard(
                  title: 'Monthly Revenue',
                  value: '\$45,678',
                  change: '+8%',
                  isPositive: true,
                  icon: Icons.attach_money,
                ),
                StatCard(
                  title: 'Occupancy Rate',
                  value: '92%',
                  change: '-2%',
                  isPositive: false,
                  icon: Icons.trending_up,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Charts Section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Revenue Chart
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Revenue Overview',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        const SizedBox(
                          height: 300,
                          child: StatChart(type: ChartType.revenue),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Occupancy Chart
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Occupancy Rate',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        const SizedBox(
                          height: 300,
                          child: StatChart(type: ChartType.occupancy),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Performance Metrics and Recent Activity
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Performance Metrics
                const Expanded(flex: 2, child: PerformanceMetrics()),
                const SizedBox(width: 16),

                // Recent Activity
                const Expanded(child: RecentActivity()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
