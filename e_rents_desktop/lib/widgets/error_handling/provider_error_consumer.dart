import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/base/base_provider.dart';
import 'error_banner.dart';

/// A widget that listens to a provider's error state and displays an error banner.
/// 
/// This widget automatically:
/// - Shows an error banner when the provider has an error
/// - Hides the banner when the error is cleared
/// - Provides retry functionality
/// - Allows dismissing errors
/// 
/// Usage:
/// ```dart
/// ProviderErrorConsumer<MaintenanceProvider>(
///   onRetry: () => provider.refresh(),
///   child: YourContentWidget(),
/// )
/// ```
class ProviderErrorConsumer<T extends BaseProvider> extends StatelessWidget {
  /// The child widget to display below the error banner
  final Widget child;
  
  /// Callback when retry is pressed
  final VoidCallback? onRetry;
  
  /// Whether to auto-dismiss the error when the provider starts loading
  final bool autoDismissOnLoad;
  
  /// Position of the error banner
  final ErrorBannerPosition position;
  
  /// Whether the banner should be shown inline (part of column) or as an overlay
  final bool inline;

  const ProviderErrorConsumer({
    super.key,
    required this.child,
    this.onRetry,
    this.autoDismissOnLoad = true,
    this.position = ErrorBannerPosition.top,
    this.inline = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<T>(
      builder: (context, provider, _) {
        final hasError = provider.hasError && provider.error != null;
        
        if (inline) {
          return Column(
            children: [
              if (hasError && position == ErrorBannerPosition.top)
                _buildBanner(context, provider),
              Expanded(child: child),
              if (hasError && position == ErrorBannerPosition.bottom)
                _buildBanner(context, provider),
            ],
          );
        }
        
        // Overlay mode
        return Stack(
          children: [
            child,
            if (hasError)
              Positioned(
                top: position == ErrorBannerPosition.top ? 0 : null,
                bottom: position == ErrorBannerPosition.bottom ? 0 : null,
                left: 0,
                right: 0,
                child: _buildBanner(context, provider),
              ),
          ],
        );
      },
    );
  }

  Widget _buildBanner(BuildContext context, T provider) {
    return ErrorBanner.fromString(
      provider.error!,
      onRetry: onRetry,
      onDismiss: () => provider.clearError(),
    );
  }
}

/// A more flexible version that works with any ChangeNotifier that has error state
class ErrorStateConsumer<T extends ChangeNotifier> extends StatelessWidget {
  /// The child widget to display
  final Widget child;
  
  /// Function to extract error message from the provider (return null if no error)
  final String? Function(T provider) errorExtractor;
  
  /// Function to clear the error
  final void Function(T provider)? onClearError;
  
  /// Callback when retry is pressed
  final VoidCallback? onRetry;
  
  /// Position of the error banner
  final ErrorBannerPosition position;

  const ErrorStateConsumer({
    super.key,
    required this.child,
    required this.errorExtractor,
    this.onClearError,
    this.onRetry,
    this.position = ErrorBannerPosition.top,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<T>(
      builder: (context, provider, _) {
        final error = errorExtractor(provider);
        final hasError = error != null && error.isNotEmpty;
        
        return Column(
          children: [
            if (hasError && position == ErrorBannerPosition.top)
              ErrorBanner.fromString(
                error,
                onRetry: onRetry,
                onDismiss: onClearError != null 
                    ? () => onClearError!(provider) 
                    : null,
              ),
            Expanded(child: child),
            if (hasError && position == ErrorBannerPosition.bottom)
              ErrorBanner.fromString(
                error,
                onRetry: onRetry,
                onDismiss: onClearError != null 
                    ? () => onClearError!(provider) 
                    : null,
              ),
          ],
        );
      },
    );
  }
}

/// Position for the error banner
enum ErrorBannerPosition {
  top,
  bottom,
}

/// Extension to easily show error dialogs from providers
extension ProviderErrorDialogs on BuildContext {
  /// Shows an error dialog with the given message
  Future<void> showErrorDialog({
    required String title,
    required String message,
    String? details,
    VoidCallback? onRetry,
  }) {
    return showDialog(
      context: this,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (details != null && details.isNotEmpty) ...[
              const SizedBox(height: 16),
              ExpansionTile(
                title: const Text('Technical Details', style: TextStyle(fontSize: 14)),
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      details,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (onRetry != null)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  /// Shows a snackbar with error styling
  void showErrorSnackBar(
    String message, {
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 5),
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: duration,
        action: onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  /// Shows a success snackbar
  void showSuccessSnackBar(String message, {Duration duration = const Duration(seconds: 3)}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        duration: duration,
      ),
    );
  }
}
