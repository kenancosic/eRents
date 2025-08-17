import 'package:flutter/material.dart';

/// A compact, reusable pill-style status badge for list rows.
/// Provide a text label, background color, foreground color and icon.
class StatusPill extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final IconData iconData;
  final Color foregroundColor;

  const StatusPill({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.iconData,
    this.foregroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, color: foregroundColor, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
