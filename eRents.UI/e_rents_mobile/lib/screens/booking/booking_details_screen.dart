import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookingDetailsScreen extends StatelessWidget {
  final String propertyName;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;
  final String status;

  const BookingDetailsScreen({
    Key? key,
    required this.propertyName,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat.yMd();

    return Scaffold(
      appBar: AppBar(
        title: Text('Booking Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(propertyName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('Check-in: ${dateFormat.format(startDate)}'),
            Text('Check-out: ${dateFormat.format(endDate)}'),
            SizedBox(height: 10),
            Text('Total Price: \$${totalPrice.toStringAsFixed(2)}', style: TextStyle(color: Colors.green)),
            SizedBox(height: 10),
            Text('Status: $status', style: TextStyle(color: status == 'Confirmed' ? Colors.green : Colors.red)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Implement booking cancellation or other actions here
              },
              child: Text('Cancel Booking'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
