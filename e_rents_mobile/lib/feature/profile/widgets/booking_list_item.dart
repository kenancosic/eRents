import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/models/booking_model.dart';
import 'package:e_rents_mobile/core/widgets/custom_button.dart';

/// Widget for displaying a booking item in a list
/// Used in booking history screen and other booking-related screens
class BookingListItem extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onTap;
  final VoidCallback? onViewDetails;
  final VoidCallback? onCancel;

  const BookingListItem({
    super.key,
    required this.booking,
    this.onTap,
    this.onViewDetails,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Booking header with status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Booking #${booking.bookingId}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(booking.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getStatusText(booking.status),
                      style: TextStyle(
                        color: _getStatusColor(booking.status),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Property name and dates
              Text(
                booking.propertyName ?? 'Property Name',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_formatDate(booking.startDate)} - ${_formatDate(booking.endDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.group,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${booking.numberOfGuests ?? 1} guests',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Total price
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '\$${booking.totalPrice.toStringAsFixed(2) ?? '0.00'}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7265F0),
                    ),
                  ),
                ],
              ),

              // Actions
              if (onViewDetails != null || onCancel != null) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onViewDetails != null)
                      CustomButton.compact(
                        label: 'View Details',
                        isLoading: false,
                        onPressed: onViewDetails!,
                      ),
                    if (onCancel != null && _canCancel(booking.status)) ...[
                      const SizedBox(width: 8),
                      CustomButton(
                        label: 'Cancel',
                        isLoading: false,
                        backgroundColor: Colors.red,
                        size: ButtonSize.compact,
                        width: ButtonWidth.content,
                        useGradient: false,
                        useShadow: false,
                        onPressed: onCancel!,
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(BookingStatus? status) {
    switch (status) {
      case BookingStatus.upcoming:
        return Colors.orange;
      case BookingStatus.active:
        return Colors.green;
      case BookingStatus.cancelled:
        return Colors.red;
      case BookingStatus.completed:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(BookingStatus? status) {
    switch (status) {
      case BookingStatus.upcoming:
        return 'Upcoming';
      case BookingStatus.active:
        return 'Active';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.completed:
        return 'Completed';
      default:
        return 'Unknown';
    }
  }

  bool _canCancel(BookingStatus? status) {
    return status == BookingStatus.upcoming || status == BookingStatus.active;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }
}