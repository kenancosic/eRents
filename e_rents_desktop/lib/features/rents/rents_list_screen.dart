import 'package:e_rents_desktop/base/service_locator.dart';
import 'package:e_rents_desktop/features/rents/widgets/leases_table_widget.dart';
import 'package:e_rents_desktop/features/rents/widgets/stays_table_widget.dart';
import 'package:e_rents_desktop/services/rental_management_service.dart';
import 'package:flutter/material.dart';

class RentsListScreen extends StatefulWidget {
  const RentsListScreen({Key? key}) : super(key: key);

  @override
  State<RentsListScreen> createState() => _RentsListScreenState();
}

class _RentsListScreenState extends State<RentsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RentalManagementService _rentalManagementService =
      ServiceLocator().get<RentalManagementService>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rentals'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Stays', icon: Icon(Icons.hotel)),
            Tab(text: 'Leases', icon: Icon(Icons.house)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          StaysTableWidget(rentalManagementService: _rentalManagementService),
          LeasesTableWidget(rentalManagementService: _rentalManagementService),
        ],
      ),
    );
  }
}
