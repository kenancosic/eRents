import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_mobile/core/models/booking_model.dart';
import 'package:e_rents_mobile/core/enums/booking_enums.dart';
import 'package:e_rents_mobile/core/services/api_service.dart';

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
        onTap: onTap ?? onViewDetails,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Property thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[200],
                  child: _buildPropertyImage(context),
                ),
              ),
              const SizedBox(width: 12),
              // Booking details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with status badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            booking.propertyName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(booking.status).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getStatusText(booking.status),
                            style: TextStyle(
                              color: _getStatusColor(booking.status),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Date range
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          '${_formatDate(booking.startDate)} - ${_formatDate(booking.endDate)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Guest name
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          booking.userName ?? 'Guest',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        if (booking.isSubscription) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'Monthly',
                              style: TextStyle(fontSize: 9, color: Colors.purple, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Price and actions row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${booking.currency ?? 'USD'} ${booking.totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7265F0),
                          ),
                        ),
                        if (onCancel != null && _canCancel(booking.status))
                          TextButton(
                            onPressed: onCancel,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
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
      case BookingStatus.pending:
        return Colors.amber;
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
      case BookingStatus.pending:
        return 'Pending';
      default:
        return 'Unknown';
    }
  }

  bool _canCancel(BookingStatus? status) {
    return status == BookingStatus.upcoming || status == BookingStatus.active || status == BookingStatus.pending;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildPropertyImage(BuildContext context) {
    final thumbnailUrl = booking.propertyThumbnailUrl;
    if (thumbnailUrl == null || thumbnailUrl.isEmpty) {
      return Icon(
        Icons.home_outlined,
        size: 32,
        color: Colors.grey[400],
      );
    }

    // Make relative URLs absolute using ApiService
    String imageUrl = thumbnailUrl;
    if (thumbnailUrl.startsWith('/')) {
      final api = context.read<ApiService>();
      imageUrl = api.makeAbsoluteUrl(thumbnailUrl);
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Icon(
        Icons.home_outlined,
        size: 32,
        color: Colors.grey[400],
      ),
    );
  }
}