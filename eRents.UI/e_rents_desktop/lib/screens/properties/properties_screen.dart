import 'package:flutter/material.dart';
import 'package:e_rents_desktop/base/app_base_screen.dart';

class PropertiesScreen extends StatelessWidget {
  const PropertiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBaseScreen(
      title: 'Properties',
      currentPath: '/properties',
      content: const Center(child: Text('Properties Screen Content')),
    );
  }
}
