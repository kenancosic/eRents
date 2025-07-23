import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/property.dart';

// Refactored reusable StatusChip
class StatusChip extends StatelessWidget {
  final dynamic label; // Can be PropertyStatus enum or String
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
    // Convert enum to string if needed
    final String displayLabel =
        label is PropertyStatus
            ? label.toString().split('.').last
            : label.toString();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ), // Adjusted padding slightly
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.9), // Consistent opacity
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08), // Softer shadow
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
            displayLabel,
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
