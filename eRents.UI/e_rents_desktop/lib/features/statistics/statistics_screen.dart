import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/base/app_base_screen.dart';
import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/features/statistics/providers/statistics_provider.dart';
import 'package:e_rents_desktop/features/statistics/widgets/occupancy_pie_chart.dart';
import 'package:e_rents_desktop/features/statistics/widgets/revenue_line_chart.dart';
import 'package:e_rents_desktop/features/statistics/widgets/maintenance_bar_chart.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBaseScreen(
      title: 'Statistics',
      currentPath: '/statistics',
      child: Consumer<StatisticsProvider>(
        builder: (context, provider, child) {
          if (provider.state == ViewState.Busy) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.state == ViewState.Error) {
            return Center(
              child: Text(provider.errorMessage ?? 'An error occurred'),
            );
          }

          final occupancyStats = provider.getMockOccupancyStatistics().first;
          final financialStats = provider.getMockFinancialStatistics().first;
          final maintenanceStats =
              provider.getMockMaintenanceStatistics().first;

          return Column(
            children: [
              // First row with pie and line charts
              Expanded(
                child: Row(
                  children: [
                    // Pie chart for occupancy
                    Expanded(
                      child: OccupancyPieChart(
                        unitsByType: occupancyStats.unitsByType,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Line chart for revenue
                    Expanded(
                      child: RevenueLineChart(
                        monthlyRevenue: financialStats.monthlyRevenue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Second row with bar chart
              Expanded(
                child: MaintenanceBarChart(
                  issuesByCategory: maintenanceStats.issuesByCategory,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
