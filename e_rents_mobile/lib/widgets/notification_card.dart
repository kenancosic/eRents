import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationCard extends StatelessWidget {
  final String title;
  final String message;
  final DateTime date;

  const NotificationCard({
    required this.title,
    required this.message,
    required this.date,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat.yMd(); // or any format you prefer
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message),
            const SizedBox(height: 8),
            Text('Received: ${dateFormat.format(date)}', style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
