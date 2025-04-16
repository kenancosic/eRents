import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:e_rents_desktop/features/statistics/widgets/base_chart_widget.dart';

class OccupancyPieChart extends StatelessWidget {
  final Map<String, int> unitsByType;

  const OccupancyPieChart({super.key, required this.unitsByType});

  @override
  Widget build(BuildContext context) {
    final List<PieChartSectionData> sections = [];
    final List<Widget> legends = [];
    final colors = [
      const Color(0xFFFF4081), // Pink
      const Color(0xFF7C4DFF), // Purple
      const Color(0xFFFF5252), // Red
      const Color(0xFF448AFF), // Blue
      const Color(0xFF69F0AE), // Green
    ];
    int index = 0;
    final total = unitsByType.values.fold(0, (sum, count) => sum + count);

    unitsByType.forEach((type, count) {
      final color = colors[index % colors.length];
      final percentage = (count / total * 100).toStringAsFixed(1);

      sections.add(
        PieChartSectionData(
          color: color,
          value: count.toDouble(),
          title: '$percentage%',
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          badgeWidget: Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          badgePositionPercentageOffset: 0.98,
        ),
      );

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
              Text('$type ($count)', style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      );

      index++;
    });

    return BaseChartWidget(
      title: 'Units by Type',
      chart: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sections: sections,
              sectionsSpace: 2,
              centerSpaceRadius: 50,
              startDegreeOffset: -90,
            ),
          ),
          Text(
            'Total\n$total',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      legends: legends,
    );
  }
}
