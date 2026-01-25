import 'package:flutter/material.dart';
import 'package:e_rents_desktop/base/app_error.dart';

/// A banner widget that displays errors in a consistent, user-friendly way.
/// 
/// Features:
/// - Supports different severity levels (error, warning, info)
/// - Shows user-friendly messages with optional technical details
/// - Provides retry and dismiss actions
/// - Animates in/out smoothly
class ErrorBanner extends StatelessWidget {
  /// The error message to display
  final String message;
  
  /// Optional detailed error information (shown on expansion)
  final String? details;
  
  /// The type of error for styling purposes
  final ErrorBannerType type;
  
  /// Callback when retry is pressed (if null, no retry button shown)
  final VoidCallback? onRetry;
  
  /// Callback when dismiss is pressed (if null, no dismiss button shown)
  final VoidCallback? onDismiss;
  
  /// Whether to show the expand button for details
  final bool showDetails;
  
  /// Custom icon to display
  final IconData? icon;

  const ErrorBanner({
    super.key,
    required this.message,
    this.details,
    this.type = ErrorBannerType.error,
    this.onRetry,
    this.onDismiss,
    this.showDetails = true,
    this.icon,
  });

  /// Creates an ErrorBanner from an AppError
  factory ErrorBanner.fromAppError(
    AppError error, {
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) {
    return ErrorBanner(
      message: error.userMessage,
      details: error.details,
      type: _mapErrorTypeTobannerType(error.type),
      onRetry: error.isRetryable ? onRetry : null,
      onDismiss: onDismiss,
    );
  }

  /// Creates an ErrorBanner from a raw error string
  factory ErrorBanner.fromString(
    String error, {
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) {
    // Try to parse common error patterns
    final isServerError = error.contains('500') || 
                          error.contains('Internal Server Error') ||
                          error.contains('server');
    final isNetworkError = error.contains('network') || 
                           error.contains('connection') ||
                           error.contains('timeout');
    final isValidationError = error.contains('validation') || 
                              error.contains('invalid') ||
                              error.contains('constraint');
    
    ErrorBannerType type;
    String userMessage;
    
    if (isNetworkError) {
      type = ErrorBannerType.warning;
      userMessage = 'Network connection issue. Please check your connection and try again.';
    } else if (isServerError) {
      type = ErrorBannerType.error;
      userMessage = 'Server error occurred. Please try again in a moment.';
    } else if (isValidationError) {
      type = ErrorBannerType.warning;
      userMessage = 'Invalid data. Please check your input and try again.';
    } else {
      type = ErrorBannerType.error;
      userMessage = 'An error occurred. Please try again.';
    }
    
    return ErrorBanner(
      message: userMessage,
      details: error,
      type: type,
      onRetry: onRetry,
      onDismiss: onDismiss,
    );
  }

  static ErrorBannerType _mapErrorTypeTobannerType(ErrorType errorType) {
    switch (errorType) {
      case ErrorType.network:
      case ErrorType.timeout:
      case ErrorType.serviceUnavailable:
        return ErrorBannerType.warning;
      case ErrorType.validation:
        return ErrorBannerType.warning;
      case ErrorType.authentication:
      case ErrorType.permission:
        return ErrorBannerType.error;
      case ErrorType.notFound:
        return ErrorBannerType.info;
      case ErrorType.server:
      case ErrorType.unknown:
      default:
        return ErrorBannerType.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _getColors(theme);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon ?? _getIcon(),
                    color: colors.icon,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.text,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (onDismiss != null)
                    IconButton(
                      icon: Icon(Icons.close, color: colors.icon, size: 20),
                      onPressed: onDismiss,
                      tooltip: 'Dismiss',
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                ],
              ),
              if (showDetails && details != null && details!.isNotEmpty)
                _ExpandableDetails(
                  details: details!,
                  textColor: colors.text,
                ),
              if (onRetry != null) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: onRetry,
                      icon: Icon(Icons.refresh, color: colors.icon, size: 18),
                      label: Text(
                        'Retry',
                        style: TextStyle(color: colors.icon),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (type) {
      case ErrorBannerType.error:
        return Icons.error_outline;
      case ErrorBannerType.warning:
        return Icons.warning_amber_outlined;
      case ErrorBannerType.info:
        return Icons.info_outline;
    }
  }

  _ErrorBannerColors _getColors(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    
    switch (type) {
      case ErrorBannerType.error:
        return _ErrorBannerColors(
          background: isDark ? const Color(0xFF2D1B1B) : const Color(0xFFFDEDED),
          border: isDark ? const Color(0xFF5C2B2B) : const Color(0xFFF5C6CB),
          icon: isDark ? const Color(0xFFE57373) : const Color(0xFFD32F2F),
          text: isDark ? const Color(0xFFEF9A9A) : const Color(0xFFC62828),
          shadow: Colors.red.withValues(alpha: 0.1),
        );
      case ErrorBannerType.warning:
        return _ErrorBannerColors(
          background: isDark ? const Color(0xFF2D2A1B) : const Color(0xFFFFF8E1),
          border: isDark ? const Color(0xFF5C5A2B) : const Color(0xFFFFE082),
          icon: isDark ? const Color(0xFFFFD54F) : const Color(0xFFF57C00),
          text: isDark ? const Color(0xFFFFE082) : const Color(0xFFE65100),
          shadow: Colors.orange.withValues(alpha: 0.1),
        );
      case ErrorBannerType.info:
        return _ErrorBannerColors(
          background: isDark ? const Color(0xFF1B2D2D) : const Color(0xFFE3F2FD),
          border: isDark ? const Color(0xFF2B5C5C) : const Color(0xFF90CAF9),
          icon: isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2),
          text: isDark ? const Color(0xFF90CAF9) : const Color(0xFF0D47A1),
          shadow: Colors.blue.withValues(alpha: 0.1),
        );
    }
  }
}

/// Expandable section for showing technical error details
class _ExpandableDetails extends StatefulWidget {
  final String details;
  final Color textColor;

  const _ExpandableDetails({
    required this.details,
    required this.textColor,
  });

  @override
  State<_ExpandableDetails> createState() => _ExpandableDetailsState();
}

class _ExpandableDetailsState extends State<_ExpandableDetails> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _expanded ? 'Hide details' : 'Show details',
                style: TextStyle(
                  color: widget.textColor.withValues(alpha: 0.7),
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                ),
              ),
              Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                size: 16,
                color: widget.textColor.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: _expanded 
              ? CrossFadeState.showSecond 
              : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              widget.details,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: widget.textColor.withValues(alpha: 0.8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The type/severity of the error banner
enum ErrorBannerType {
  error,
  warning,
  info,
}

/// Color scheme for error banners
class _ErrorBannerColors {
  final Color background;
  final Color border;
  final Color icon;
  final Color text;
  final Color shadow;

  const _ErrorBannerColors({
    required this.background,
    required this.border,
    required this.icon,
    required this.text,
    required this.shadow,
  });
}
