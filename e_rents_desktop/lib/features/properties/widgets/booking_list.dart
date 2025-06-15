import 'package:e_rents_desktop/models/booking_summary.dart';
import 'package:e_rents_desktop/utils/date_utils.dart';
import 'package:e_rents_desktop/utils/formatters.dart';
import 'package:flutter/material.dart';

class BookingList extends StatelessWidget {
  final String title;
  final List<BookingSummary> bookings;
  final Color highlightColor;
  final bool isEmpty;
  final String emptyMessage;

  const BookingList({
    super.key,
    required this.title,
    required this.bookings,
    this.highlightColor = Colors.blue,
    this.isEmpty = false,
    this.emptyMessage = "No bookings in this category.",
  });

  @override
  Widget build(BuildContext context) {
    if (isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(emptyMessage),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: highlightColor,
            ),
          ),
        ),
        ...bookings.map(
          (booking) =>
              _BookingItem(booking: booking, highlightColor: highlightColor),
        ),
      ],
    );
  }
}

class _BookingItem extends StatelessWidget {
  final BookingSummary booking;
  final Color highlightColor;

  const _BookingItem({required this.booking, required this.highlightColor});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: highlightColor.withValues(alpha: 0.5),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  booking.tenantName ?? 'Anonymous',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  kCurrencyFormat.format(booking.totalPrice),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${AppDateUtils.formatPrimary(booking.startDate)} - ${AppDateUtils.formatPrimary(booking.endDate)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
