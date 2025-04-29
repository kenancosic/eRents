import 'package:flutter/material.dart';

class MessageDialog extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final bool isError;

  const MessageDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onConfirm,
    this.onCancel,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        title,
        style: TextStyle(color: isError ? Colors.red : Colors.black),
      ),
      content: Text(content),
      actions: [
        if (onCancel != null)
          TextButton(
            onPressed: onCancel,
            child: const Text("Cancel"),
          ),
        TextButton(
          onPressed: onConfirm,
          child: const Text("Confirm"),
        ),
      ],
    );
  }
}
