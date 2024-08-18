import 'package:flutter/material.dart';

class CustomDialog extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const CustomDialog({
    Key? key,
    required this.title,
    required this.content,
    required this.onConfirm,
    this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
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
