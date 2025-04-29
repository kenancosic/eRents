import 'package:flutter/material.dart';

// Refactored reusable StatusChip
class StatusChip extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final IconData iconData;
  final Color foregroundColor; // Color for text and icon

  const StatusChip({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.iconData,
    this.foregroundColor = Colors.white, // Default to white
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ), // Adjusted padding slightly
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.9), // Consistent opacity
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08), // Softer shadow
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Ensure chip takes minimum space
        children: [
          Icon(iconData, color: foregroundColor, size: 14),
          const SizedBox(width: 5), // Adjusted spacing
          Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 12,
              fontWeight: FontWeight.w600, // Slightly bolder
              height: 1.1, // Adjust line height for compactness
            ),
          ),
        ],
      ),
    );
  }
}
