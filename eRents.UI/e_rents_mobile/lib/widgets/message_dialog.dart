import 'package:flutter/material.dart';

class MessageDialog extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final bool isError;

  const MessageDialog({
    Key? key,
    required this.title,
    required this.content,
    required this.onConfirm,
    this.onCancel,
    this.isError = false,
  }) : super(key: key);

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
            child: Text("Cancel"),
          ),
        TextButton(
          onPressed: onConfirm,
          child: Text("Confirm"),
        ),
      ],
    );
  }
}
