import 'package:e_rents_mobile/core/widgets/custom_app_bar.dart';
import 'package:e_rents_mobile/core/models/booking_model.dart';
import 'package:e_rents_mobile/core/utils/date_extensions.dart';
import 'package:e_rents_mobile/features/profile/providers/user_bookings_provider.dart';
import 'package:e_rents_mobile/features/profile/widgets/booking_list_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class BookingHistoryScreen extends StatefulWidget {
  final int initialTabIndex;
  const BookingHistoryScreen({super.key, this.initialTabIndex = 0});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final safeIndex = widget.initialTabIndex.clamp(0, 2);
    _tabController = TabController(length: 3, vsync: this, initialIndex: safeIndex);
    // Load user bookings when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserBookingsProvider>().loadUserBookings();
    });
  }

  Future<void> _refreshBookings() async {
    await context.read<UserBookingsProvider>().loadUserBookings(forceRefresh: true);
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
        return BookingListItem(
          booking: booking,
          onCancel: () => _confirmCancellation(booking),
          onViewDetails: () => _navigateToPropertyDetails(booking),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Booking History',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refreshBookings,
          ),
        ],
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
        builder: (context, bookingsProvider, child) {
          if (bookingsProvider.isLoading && bookingsProvider.bookingHistory == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (bookingsProvider.error != null && bookingsProvider.bookingHistory == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    bookingsProvider.errorMessage.isNotEmpty
                        ? bookingsProvider.errorMessage
                        : 'Failed to load bookings.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _refreshBookings,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  )
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshBookings,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRefreshableList(
                  bookingsProvider.upcomingBookings.map((b) => Booking.fromJson(b)).toList(),
                  'No Upcoming Bookings',
                ),
                _buildRefreshableList(
                  bookingsProvider.pastBookings.map((b) => Booking.fromJson(b)).toList(),
                  'No Completed Bookings',
                ),
                _buildRefreshableList(
                  bookingsProvider.cancelledBookings.map((b) => Booking.fromJson(b)).toList(),
                  'No Cancelled Bookings',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _navigateToPropertyDetails(Booking booking) {
    // Navigate to property details screen with the booking's property ID
    context.push('/property/${booking.propertyId}');
  }

  Widget _buildRefreshableList(List<Booking> bookings, String emptyMessage) {
    if (bookings.isEmpty) {
      // Return a scrollable empty state so RefreshIndicator works
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: _buildEmptyState(context, emptyMessage),
        ),
      );
    }
    return _buildBookingList(bookings, emptyMessage);
  }

  Future<void> _confirmCancellation(Booking booking) async {
    DateTime? selectedDate;
    bool includeDate = false;

    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Cancel Booking'),
          content: StatefulBuilder(
            builder: (ctx, setState) => SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: includeDate,
                        onChanged: (v) => setState(() => includeDate = v ?? false),
                      ),
                      const Expanded(
                        child: Text('Specify cancellation date (needed for in-stay monthly leases).'),
                      ),
                    ],
                  ),
                  if (includeDate)
                    Row(
                      children: [
                        Text(selectedDate == null
                            ? 'No date selected'
                            : selectedDate!.toDisplayDate()),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () async {
                            final now = DateTime.now();
                            final first = now;
                            final last = booking.endDate ?? now.add(const Duration(days: 365));
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: now,
                              firstDate: first,
                              lastDate: last,
                            );
                            if (picked != null) setState(() => selectedDate = picked);
                          },
                          child: const Text('Pick date'),
                        )
                      ],
                    ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 4),
                  const Text('Policies:'),
                  const SizedBox(height: 4),
                  const Text('• Daily: Full refund if cancelled at least 3 days before start.'),
                  const Text('• Monthly: Before start – free; In-stay – contract adjusted; next month is still due.'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Close')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm Cancel'),
            ),
          ],
        );
      },
    );

    if (res == true && mounted) {
      final provider = context.read<UserBookingsProvider>();
      final ok = await provider.cancelBooking(
        booking.bookingId.toString(),
        cancellationDate: selectedDate,
      );
      if (ok && mounted) {
        // Switch to Cancelled tab for immediate visual feedback
        _tabController.animateTo(2);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Booking cancelled successfully'),
            backgroundColor: Colors.green[600],
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                // Already on Cancelled tab
              },
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel: ${provider.errorMessage}'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }
}
