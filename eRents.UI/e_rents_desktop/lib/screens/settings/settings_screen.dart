import 'package:flutter/material.dart';
import 'package:e_rents_desktop/base/app_base_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBaseScreen(
      title: 'Settings',
      currentPath: '/settings',
      content: const Center(child: Text('Settings Screen Content')),
    );
  }
}
