import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_providers.dart';

class GlobalErrorDialog extends StatelessWidget {
  const GlobalErrorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppErrorProvider>(
      builder: (context, errorProvider, child) {
        if (!errorProvider.hasError) return const SizedBox.shrink();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Error'),
                  content: Text(
                    errorProvider.userMessage ?? 'An error occurred',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        errorProvider.clearError();
                      },
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
