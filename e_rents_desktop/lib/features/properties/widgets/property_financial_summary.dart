import 'package:e_rents_desktop/models/property_stats_data.dart';
import 'package:e_rents_desktop/utils/formatters.dart';
import 'package:flutter/material.dart';

class PropertyFinancialSummary extends StatelessWidget {
  final PropertyStatsData? stats;

  const PropertyFinancialSummary({super.key, this.stats});

  @override
  Widget build(BuildContext context) {
    // Helper method to create formatted strings from stats, with fallback
    String getFormattedRevenue() {
      if (stats?.financialStats == null) return 'N/A';
      return '${kCurrencyFormat.format(stats!.financialStats!.yearlyRevenue)}';
    }

    String getFormattedRating() {
      if (stats?.reviewStats == null || stats!.reviewStats!.totalReviews == 0) {
        return 'No reviews';
      }
      final reviewStats = stats!.reviewStats!;
      return '${reviewStats.averageRating.toStringAsFixed(1)} (${reviewStats.totalReviews} reviews)';
    }

    String getFormattedOccupancy() {
      if (stats?.occupancyStats == null) return 'N/A';
      final occupancy = stats!.occupancyStats!.currentOccupancyRate * 100;
      return '${occupancy.toStringAsFixed(1)}%';
    }

    String getPerformanceIndicator() {
      if (stats == null) return 'N/A';
      final occupancyRate = stats?.occupancyStats?.currentOccupancyRate ?? 0.0;
      final averageRating = stats?.reviewStats?.averageRating ?? 0.0;

      if (occupancyRate > 0.8 && averageRating > 4.5) return 'Excellent';
      if (occupancyRate > 0.6 && averageRating > 4.0) return 'Good';
      if (occupancyRate > 0.4 && averageRating > 3.5) return 'Average';
      return 'Needs Improvement';
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Total Revenue',
                value: getFormattedRevenue(),
                icon: Icons.monetization_on_outlined,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                label: 'Avg. Rating',
                value: getFormattedRating(),
                icon: Icons.star_border,
                color: Colors.amber,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Occupancy',
                value: getFormattedOccupancy(),
                icon: Icons.pie_chart_outline,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                label: 'Performance',
                value: getPerformanceIndicator(),
                icon: Icons.show_chart,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                Icon(icon, color: color),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
