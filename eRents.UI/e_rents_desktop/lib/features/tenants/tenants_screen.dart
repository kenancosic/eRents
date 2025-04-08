import 'package:flutter/material.dart';
import 'package:e_rents_desktop/base/app_base_screen.dart';

class TenantsScreen extends StatelessWidget {
  const TenantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBaseScreen(
      title: 'Tenants',
      currentPath: '/tenants',
      content: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(children: [TenantCard()]),
      ),
    );
  }
}

class TenantCard extends StatelessWidget {
  const TenantCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      child: Column(
        children: [
          Row(children: [Text('Tenant Card')]),
          Text('Tenant Card'),
          Text('Tenant Card'),
        ],
      ),
    );
  }
}
