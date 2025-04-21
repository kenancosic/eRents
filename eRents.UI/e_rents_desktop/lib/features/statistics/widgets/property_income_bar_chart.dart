import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:e_rents_desktop/features/statistics/widgets/base_chart_widget.dart';
import 'package:intl/intl.dart';

class PropertyIncomeBarChart extends StatelessWidget {
  final Map<String, Map<String, double>> propertyIncomes;

  const PropertyIncomeBarChart({super.key, required this.propertyIncomes});

  @override
  Widget build(BuildContext context) {
    final List<BarChartGroupData> barGroups = [];
    final List<String> properties = propertyIncomes.keys.toList();
    final List<Widget> legends = [];
    final currencyFormatter = NumberFormat.currency(symbol: '\$');

    // Define colors for each category
    final categoryColors = {
      'Rent': const Color(0xFF2196F3), // Blue
      'Utilities': const Color(0xFF4CAF50), // Green
      'Maintenance': const Color(0xFFFFC107), // Amber
    };

    // Find the maximum value for scaling
    double maxValue = 0;
    propertyIncomes.forEach((_, incomes) {
      incomes.values.forEach((value) {
        if (value > maxValue) maxValue = value;
      });
    });

    // Create bar groups
    properties.asMap().forEach((propertyIndex, property) {
      final propertyData = propertyIncomes[property]!;
      final List<BarChartRodData> rods = [];

      categoryColors.entries.toList().asMap().forEach((index, entry) {
        final category = entry.key;
        final color = entry.value;
        final value = propertyData[category] ?? 0.0;

        rods.add(
          BarChartRodData(
            toY: value,
            color: color,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        );
      });

      barGroups.add(
        BarChartGroupData(
          x: propertyIndex,
          groupVertically: false,
          barRods: rods,
        ),
      );
    });

    // Create legends
    categoryColors.forEach((category, color) {
      legends.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(category, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      );
    });

    return BaseChartWidget(
      title: 'Property Income Distribution',
      chart: Padding(
        padding: const EdgeInsets.fromLTRB(8, 30, 20, 12),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxValue + (maxValue * 0.1),
            barGroups: barGroups,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxValue / 5,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey.withOpacity(0.2),
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 60,
                  interval: maxValue / 5,
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
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 &&
                        value.toInt() < properties.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          properties[value.toInt()],
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
          ),
        ),
      ),
      legends: legends,
    );
  }
}
