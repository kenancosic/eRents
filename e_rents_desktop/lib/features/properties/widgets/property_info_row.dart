import 'package:flutter/material.dart';

/// A simple row widget displaying an icon and text.
class PropertyInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final double iconSize;
  final double spacing;
  final TextStyle? textStyle;

  const PropertyInfoRow({
    super.key,
    required this.icon,
    required this.text,
    this.iconSize = 16,
    this.spacing = 4,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min, // Take up only needed space
      children: [
        Icon(icon, size: iconSize),
        SizedBox(width: spacing),
        Text(text, style: textStyle),
      ],
    );
  }
}
