import 'package:flutter/material.dart';
import 'package:e_rents_mobile/widgets/simple_button.dart';
import 'package:intl/intl.dart';

class BookingSummary extends StatelessWidget {
  final String propertyName;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;

  const BookingSummary({
    required this.propertyName,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat.yMd();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(propertyName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Check-in: ${dateFormat.format(startDate)}'),
            Text('Check-out: ${dateFormat.format(endDate)}'),
            const SizedBox(height: 8),
            Text('Total Price: \$${totalPrice.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green)),
            const SizedBox(height: 10),
            SimpleButton(
              text: 'Confirm Booking',
              textColor: Colors.white,
              bgColor: Colors.blue,
              onTap: () {
                // Confirm Booking action
              },
            ),
          ],
        ),
      ),
    );
  }
}
