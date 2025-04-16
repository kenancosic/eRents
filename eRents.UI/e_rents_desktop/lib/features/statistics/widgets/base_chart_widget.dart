import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class BaseChartWidget extends StatelessWidget {
  final String title;
  final Widget chart;
  final List<Widget> legends;

  const BaseChartWidget({
    super.key,
    required this.title,
    required this.chart,
    required this.legends,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Expanded(child: chart),
            const SizedBox(height: 16),
            Wrap(spacing: 16, runSpacing: 8, children: legends),
          ],
        ),
      ),
    );
  }
}
