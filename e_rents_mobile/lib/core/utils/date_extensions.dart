import 'package:intl/intl.dart';

/// Extension methods for DateTime formatting
/// 
/// Consolidates date formatting logic that was previously duplicated
/// across multiple providers and widgets.
extension DateFormatting on DateTime {
  /// Format to API-compatible date string (yyyy-MM-dd)
  /// 
  /// Used when sending dates to backend endpoints that expect DateOnly format.
  /// Example: 2024-12-02
  String toApiDate() {
    final y = year.toString().padLeft(4, '0');
    final m = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Format for display (dd/MM/yyyy)
  /// 
  /// User-friendly format for UI display.
  /// Example: 02/12/2024
  String toDisplayDate() => DateFormat('dd/MM/yyyy').format(this);

  /// Format for display with time (dd/MM/yyyy HH:mm)
  /// 
  /// Example: 02/12/2024 14:30
  String toDisplayDateTime() => DateFormat('dd/MM/yyyy HH:mm').format(this);

  /// Format for short display (MMM d, yyyy)
  /// 
  /// Example: Dec 2, 2024
  String toShortDate() => DateFormat('MMM d, yyyy').format(this);

  /// Format for long display (MMMM d, yyyy)
  /// 
  /// Example: December 2, 2024
  String toLongDate() => DateFormat('MMMM d, yyyy').format(this);

  /// Format time only (HH:mm)
  /// 
  /// Example: 14:30
  String toTimeOnly() => DateFormat('HH:mm').format(this);

  /// Check if this date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if this date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }

  /// Check if this date is in the past (before today)
  bool get isPast => isBefore(DateTime.now());

  /// Check if this date is in the future (after today)
  bool get isFuture => isAfter(DateTime.now());

  /// Get relative description (Today, Yesterday, or formatted date)
  String toRelativeDate() {
    if (isToday) return 'Today';
    if (isYesterday) return 'Yesterday';
    return toShortDate();
  }
}

/// Extension for nullable DateTime
extension NullableDateFormatting on DateTime? {
  /// Format to API date or return empty string if null
  String toApiDateOrEmpty() => this?.toApiDate() ?? '';

  /// Format to display date or return placeholder if null
  String toDisplayDateOr(String placeholder) => this?.toDisplayDate() ?? placeholder;

  /// Format to short date or return placeholder if null  
  String toShortDateOr(String placeholder) => this?.toShortDate() ?? placeholder;
}
