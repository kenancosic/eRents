import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../base/error_provider.dart';

class GlobalErrorDialog extends StatelessWidget {
  const GlobalErrorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ErrorProvider>(
      builder: (context, errorProvider, child) {
        if (errorProvider.errorMessage == null) return const SizedBox.shrink();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Error'),
              content: Text(errorProvider.errorMessage!),
              actions: [
                TextButton(
                  onPressed: () => errorProvider.clearError(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        });
        return const SizedBox.shrink();
      },
    );
  }
}
