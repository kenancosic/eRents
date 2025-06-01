import 'package:e_rents_desktop/widgets/filters/report_filters.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/features/statistics/providers/statistics_provider.dart';
import 'package:e_rents_desktop/models/reports/financial_report_item.dart';
import 'package:e_rents_desktop/models/statistics/financial_statistics.dart';
import 'package:e_rents_desktop/features/auth/providers/auth_provider.dart';
import 'package:intl/intl.dart';
import 'package:e_rents_desktop/utils/formatters.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  @override
  void initState() {
    super.initState();
    // Load statistics data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticatedState) {
        final statisticsProvider = Provider.of<StatisticsProvider>(
          context,
          listen: false,
        );
        statisticsProvider.loadFinancialStatistics();
      }
    });
  }

  void _handleDateRangeChanged(
    BuildContext context,
    DateTime start,
    DateTime end,
  ) {
    debugPrint(
      'StatisticsScreen: Date range changed to ${DateFormat('dd/MM/yyyy').format(start)} - ${DateFormat('dd/MM/yyyy').format(end)}',
    );
    final provider = Provider.of<StatisticsProvider>(context, listen: false);
    provider.setDateRangeAndFetch(start, end);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // If not authenticated, show login prompt
        if (!authProvider.isAuthenticatedState) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 64),
                SizedBox(height: 16),
                Text('Please log in to view statistics'),
              ],
            ),
          );
        }

        return Consumer<StatisticsProvider>(
          builder: (context, statisticsProvider, child) {
            debugPrint(
              'StatisticsScreen: Consumer rebuild - provider state=${statisticsProvider.state}, hasData=${statisticsProvider.statisticsUiModel != null}',
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StatisticsFilters(
                  onDateRangeChanged:
                      (start, end) =>
                          _handleDateRangeChanged(context, start, end),
                  onPropertyFilterChanged: (selectedProps) {
                    debugPrint(
                      'Statistics Screen: Property filter changed (not used): $selectedProps',
                    );
                  },
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildStatisticsContent(context, statisticsProvider),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatisticsContent(
    BuildContext context,
    StatisticsProvider provider,
  ) {
    debugPrint(
      'StatisticsScreen._buildStatisticsContent: state=${provider.state}, hasModel=${provider.statisticsUiModel != null}',
    );

    if (provider.state == ViewState.Busy &&
        provider.statisticsUiModel == null) {
      debugPrint('StatisticsScreen: Showing loading indicator');
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.state == ViewState.Error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error loading statistics: ${provider.errorMessage ?? "Unknown error"}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: () => provider.loadFinancialStatistics(),
            ),
          ],
        ),
      );
    }

    if (provider.statisticsUiModel == null) {
      debugPrint('StatisticsScreen: No statistics data available');
      return const Center(
        child: Text('No statistics data available for the selected period.'),
      );
    }

    final stats = provider.statisticsUiModel!;
    debugPrint(
      'StatisticsScreen: Displaying statistics data - totalRent=${stats.totalRent}, monthlyBreakdown=${stats.monthlyBreakdown.length} items',
    );

    // Sort monthly breakdown by date for consistent chart order
    stats.monthlyBreakdown.sort((a, b) {
      final DateFormat formatter = DateFormat('dd/MM/yyyy');
      try {
        final dateA = formatter.parse(a.dateFrom);
        final dateB = formatter.parse(b.dateFrom);
        return dateA.compareTo(dateB);
      } catch (e) {
        return 0; // Should not happen with valid data
      }
    });

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Financial Summary (${stats.formattedDateRange})',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _buildStatRow(
                  'Total Rental Income:',
                  kCurrencyFormat.format(stats.totalRent),
                  Colors.green,
                ),
                const SizedBox(height: 12),
                _buildStatRow(
                  'Total Maintenance Costs:',
                  kCurrencyFormat.format(stats.totalMaintenanceCosts),
                  Colors.orange,
                ),
                const Divider(height: 24, thickness: 1),
                _buildStatRow(
                  'Net Total:',
                  kCurrencyFormat.format(stats.netTotal),
                  stats.netTotal >= 0 ? Colors.blue : Colors.red,
                  isBold: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Row to hold both charts
        Row(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Align charts at the top
          children: [
            // Expanded Bar Chart
            Expanded(child: _buildBarChart(context, stats.monthlyBreakdown)),
            const SizedBox(width: 16), // Horizontal spacing between charts
            // Expanded Pie Chart
            Expanded(child: _buildPieChart(context, stats)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatRow(
    String label,
    String value,
    Color valueColor, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  // Method to build the Bar Chart
  Widget _buildBarChart(
    BuildContext context,
    List<FinancialReportItem> monthlyData,
  ) {
    if (monthlyData.isEmpty) {
      return const Card(
        elevation: 2,
        child: SizedBox(
          height: 300,
          child: Center(child: Text('No monthly data for bar chart')),
        ),
      );
    }

    final DateFormat monthFormatter = DateFormat('MMM yyyy'); // For labels
    final DateFormat inputFormatter = DateFormat('dd/MM/yyyy'); // For parsing

    final barGroups = <BarChartGroupData>[];
    double maxY = 0; // To dynamically set the Y-axis max value

    for (int i = 0; i < monthlyData.length; i++) {
      final item = monthlyData[i];
      final rent = item.totalRent;
      final costs = item.maintenanceCosts;

      // Update maxY
      if (rent > maxY) maxY = rent;
      if (costs > maxY) maxY = costs;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: rent,
              color: Colors.green, // Color for Rent
              width: 16,
              borderRadius: BorderRadius.zero,
            ),
            BarChartRodData(
              toY: costs,
              color: Colors.orange, // Color for Costs
              width: 16,
              borderRadius: BorderRadius.zero,
            ),
          ],
        ),
      );
    }

    // Add some padding to the max Y value
    maxY *= 1.2;

    return Card(
      elevation: 2,
      child: Container(
        height: 350, // Increased height for titles/labels
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Monthly Income vs. Costs',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final item = monthlyData[group.x];
                        String label = rodIndex == 0 ? 'Rent:' : 'Costs:';
                        String value = kCurrencyFormat.format(rod.toY);
                        return BarTooltipItem(
                          '${monthFormatter.format(inputFormatter.parse(item.dateFrom))}\n',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text: '$label $value',
                              style: TextStyle(
                                color: rod.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < monthlyData.length) {
                            try {
                              final date = inputFormatter.parse(
                                monthlyData[index].dateFrom,
                              );
                              return SideTitleWidget(
                                meta: meta,
                                space: 10,
                                child: Text(
                                  monthFormatter.format(date),
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            } catch (e) {
                              return const Text(
                                '',
                                style: TextStyle(fontSize: 10),
                              );
                            }
                          }
                          return const Text('', style: TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          // Show labels only at reasonable intervals
                          if (value == 0 || value == meta.max) {
                            return Text(
                              kCurrencyFormat.format(value),
                              style: const TextStyle(fontSize: 10),
                            );
                          } else if (value % (meta.max / 5).ceil() == 0) {
                            // Adjust interval if needed
                            return Text(
                              kCurrencyFormat.format(value),
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval:
                        (maxY / 5).ceil().toDouble(), // Match label interval
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  barGroups: barGroups,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.green, 'Rental Income'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.orange, 'Maintenance Costs'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper for Legend
  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // Method to build the Pie Chart
  Widget _buildPieChart(BuildContext context, FinancialStatistics stats) {
    final totalRent = stats.totalRent;
    final totalCosts = stats.totalMaintenanceCosts;
    final totalValue = totalRent + totalCosts;

    // Handle case where there's no data or total is zero to avoid division by zero
    if (totalValue <= 0) {
      return const Card(
        elevation: 2,
        child: SizedBox(
          height: 300,
          child: Center(child: Text('No data for pie chart')),
        ),
      );
    }

    final rentPercentage = (totalRent / totalValue) * 100;
    final costsPercentage = (totalCosts / totalValue) * 100;

    return Card(
      elevation: 2,
      child: Container(
        height: 350, // Consistent height
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Income vs. Costs Breakdown',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      color: Colors.green,
                      value: totalRent,
                      title: '${rentPercentage.toStringAsFixed(1)}%',
                      radius: 80,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      // Optional: Add tooltip on touch
                      // badgeWidget: _Badge(Icons.attach_money, size: 20, borderColor: Colors.black),
                      // badgePositionPercentageOffset: .98,
                    ),
                    PieChartSectionData(
                      color: Colors.orange,
                      value: totalCosts,
                      title: '${costsPercentage.toStringAsFixed(1)}%',
                      radius: 80,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                  // Optional: Add touch interactions if needed
                  // pieTouchData: PieTouchData(touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  //   ...
                  // }),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Legend (using the same helper)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(
                  Colors.green,
                  'Income (${kCurrencyFormat.format(stats.totalRent)})',
                ),
                const SizedBox(width: 16),
                _buildLegendItem(
                  Colors.orange,
                  'Costs (${kCurrencyFormat.format(stats.totalMaintenanceCosts)})',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Optional Badge widget example if needed later
  // class _Badge extends StatelessWidget { ... }
}
