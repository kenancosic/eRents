import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    // Determine color and icon based on status
    // TODO: Add more status types and corresponding colors/icons as needed
    final bool isAvailable = status.toLowerCase() == 'available';
    final bool isOccupied =
        status.toLowerCase() == 'occupied'; // Example other status
    final Color color;
    final IconData iconData;

    if (isAvailable) {
      color = Colors.green;
      iconData = Icons.check_circle_outline;
    } else if (isOccupied) {
      color = Colors.blue; // Example color for occupied
      iconData = Icons.person_outline; // Example icon for occupied
    } else {
      // Default/Other statuses like 'Rented', 'Maintenance'
      color = Colors.orange;
      iconData = Icons.lock_outline; // Default icon
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(
          0.85,
        ), // Match the opacity from _buildStatusChip
        borderRadius: BorderRadius.circular(16), // Match the border radius
        boxShadow: [
          // Match the shadow
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, color: Colors.white, size: 14), // Match icon style
          const SizedBox(width: 4),
          Text(
            status, // Display the original status string
            style: const TextStyle(
              // Match text style
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
