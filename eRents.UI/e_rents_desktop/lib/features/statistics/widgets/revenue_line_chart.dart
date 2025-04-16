import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:e_rents_desktop/features/statistics/widgets/base_chart_widget.dart';
import 'package:intl/intl.dart';

class RevenueLineChart extends StatelessWidget {
  final Map<String, double> monthlyRevenue;

  const RevenueLineChart({super.key, required this.monthlyRevenue});

  @override
  Widget build(BuildContext context) {
    final List<FlSpot> spots = [];
    final List<String> months = [];
    final currencyFormatter = NumberFormat.currency(symbol: '\$');
    int index = 0;

    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    monthlyRevenue.forEach((month, revenue) {
      spots.add(FlSpot(index.toDouble(), revenue));
      months.add(month);
      if (revenue < minY) minY = revenue;
      if (revenue > maxY) maxY = revenue;
      index++;
    });

    // Add some padding to min/max for better visualization
    final yPadding = (maxY - minY) * 0.1;
    minY = (minY - yPadding).clamp(0, double.infinity);
    maxY = maxY + yPadding;

    return BaseChartWidget(
      title: 'Monthly Revenue',
      chart: Padding(
        padding: const EdgeInsets.fromLTRB(8, 30, 20, 12),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: (maxY - minY) / 5,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey.withOpacity(0.2),
                  strokeWidth: 1,
                );
              },
            ),
            minY: minY,
            maxY: maxY,
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: (maxY - minY) / 5,
                  reservedSize: 60,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      currencyFormatter.format(value),
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 && value.toInt() < months.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          months[value.toInt()],
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
                left: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Theme.of(context).primaryColor,
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: Colors.white,
                      strokeWidth: 2,
                      strokeColor: Theme.of(context).primaryColor,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: Theme.of(context).primaryColor.withOpacity(0.15),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).primaryColor.withOpacity(0.2),
                      Theme.of(context).primaryColor.withOpacity(0.05),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      legends: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            const Text('Monthly Revenue', style: TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }
}
