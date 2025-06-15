import 'package:flutter/material.dart';

class MiniButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final Color? color;

  const MiniButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonColor = color ?? theme.colorScheme.secondary;

    return TextButton.icon(
      onPressed: onPressed,
      icon:
          icon != null
              ? Icon(icon, size: 16, color: buttonColor)
              : const SizedBox.shrink(),
      label: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: buttonColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: buttonColor.withOpacity(0.1),
        foregroundColor: buttonColor,
      ),
    );
  }
}
