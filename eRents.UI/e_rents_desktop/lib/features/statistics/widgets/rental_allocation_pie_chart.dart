import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:e_rents_desktop/features/statistics/widgets/base_chart_widget.dart';

class RentalAllocationPieChart extends StatelessWidget {
  final Map<String, double> rentalIncomeAllocation;

  const RentalAllocationPieChart({
    super.key,
    required this.rentalIncomeAllocation,
  });

  @override
  Widget build(BuildContext context) {
    final List<PieChartSectionData> sections = [];
    final List<Widget> legends = [];
    final colors = [
      const Color(0xFF4CAF50), // Green for Rent
      const Color(0xFF2196F3), // Blue for Utilities
      const Color(0xFFFFC107), // Amber for Maintenance
      const Color(0xFFFF5722), // Deep Orange for Other
    ];
    int index = 0;
    final total = rentalIncomeAllocation.values.fold(
      0.0,
      (sum, value) => sum + value,
    );

    rentalIncomeAllocation.forEach((category, percentage) {
      final color = colors[index % colors.length];

      sections.add(
        PieChartSectionData(
          color: color,
          value: percentage,
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
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
              Text(
                '$category (${percentage.toStringAsFixed(1)}%)',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      );

      index++;
    });

    return BaseChartWidget(
      title: 'Rental Income Allocation',
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
            'Total\n100%',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      legends: legends,
    );
  }
}
