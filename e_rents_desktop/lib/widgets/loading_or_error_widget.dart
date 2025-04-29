import 'package:flutter/material.dart';

/// A widget that displays a loading indicator, an error message with a retry
/// button, or the main content based on the provided state.
class LoadingOrErrorWidget extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;
  final Widget child;
  final String loadingText;
  final String errorTitle;
  final String retryButtonText;

  const LoadingOrErrorWidget({
    super.key,
    required this.isLoading,
    this.error,
    this.onRetry,
    required this.child,
    this.loadingText = 'Loading...',
    this.errorTitle = 'Error', // Although often overridden by specific error
    this.retryButtonText = 'Retry',
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(loadingText),
          ],
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                errorTitle, // Generic title, specific message below
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                error!, // The specific error message
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) const SizedBox(height: 16),
              if (onRetry != null)
                ElevatedButton(
                  onPressed: onRetry,
                  child: Text(retryButtonText),
                ),
            ],
          ),
        ),
      );
    }

    // If not loading and no error, show the actual content
    return child;
  }
}
