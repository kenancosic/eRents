import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

enum ChartType { revenue, occupancy }

class StatChart extends StatelessWidget {
  final ChartType type;

  const StatChart({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case ChartType.revenue:
        return _buildRevenueChart(context);
      case ChartType.occupancy:
        return _buildOccupancyChart(context);
    }
  }

  Widget _buildRevenueChart(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '\$${value.toInt()}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                if (value.toInt() >= 0 && value.toInt() < months.length) {
                  return Text(
                    months[value.toInt()],
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              const FlSpot(0, 30000),
              const FlSpot(1, 35000),
              const FlSpot(2, 32000),
              const FlSpot(3, 40000),
              const FlSpot(4, 38000),
              const FlSpot(5, 45000),
            ],
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOccupancyChart(BuildContext context) {
    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            value: 92,
            title: '92%',
            radius: 100,
            color: Theme.of(context).colorScheme.primary,
            titleStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            value: 8,
            title: '',
            radius: 100,
            color: Colors.grey[200],
          ),
        ],
        sectionsSpace: 0,
      ),
    );
  }
}
