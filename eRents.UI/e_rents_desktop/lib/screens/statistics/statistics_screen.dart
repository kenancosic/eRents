import 'package:flutter/material.dart';
import 'package:e_rents_desktop/base/app_base_screen.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBaseScreen(
      title: 'Statistics',
      currentPath: '/statistics',
      content: const Center(child: Text('Statistics Screen Content')),
    );
  }
}
