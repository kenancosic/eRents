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
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat.yMd(); // or any format you prefer
    return Card(
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(message),
            SizedBox(height: 8),
            Text('Received: ${dateFormat.format(date)}', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
