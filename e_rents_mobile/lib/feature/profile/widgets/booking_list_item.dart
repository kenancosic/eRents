import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import '../../../core/models/booking_model.dart';

class BookingListItem extends StatelessWidget {
  final Booking booking;

  const BookingListItem({super.key, required this.booking});

  Color _getStatusColor(BookingStatus status, BuildContext context) {
    // Access theme colors for consistency if possible
    final ThemeData theme = Theme.of(context);
    switch (status) {
      case BookingStatus.Upcoming:
        return Colors.blue[100] ?? theme.primaryColorLight;
      case BookingStatus.Completed:
        return Colors.green[100] ?? theme.colorScheme.secondaryContainer;
      case BookingStatus.Cancelled:
        return Colors.red[100] ?? theme.colorScheme.errorContainer;
      default:
        return Colors.grey[200] ?? Colors.grey;
    }
  }

  Color _getStatusTextColor(BookingStatus status, BuildContext context) {
    final ThemeData theme = Theme.of(context);
    switch (status) {
      case BookingStatus.Upcoming:
        return Colors.blue[800] ?? theme.primaryColorDark;
      case BookingStatus.Completed:
        return Colors.green[800] ?? theme.colorScheme.secondary;
      case BookingStatus.Cancelled:
        return Colors.red[800] ?? theme.colorScheme.error;
      default:
        return Colors.grey[800] ?? Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy'); // e.g., Jan 1, 2023

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    booking.propertyImageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: Icon(Icons.broken_image,
                          size: 40, color: Colors.grey[600]),
                    ),
                    loadingBuilder: (BuildContext context, Widget child,
                        ImageChunkEvent? loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.propertyName,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${dateFormat.format(booking.startDate)} - ${dateFormat.format(booking.endDate)}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey[700]),
                      ),
                      if (booking.numberOfGuests > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Guests: ${booking.numberOfGuests}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey[700]),
                        ),
                      ],
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    booking.statusDisplay,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getStatusTextColor(booking.status, context),
                    ),
                  ),
                  backgroundColor: _getStatusColor(booking.status, context),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  labelPadding: const EdgeInsets.only(
                      top: 0,
                      bottom: 0,
                      left: 4,
                      right: 4), // Adjust padding for chip height
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const Divider(height: 24, thickness: 0.5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: \$${booking.totalPrice.toStringAsFixed(2)}',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to booking details screen
                    // Example: Navigator.push(context, MaterialPageRoute(builder: (context) => BookingDetailsScreen(bookingId: booking.id)));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('View details for ${booking.propertyName}')),
                    );
                  },
                  child: const Text('View Details'),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
