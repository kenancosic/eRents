import 'package:flutter/material.dart';
import 'package:e_rents_desktop/services/booking_service.dart';
import 'package:intl/intl.dart';
import 'package:e_rents_desktop/models/booking_summary.dart';

class PropertyBookingsSection extends StatelessWidget {
  final List<BookingSummary> currentBookings;
  final List<BookingSummary> upcomingBookings;
  final List<BookingSummary> recentBookings;

  const PropertyBookingsSection({
    super.key,
    required this.currentBookings,
    required this.upcomingBookings,
    required this.recentBookings,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bookings',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to all bookings
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (currentBookings.isNotEmpty) ...[
              _buildBookingSection(
                'Current Bookings',
                currentBookings,
                Colors.green,
              ),
              const SizedBox(height: 16),
            ],

            if (upcomingBookings.isNotEmpty) ...[
              _buildBookingSection(
                'Upcoming Bookings',
                upcomingBookings,
                Colors.blue,
              ),
              const SizedBox(height: 16),
            ],

            if (recentBookings.isNotEmpty)
              _buildBookingSection(
                'Recent Bookings',
                recentBookings.take(3).toList(),
                Colors.grey,
              ),

            if (currentBookings.isEmpty &&
                upcomingBookings.isEmpty &&
                recentBookings.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'No bookings yet',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingSection(
    String title,
    List<BookingSummary> bookings,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        ...bookings.map((booking) => _buildBookingItem(booking, color)),
      ],
    );
  }

  Widget _buildBookingItem(BookingSummary booking, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(width: 3, color: color)),
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.tenantName ?? 'Anonymous Tenant',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(
                    booking.bookingStatus,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  booking.bookingStatus,
                  style: TextStyle(
                    color: _getStatusColor(booking.bookingStatus),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (booking.tenantEmail != null)
            Text(
              booking.tenantEmail!,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${DateFormat.yMMMd().format(booking.startDate)}${booking.endDate != null ? ' - ${DateFormat.yMMMd().format(booking.endDate!)}' : ' (Ongoing)'}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const Spacer(),
              Text(
                '${booking.totalPrice.toStringAsFixed(0)} ${booking.currency}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'upcoming':
        return Colors.blue;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
