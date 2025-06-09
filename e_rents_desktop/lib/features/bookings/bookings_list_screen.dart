import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../repositories/booking_repository.dart';
import '../../models/booking.dart';
import '../../base/service_locator.dart';
import 'providers/booking_list_factory.dart';

/// ✅ RICH BOOKINGS SCREEN - Production screen with enhanced UI
///
/// This provides a professional landlord interface with:
/// - Rich visual table with icons and styling
/// - Interactive modals for booking management
/// - Quick actions for common tasks
/// - Responsive and modern design

class BookingsListScreen extends StatefulWidget {
  const BookingsListScreen({super.key});

  @override
  State<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends State<BookingsListScreen> {
  late BookingRepository _bookingRepository;

  @override
  void initState() {
    super.initState();
    _bookingRepository = getService<BookingRepository>();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ CLEAN: Using BaseTableFactory-powered implementation
    return BookingListFactory.create(
      repository: _bookingRepository,
      context: context, // Required for navigation actions
      title: '', // ContentWrapper handles the title
      headerActions: _buildHeaderActions(context),
      onRowTap: _handleRowTap,
      onRowDoubleTap: _handleRowDoubleTap,
    );
  }

  /// ✅ MODULAR: Header actions separated for clarity
  Widget _buildHeaderActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildQuickStats(),
        const SizedBox(width: 16),
        _buildRefreshButton(),
        const SizedBox(width: 8),
        _buildAddButton(context),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.table_chart,
            size: 16,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 8),
          Text(
            'Smart Table',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshButton() {
    return ElevatedButton.icon(
      onPressed: _handleRefresh,
      icon: const Icon(Icons.refresh, size: 18),
      label: const Text('Refresh'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _handleAddBooking(context),
      icon: const Icon(Icons.add, size: 18),
      label: const Text('Add Booking'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  // ✅ CLEAN EVENT HANDLERS

  void _handleRowTap(Booking booking) {
    _showBookingQuickActions(booking);
  }

  void _handleRowDoubleTap(Booking booking) {
    context.push('/bookings/${booking.bookingId}');
  }

  void _handleRefresh() {
    setState(() {
      // Table will automatically refresh
    });
  }

  void _handleAddBooking(BuildContext context) {
    context.push('/bookings/add');
  }

  /// ✅ MODULAR: Quick actions separated for reusability
  void _showBookingQuickActions(Booking booking) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BookingQuickActionsSheet(booking: booking),
    );
  }
}

/// ✅ REUSABLE COMPONENT: Quick actions sheet
class BookingQuickActionsSheet extends StatelessWidget {
  final Booking booking;

  const BookingQuickActionsSheet({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 20),
          _buildDetails(context),
          const SizedBox(height: 24),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                booking.propertyName ?? 'Unknown Property',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
    );
  }

  Widget _buildDetails(BuildContext context) {
    return Column(
      children: [
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
      ],
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
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
                _showCancelDialog(context);
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
    );
  }

  Widget _buildStatusBadge(BookingStatus status) {
    final Color color;
    switch (status) {
      case BookingStatus.upcoming:
        color = Colors.blue;
        break;
      case BookingStatus.active:
        color = Colors.green;
        break;
      case BookingStatus.completed:
        color = Colors.deepPurple;
        break;
      case BookingStatus.cancelled:
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
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
                  // Handle cancellation
                  try {
                    final repository = getService<BookingRepository>();
                    await repository.cancelBooking(
                      booking.bookingId,
                      'Cancelled from table interface',
                      true, // requestRefund
                    );
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
