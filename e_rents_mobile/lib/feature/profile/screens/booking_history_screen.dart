import 'package:e_rents_mobile/core/base/base_provider.dart'; // For ViewState
import 'package:e_rents_mobile/core/widgets/custom_app_bar.dart';
import 'package:e_rents_mobile/core/models/booking_model.dart';
import 'package:e_rents_mobile/feature/profile/user_bookings_provider.dart';
import 'package:e_rents_mobile/feature/profile/widgets/booking_list_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Optionally, fetch bookings here if not fetched on provider initialization
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   context.read<UserBookingsProvider>().fetchUserBookings();
    // });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_outlined, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Your bookings for this category will appear here.',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            // Optionally, add a button to explore or refresh
          ],
        ),
      ),
    );
  }

  Widget _buildBookingList(List<Booking> bookings, String emptyMessage) {
    if (bookings.isEmpty) {
      return _buildEmptyState(context, emptyMessage);
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return BookingListItem(booking: booking);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Booking History',
        showBackButton: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: Consumer<UserBookingsProvider>(
        builder: (context, provider, child) {
          if (provider.state == ViewState.busy) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.state == ViewState.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(provider.errorMessage ?? 'Failed to load bookings.'),
                  ElevatedButton(
                    onPressed: () => provider.fetchBookings(),
                    child: const Text('Try Again'),
                  )
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildBookingList(
                  provider.upcomingBookings, 'No Upcoming Bookings'),
              _buildBookingList(
                  provider.completedBookings, 'No Completed Bookings'),
              _buildBookingList(
                  provider.cancelledBookings, 'No Cancelled Bookings'),
            ],
          );
        },
      ),
    );
  }
}
