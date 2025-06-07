import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../repositories/booking_repository.dart';
import '../../models/booking.dart';
import '../../base/service_locator.dart';
import 'providers/booking_universal_table_provider.dart';

class BookingsTableScreen extends StatefulWidget {
  const BookingsTableScreen({super.key});

  @override
  State<BookingsTableScreen> createState() => _BookingsTableScreenState();
}

class _BookingsTableScreenState extends State<BookingsTableScreen> {
  late BookingRepository _bookingRepository;

  @override
  void initState() {
    super.initState();
    // ✅ CLEAN: Use service locator to get repository dependency
    _bookingRepository = getService<BookingRepository>();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ CLEAN: Remove redundant Scaffold - ContentWrapper handles layout
    return BookingTableFactory.create(
      repository: _bookingRepository,
      title: '', // Remove title - ContentWrapper provides it
      headerActions: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildSummaryStats(),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () => _refreshData(),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
      onRowTap: (booking) {
        // Handle row selection
        _showBookingQuickActions(booking);
      },
      onRowDoubleTap: (booking) {
        // Navigate to booking details
        context.push('/bookings/${booking.bookingId}');
      },
    );
  }

  Widget _buildSummaryStats() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 14,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 6),
          Text(
            'Smart Table',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  void _refreshData() {
    // ✅ CLEAN: Simply trigger rebuild
    // The Universal Table Widget handles its own data refresh
    setState(() {
      // This will cause the table widget to rebuild and fetch fresh data
    });
  }

  void _showBookingQuickActions(Booking booking) {
    showModalBottomSheet(
      context: context,
      builder: (context) => BookingQuickActionsSheet(booking: booking),
    );
  }
}

class BookingQuickActionsSheet extends StatelessWidget {
  final Booking booking;

  const BookingQuickActionsSheet({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.propertyName ?? 'Unknown Property',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Booking #${booking.bookingId} • ${booking.userName ?? "Unknown Tenant"}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(booking.status),
            ],
          ),

          const SizedBox(height: 24),

          // Booking Details
          _buildDetailRow(
            context,
            'Check-in',
            booking.formattedStartDate,
            Icons.login,
          ),
          _buildDetailRow(
            context,
            'Check-out',
            booking.formattedEndDate,
            Icons.logout,
          ),
          _buildDetailRow(
            context,
            'Guests',
            '${booking.numberOfGuests}',
            Icons.people,
          ),
          _buildDetailRow(
            context,
            'Total Price',
            booking.formattedPrice,
            Icons.attach_money,
          ),

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push('/bookings/${booking.bookingId}');
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text('View Details'),
                ),
              ),
              const SizedBox(width: 12),
              if (booking.canBeCancelled) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showCancelDialog(context, booking);
                    },
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push('/properties/${booking.propertyId}');
                    },
                    icon: const Icon(Icons.home),
                    label: const Text('View Property'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BookingStatus status) {
    final Color baseColor;
    switch (status) {
      case BookingStatus.upcoming:
        baseColor = Colors.blue;
        break;
      case BookingStatus.active:
        baseColor = Colors.green;
        break;
      case BookingStatus.completed:
        baseColor = Colors.deepPurple;
        break;
      case BookingStatus.cancelled:
        baseColor = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: baseColor.withOpacity(0.3)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: baseColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, Booking booking) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancel Booking'),
            content: Text(
              'Are you sure you want to cancel booking #${booking.bookingId}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  try {
                    // ✅ CLEAN: Use repository directly through service locator
                    final repository = getService<BookingRepository>();
                    final cancellationRequest = BookingCancellationRequest(
                      bookingId: booking.bookingId,
                      cancellationReason: 'Cancelled from table interface',
                      requestRefund: true,
                    );
                    await repository.cancelBooking(cancellationRequest);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Booking #${booking.bookingId} cancelled',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to cancel booking: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Yes, Cancel'),
              ),
            ],
          ),
    );
  }
}
