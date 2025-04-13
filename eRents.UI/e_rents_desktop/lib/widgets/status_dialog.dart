import 'package:flutter/material.dart';

class StatusDialog extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onActionPressed;
  final String? actionLabel;

  const StatusDialog({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.check_circle_outline,
    this.iconColor = Colors.green,
    this.onActionPressed,
    this.actionLabel,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    IconData icon = Icons.check_circle_outline,
    Color iconColor = Colors.green,
    VoidCallback? onActionPressed,
    String? actionLabel,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => StatusDialog(
            title: title,
            message: message,
            icon: icon,
            iconColor: iconColor,
            onActionPressed: onActionPressed,
            actionLabel: actionLabel,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: iconColor),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (actionLabel != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onActionPressed?.call();
                },
                child: Text(actionLabel!),
              ),
          ],
        ),
      ),
    );
  }
}
