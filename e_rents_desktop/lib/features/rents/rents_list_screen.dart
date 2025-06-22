import 'package:e_rents_desktop/base/service_locator.dart';
import 'package:e_rents_desktop/features/rents/lease_detail_screen.dart';
import 'package:e_rents_desktop/features/rents/stay_detail_screen.dart';
import 'package:e_rents_desktop/features/rents/widgets/leases_table_widget.dart';
import 'package:e_rents_desktop/features/rents/widgets/stays_table_widget.dart';
import 'package:e_rents_desktop/repositories/booking_repository.dart';
import 'package:e_rents_desktop/repositories/rental_request_repository.dart';
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
  final BookingRepository _bookingRepository =
      ServiceLocator().get<BookingRepository>();
  final RentalRequestRepository _rentalRequestRepository =
      ServiceLocator().get<RentalRequestRepository>();

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
          StaysTableWidget(
            bookingRepository: _bookingRepository,
            onItemTap: (item) {
              context.push('/stays/${item.id}');
            },
          ),
          LeasesTableWidget(
            rentalRequestRepository: _rentalRequestRepository,
            onItemTap: (item) {
              context.push('/leases/${item.id}');
            },
          ),
        ],
      ),
    );
  }
}
