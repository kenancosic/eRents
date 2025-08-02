import 'package:e_rents_desktop/features/rents/providers/rents_provider.dart';
import 'package:e_rents_desktop/models/booking.dart';
import 'package:e_rents_desktop/models/rental_request.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RentsScreen extends StatefulWidget {
  const RentsScreen({super.key});

  @override
  State<RentsScreen> createState() => _RentsScreenState();
}

class _RentsScreenState extends State<RentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final rentsProvider = context.read<RentsProvider>();
    await rentsProvider.getPagedStays();
    await rentsProvider.getPagedLeases();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      final rentsProvider = context.read<RentsProvider>();
      rentsProvider.setRentalType(
        _tabController.index == 0 ? RentalType.stay : RentalType.lease,
      );
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rental Management'),
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
          // Stays Tab (Read-Only List of Bookings)
          _buildStaysList(context),
          // Leases Tab (List of Rental Requests with Actions)
          _buildLeasesList(context),
        ],
      ),
    );
  }

  Widget _buildStaysList(BuildContext context) {
    return Consumer<RentsProvider>(
      builder: (context, rentsProvider, child) {
        if (rentsProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (rentsProvider.error != null) {
          return Center(child: Text('Error: ${rentsProvider.error}'));
        }
        if (rentsProvider.stays.isEmpty) {
          return const Center(child: Text('No stays found.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: rentsProvider.stays.length,
          itemBuilder: (context, index) {
            final Booking stay = rentsProvider.stays[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Property: ${stay.propertyName ?? 'N/A'}'),
                    Text('Tenant: ${stay.userName ?? 'N/A'}'),
                    Text('Dates: ${stay.dateRange}'),
                    Text('Status: ${stay.status.displayName}'),
                    Text('Total Price: ${stay.formattedTotalPrice}'),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLeasesList(BuildContext context) {
    return Consumer<RentsProvider>(
      builder: (context, rentsProvider, child) {
        if (rentsProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (rentsProvider.error != null) {
          return Center(child: Text('Error: ${rentsProvider.error}'));
        }
        if (rentsProvider.leases.isEmpty) {
          return const Center(child: Text('No leases found.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: rentsProvider.leases.length,
          itemBuilder: (context, index) {
            final RentalRequest lease = rentsProvider.leases[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Property: ${lease.propertyName}'),
                    Text('Applicant: ${lease.userName}'),
                    Text('Proposed Dates: ${lease.formattedStartDate} - ${lease.formattedEndDate}'),
                    Text('Monthly Rent: ${lease.formattedRent}'),
                    Text('Status: ${lease.status}'),
                    if (lease.isPending)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: rentsProvider.isLoading
                                ? null
                                : () async {
                                    final success = await rentsProvider.approveLease(lease.requestId, 'Approved by landlord');
                                    if (context.mounted && success) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Lease approved!')),
                                      );
                                      await rentsProvider.getPagedLeases(); // Refresh list
                                    } else if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(rentsProvider.error ?? 'Failed to approve lease.')),
                                      );
                                    }
                                  },
                            child: const Text('Approve'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: rentsProvider.isLoading
                                ? null
                                : () async {
                                    final success = await rentsProvider.rejectLease(lease.requestId, 'Rejected by landlord');
                                    if (context.mounted && success) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Lease rejected!')),
                                      );
                                      await rentsProvider.getPagedLeases(); // Refresh list
                                    } else if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(rentsProvider.error ?? 'Failed to reject lease.')),
                                      );
                                    }
                                  },
                            child: const Text('Reject'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
