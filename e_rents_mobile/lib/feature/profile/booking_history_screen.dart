import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/core/widgets/custom_app_bar.dart';
import 'package:e_rents_mobile/core/models/booking_model.dart';
import 'package:e_rents_mobile/feature/profile/widgets/booking_list_item.dart';
import 'package:flutter/material.dart';
// import 'package:provider/provider.dart'; // TODO: For state management
// import '../user_provider.dart'; // TODO: For state management

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  // TODO: Replace with actual data from a provider/API call
  List<Booking> _bookings = [];
  bool _isLoading = true; // Simulate loading

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // Dummy data
    setState(() {
      _bookings = [
        Booking(
          id: '1',
          propertyName: 'Sunny Beachfront Villa with Ocean View',
          propertyImageUrl: 'https://picsum.photos/seed/villa1/400/300',
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          endDate: DateTime.now().subtract(const Duration(days: 25)),
          totalPrice: 750.99,
          status: BookingStatus.Completed,
          numberOfGuests: 2,
        ),
        Booking(
          id: '2',
          propertyName: 'Cozy Mountain Cabin Retreat',
          propertyImageUrl: 'https://picsum.photos/seed/cabin2/400/300',
          startDate: DateTime.now().add(const Duration(days: 10)),
          endDate: DateTime.now().add(const Duration(days: 15)),
          totalPrice: 420.50,
          status: BookingStatus.Upcoming,
          numberOfGuests: 4,
        ),
        Booking(
          id: '3',
          propertyName: 'Urban Loft in Downtown District',
          propertyImageUrl: 'https://picsum.photos/seed/loft3/400/300',
          startDate: DateTime.now().subtract(const Duration(days: 90)),
          endDate: DateTime.now().subtract(const Duration(days: 85)),
          totalPrice: 300.00,
          status: BookingStatus.Completed,
          numberOfGuests: 1,
        ),
        Booking(
          id: '4',
          propertyName: 'Quiet Lakeside Cottage Getaway',
          propertyImageUrl: 'https://picsum.photos/seed/lake4/400/300',
          startDate: DateTime.now().subtract(const Duration(days: 15)),
          endDate: DateTime.now().subtract(const Duration(days: 10)),
          totalPrice: 220.00,
          status: BookingStatus.Cancelled,
          numberOfGuests: 3,
        ),
      ];
      _isLoading = false;
    });
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_outlined, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            'No Bookings Yet!',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            'Your past and upcoming bookings will appear here.',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.search),
            label: const Text('Explore Properties'),
            onPressed: () {
              // TODO: Navigate to property browsing screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Navigate to explore properties...')),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingList() {
    return ListView.builder(
      padding: const EdgeInsets.only(
          top: 8, bottom: 8), // Add some padding around the list
      itemCount: _bookings.length,
      itemBuilder: (context, index) {
        final booking = _bookings[index];
        return BookingListItem(booking: booking);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appBar = CustomAppBar(
      title: 'Booking History',
      showBackButton: true,
      // TODO: Add actions for filtering/sorting if needed
      // actions: [
      //   IconButton(
      //     icon: Icon(Icons.filter_list),
      //     onPressed: () { /* Show filter options */ },
      //   ),
      // ],
    );

    return BaseScreen(
      showAppBar: true,
      appBar: appBar,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
              ? _buildEmptyState(context)
              : _buildBookingList(),
    );
  }
}
