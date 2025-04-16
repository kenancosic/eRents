import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:e_rents_desktop/features/statistics/widgets/base_chart_widget.dart';

class MaintenanceBarChart extends StatelessWidget {
  final Map<String, int> issuesByCategory;

  const MaintenanceBarChart({super.key, required this.issuesByCategory});

  @override
  Widget build(BuildContext context) {
    final List<BarChartGroupData> barGroups = [];
    final List<String> categories = [];
    final List<Widget> legends = [];
    int index = 0;

    final maxValue =
        issuesByCategory.values.reduce((a, b) => a > b ? a : b).toDouble();
    final colors = [
      const Color(0xFF448AFF), // Blue
      const Color(0xFFFF4081), // Pink
      const Color(0xFF69F0AE), // Green
      const Color(0xFFFFD740), // Amber
      const Color(0xFFFF5252), // Red
    ];

    issuesByCategory.forEach((category, count) {
      final color = colors[index % colors.length];
      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: color,
              width: 16,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxValue + 1,
                color: Colors.grey.withOpacity(0.1),
              ),
            ),
          ],
        ),
      );
      categories.add(category);

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
              Text('$category ($count)', style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      );
      index++;
    });

    return BaseChartWidget(
      title: 'Maintenance Issues by Category',
      chart: Padding(
        padding: const EdgeInsets.fromLTRB(8, 30, 20, 12),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxValue + 1,
            barGroups: barGroups,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 1,
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
                  reservedSize: 30,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
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
                        value.toInt() < categories.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          categories[value.toInt()],
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
