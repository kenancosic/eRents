import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../base/error_provider.dart';

class GlobalErrorDialog extends StatefulWidget {
  const GlobalErrorDialog({super.key});

  @override
  State<GlobalErrorDialog> createState() => _GlobalErrorDialogState();
}

class _GlobalErrorDialogState extends State<GlobalErrorDialog> {
  String? _lastShownError;
  bool _isDialogShowing = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<ErrorProvider>(
      builder: (context, errorProvider, child) {
        final errorMessage = errorProvider.errorMessage;
        
        // Only show dialog if:
        // 1. There's an error message
        // 2. It's different from the last shown error (prevents duplicate dialogs)
        // 3. No dialog is currently showing
        if (errorMessage != null && 
            errorMessage != _lastShownError && 
            !_isDialogShowing) {
          _lastShownError = errorMessage;
          _isDialogShowing = true;
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Error'),
                content: Text(errorMessage),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      errorProvider.clearError();
                      _isDialogShowing = false;
                      _lastShownError = null;
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          });
        }
        
        return const SizedBox.shrink();
      },
    );
  }
}
