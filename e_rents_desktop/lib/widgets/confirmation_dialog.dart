import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shows a generic confirmation dialog.
///
/// Returns `true` if the confirm action is pressed, `false` otherwise (or null if dismissed).
Future<bool?> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required Widget content,
  String confirmActionText = 'Confirm',
  String cancelActionText = 'Cancel',
  bool isDestructiveAction = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: content,
        actions: <Widget>[
          TextButton(
            child: Text(cancelActionText),
            onPressed: () {
              context.pop(false); // Return false on cancel
            },
          ),
          ElevatedButton(
            style:
                isDestructiveAction
                    ? ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    )
                    : null,
            child: Text(confirmActionText),
            onPressed: () {
              context.pop(true); // Return true on confirm
            },
          ),
        ],
      );
    },
  );
}
