import 'package:flutter/material.dart';
import 'package:e_rents_desktop/base/app_base_screen.dart';

class TenantsScreen extends StatelessWidget {
  const TenantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBaseScreen(
      title: 'Tenants',
      currentPath: '/tenants',
      content: const Center(child: Text('Tenants Screen Content')),
    );
  }
}
