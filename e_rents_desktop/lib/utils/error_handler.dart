import 'package:flutter/material.dart';

class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error is String) return error;
    if (error is Exception) {
      final message = error.toString();
      if (message.contains('Invalid email or password')) {
        return 'Invalid email or password';
      }
      if (message.contains('Network is unreachable')) {
        return 'Please check your internet connection';
      }
      if (message.contains('timeout')) {
        return 'Request timed out. Please try again';
      }
      return 'An unexpected error occurred';
    }
    return 'An unexpected error occurred';
  }

  static void showError(BuildContext context, dynamic error) {
    final message = getErrorMessage(error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
