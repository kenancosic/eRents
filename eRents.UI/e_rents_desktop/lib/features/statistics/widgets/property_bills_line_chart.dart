import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:e_rents_desktop/features/statistics/widgets/base_chart_widget.dart';
import 'package:intl/intl.dart';

class PropertyBillsLineChart extends StatelessWidget {
  final Map<String, Map<String, double>> propertyBillsOverTime;

  const PropertyBillsLineChart({
    super.key,
    required this.propertyBillsOverTime,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(symbol: '\$');
    final List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final Map<String, List<FlSpot>> spotsByProperty = {};
    final List<Widget> legends = [];

    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    final colors = [
      const Color(0xFF2196F3), // Blue
      const Color(0xFF4CAF50), // Green
      const Color(0xFFFFC107), // Amber
      const Color(0xFFFF5722), // Deep Orange
    ];
    int colorIndex = 0;

    propertyBillsOverTime.forEach((property, monthlyData) {
      final spots = <FlSpot>[];
      final color = colors[colorIndex % colors.length];

      for (int i = 0; i < months.length; i++) {
        final value = monthlyData[months[i]] ?? 0.0;
        spots.add(FlSpot(i.toDouble(), value));
        if (value < minY) minY = value;
        if (value > maxY) maxY = value;
      }

      spotsByProperty[property] = spots;

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
              Text(
                property,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );

      colorIndex++;
    });

    // Add some padding to min/max for better visualization
    final yPadding = (maxY - minY) * 0.1;
    minY = (minY - yPadding).clamp(0, double.infinity);
    maxY = maxY + yPadding;

    return BaseChartWidget(
      title: 'Property Bills Over Time (2024)',
      chart: Padding(
        padding: const EdgeInsets.fromLTRB(8, 30, 20, 12),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: (maxY - minY) / 6,
              verticalInterval: 1,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey.withOpacity(0.15),
                  strokeWidth: 1,
                );
              },
              getDrawingVerticalLine: (value) {
                return FlLine(
                  color: Colors.grey.withOpacity(0.15),
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
                  interval: (maxY - minY) / 6,
                  reservedSize: 70,
                  getTitlesWidget: (value, meta) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        currencyFormatter.format(value),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
                  reservedSize: 25,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 && value.toInt() < months.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          months[value.toInt()],
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
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
            lineBarsData:
                spotsByProperty.entries.map((entry) {
                  final color =
                      colors[spotsByProperty.keys.toList().indexOf(entry.key) %
                          colors.length];
                  return LineChartBarData(
                    spots: entry.value,
                    isCurved: true,
                    color: color,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: color,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withOpacity(0.08),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          color.withOpacity(0.08),
                          color.withOpacity(0.0),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ),
      legends: legends,
    );
  }
}
