import 'package:flutter/material.dart';

class BookingCard extends StatelessWidget {
  final String propertyName;
  final String bookingDate;
  final String startDate;
  final String endDate;
  final double totalPrice;
  final String status;

  const BookingCard({
    super.key,
    required this.propertyName,
    required this.bookingDate,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              propertyName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text('Booking Date: $bookingDate'),
            Text('Start Date: $startDate'),
            Text('End Date: $endDate'),
            Text('Total Price: \$${totalPrice.toStringAsFixed(2)}'),
            Text('Status: $status', style: const TextStyle(color: Colors.blue)),
          ],
        ),
      ),
    );
  }
}
