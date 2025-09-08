import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/widgets/custom_button.dart';
import 'package:e_rents_mobile/core/widgets/custom_outlined_button.dart';
import 'package:go_router/go_router.dart';

/// A collection of reusable dialog widgets for consistent UI dialogs and messages
/// across the application.
///
/// This class provides static methods for showing common dialogs such as
/// confirmation dialogs, input dialogs, and snack bars. These dialogs are
/// designed to have a consistent look and feel throughout the application.
class CustomDialogs {
  /// Shows a confirmation dialog with customizable title, content, and actions.
  ///
  /// Returns `true` if the user confirms, `false` if the user cancels, or `null` if
  /// the dialog is dismissed.
  ///
  /// Example:
  /// ```dart
  /// final result = await CustomDialogs.showConfirmationDialog(
  ///   context: context,
  ///   title: 'Delete Item',
  ///   content: 'Are you sure you want to delete this item?',
  ///   confirmText: 'Delete',
  ///   isDestructive: true,
  /// );
  /// if (result == true) {
  ///   // Handle confirmation
  /// }
  /// ```
  static Future<bool?> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          CustomOutlinedButton.compact(
            label: cancelText,
            isLoading: false,
            onPressed: () => context.pop(false),
          ),
          CustomButton.compact(
            label: confirmText,
            isLoading: false,
            onPressed: () => context.pop(true),
          ),
        ],
      ),
    );
  }

  /// Shows an input dialog with a text field.
  ///
  /// Returns the entered text if the user confirms, or `null` if the user cancels
  /// or the dialog is dismissed.
  ///
  /// Example:
  /// ```dart
  /// final result = await CustomDialogs.showInputDialog(
  ///   context: context,
  ///   title: 'Enter Name',
  ///   hintText: 'Name',
  /// );
  /// if (result != null) {
  ///   // Handle the entered text
  /// }
  /// ```
  static Future<String?> showInputDialog({
    required BuildContext context,
    required String title,
    String? hintText,
    String? initialValue,
  }) async {
    final controller = TextEditingController(text: initialValue);
    
    final result = await showDialog<String?> (
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: hintText),
          autofocus: true,
        ),
        actions: [
          CustomOutlinedButton.compact(
            label: 'Cancel',
            isLoading: false,
            onPressed: () => ctx.pop(null),
          ),
          CustomButton.compact(
            label: 'Save',
            isLoading: false,
            onPressed: () => ctx.pop(controller.text.trim()),
          ),
        ],
      ),
    );
    // Dispose on next frame to avoid use-after-dispose while the dialog
    // is still finishing its transition rebuilds.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
    });
    return result;
  }

  /// Shows a custom snackbar with consistent styling.
  ///
  /// This method creates a snackbar with either a success or error style based
  /// on the [isError] parameter.
  ///
  /// Example:
  /// ```dart
  /// CustomDialogs.showCustomSnackBar(
  ///   context: context,
  ///   message: 'Operation completed successfully',
  ///   isError: false,
  /// );
  /// ```
  static void showCustomSnackBar({
    required BuildContext context,
    required String message,
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }
}
