import 'package:e_rents_desktop/features/rents/providers/rents_provider.dart';
import 'package:e_rents_desktop/features/rents/widgets/rents_table_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RentsListScreen extends StatefulWidget {
  const RentsListScreen({super.key});

  @override
  State<RentsListScreen> createState() => _RentsListScreenState();
}

class _RentsListScreenState extends State<RentsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
          // Unified RentsTableWidget for Stays
          RentsTableWidget(
            rentalType: RentalType.stay,
            onItemTap: (item) {
              if (context.mounted) {
                context.push('/stays/${item.bookingId}');
              }
            },
          ),
          // Unified RentsTableWidget for Leases
          RentsTableWidget(
            rentalType: RentalType.lease,
            onItemTap: (item) {
              if (context.mounted) {
                context.push('/leases/${item.requestId}');
              }
            },
          ),
        ],
      ),
    );
  }
}
