import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final String status;
  final bool isSmall;

  const StatusChip({super.key, required this.status, this.isSmall = false});

  @override
  Widget build(BuildContext context) {
    final isAvailable = status == 'Available';
    final isCompleted = status == 'Completed';
    final isOccupied = status == 'Occupied';

    Color backgroundColor;
    Color textColor;

    if (isAvailable) {
      backgroundColor = Colors.green.withOpacity(0.2);
      textColor = Colors.green;
    } else if (isCompleted) {
      backgroundColor = Colors.green.withOpacity(0.2);
      textColor = Colors.green;
    } else if (isOccupied) {
      backgroundColor = Colors.blue.withOpacity(0.2);
      textColor = Colors.blue;
    } else {
      backgroundColor = Colors.orange.withOpacity(0.2);
      textColor = Colors.orange;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 6 : 8,
        vertical: isSmall ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: isSmall ? 10 : 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
