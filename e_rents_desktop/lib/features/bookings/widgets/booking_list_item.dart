import 'package:flutter/material.dart';
import '../../../models/booking.dart';
import '../../../widgets/status_chip.dart';

class BookingListItem extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;

  const BookingListItem({
    super.key,
    required this.booking,
    this.onTap,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.propertyName ?? 'Unknown Property',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Booking #${booking.bookingId}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  StatusChip(
                    label: booking.status?.displayName ?? 'Unknown',
                    iconData: Icons.circle,
                    backgroundColor: _getStatusColor(
                      booking.status,
                    ).withValues(alpha: 0.1),
                  ),
                  if (booking.canBeCancelled && onCancel != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.cancel_outlined),
                      onPressed: onCancel,
                      tooltip: 'Cancel Booking',
                      color: Colors.red,
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 12),

              // Booking Details
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow(
                          Icons.event,
                          'Check-in',
                          booking.formattedStartDate,
                        ),
                        const SizedBox(height: 4),
                        _buildDetailRow(
                          Icons.event_busy,
                          'Check-out',
                          booking.formattedEndDate,
                        ),
                        const SizedBox(height: 4),
                        _buildDetailRow(
                          Icons.person,
                          'Guests',
                          '${booking.numberOfGuests ?? 1}',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow(
                          Icons.attach_money,
                          'Total Price',
                          booking.formattedTotalPrice,
                        ),
                        const SizedBox(height: 4),
                        _buildDetailRow(
                          Icons.payment,
                          'Payment',
                          booking.paymentMethod ?? 'Unknown',
                        ),
                        if (booking.specialRequests?.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          _buildDetailRow(
                            Icons.note,
                            'Special Requests',
                            booking.specialRequests!,
                            maxLines: 2,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              // Duration Info
              if (booking.duration != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Duration: ${booking.duration}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(BookingStatus? status) {
    switch (status) {
      case BookingStatus.upcoming:
        return Colors.blue;
      case BookingStatus.active:
        return Colors.green;
      case BookingStatus.completed:
        return Colors.grey;
      case BookingStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
