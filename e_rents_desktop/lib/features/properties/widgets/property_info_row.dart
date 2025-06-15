import 'package:flutter/material.dart';

/// A simple widget to display property information with an icon and text
class PropertyInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? iconColor;

  const PropertyInfoRow({
    super.key,
    required this.icon,
    required this.text,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: iconColor ?? Colors.grey[600]),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
