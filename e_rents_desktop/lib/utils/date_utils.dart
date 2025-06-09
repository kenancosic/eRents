import 'package:intl/intl.dart';

/// Comprehensive date utility for consistent formatting across the eRents application
///
/// Provides standardized date formatting, relative date calculations, and common
/// date operations used throughout the property management system.
class AppDateUtils {
  // Private constructor to prevent instantiation
  AppDateUtils._();

  // Standard date formatters for consistent display
  static final DateFormat _dayMonthYear = DateFormat('dd. MMM. yyyy');
  static final DateFormat _dayMonthYearShort = DateFormat('dd.MM.yyyy');
  static final DateFormat _monthYear = DateFormat('MMM yyyy');
  static final DateFormat _dayMonth = DateFormat('dd. MMM');
  static final DateFormat _timeOnly = DateFormat('HH:mm');
  static final DateFormat _dateTimeShort = DateFormat('dd.MM.yyyy HH:mm');
  static final DateFormat _dateTimeLong = DateFormat('dd. MMM. yyyy, HH:mm');
  static final DateFormat _monthDayYear = DateFormat('MMM dd, yyyy');
  static final DateFormat _weekdayDayMonth = DateFormat('EEEE, dd. MMM');
  static final DateFormat _isoDate = DateFormat('yyyy-MM-dd');

  /// Formats date in the primary app format: "03. Jan. 2025"
  /// This is the main format used across the eRents application
  static String formatPrimary(DateTime? date) {
    if (date == null) return 'N/A';
    return _dayMonthYear.format(date);
  }

  /// Formats date in short numeric format: "03.01.2025"
  /// Useful for compact displays and tables
  static String formatShort(DateTime? date) {
    if (date == null) return 'N/A';
    return _dayMonthYearShort.format(date);
  }

  /// Formats date with time in long format: "03. Jan. 2025, 14:30"
  /// Perfect for booking details and timestamps
  static String formatWithTime(DateTime? date) {
    if (date == null) return 'N/A';
    return _dateTimeLong.format(date);
  }

  /// Formats date with time in short format: "03.01.2025 14:30"
  /// Useful for compact timestamp displays
  static String formatShortWithTime(DateTime? date) {
    if (date == null) return 'N/A';
    return _dateTimeShort.format(date);
  }

  /// Formats only the month and year: "Jan 2025"
  /// Great for period summaries and reports
  static String formatMonthYear(DateTime? date) {
    if (date == null) return 'N/A';
    return _monthYear.format(date);
  }

  /// Formats day and month only: "03. Jan"
  /// Useful for current year events
  static String formatDayMonth(DateTime? date) {
    if (date == null) return 'N/A';
    return _dayMonth.format(date);
  }

  /// Formats time only: "14:30"
  /// For time-specific displays
  static String formatTimeOnly(DateTime? date) {
    if (date == null) return 'N/A';
    return _timeOnly.format(date);
  }

  /// Formats with weekday: "Monday, 03. Jan"
  /// Great for booking calendars and schedules
  static String formatWithWeekday(DateTime? date) {
    if (date == null) return 'N/A';
    return _weekdayDayMonth.format(date);
  }

  /// Formats in US style: "Jan 03, 2025"
  /// For international compatibility
  static String formatUS(DateTime? date) {
    if (date == null) return 'N/A';
    return _monthDayYear.format(date);
  }

  /// Formats in ISO date format: "2025-01-03"
  /// For API calls and database operations
  static String formatISO(DateTime? date) {
    if (date == null) return '';
    return _isoDate.format(date);
  }

  /// Returns relative time description: "2 days ago", "In 3 days", "Today", etc.
  /// Perfect for property listings, maintenance schedules, and user activity
  static String formatRelative(DateTime? date) {
    if (date == null) return 'N/A';

    final now = DateTime.now();
    final difference = date.difference(now);
    final daysDifference = difference.inDays;
    final hoursDifference = difference.inHours;
    final minutesDifference = difference.inMinutes;

    // Future dates
    if (daysDifference > 0) {
      if (daysDifference == 1) return 'Tomorrow';
      if (daysDifference < 7) return 'In $daysDifference days';
      if (daysDifference < 30) {
        final weeks = (daysDifference / 7).round();
        return weeks == 1 ? 'In 1 week' : 'In $weeks weeks';
      }
      if (daysDifference < 365) {
        final months = (daysDifference / 30).round();
        return months == 1 ? 'In 1 month' : 'In $months months';
      }
      final years = (daysDifference / 365).round();
      return years == 1 ? 'In 1 year' : 'In $years years';
    }
    // Past dates
    else if (daysDifference < 0) {
      final absDays = daysDifference.abs();
      if (absDays == 1) return 'Yesterday';
      if (absDays < 7) return '$absDays days ago';
      if (absDays < 30) {
        final weeks = (absDays / 7).round();
        return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
      }
      if (absDays < 365) {
        final months = (absDays / 30).round();
        return months == 1 ? '1 month ago' : '$months months ago';
      }
      final years = (absDays / 365).round();
      return years == 1 ? '1 year ago' : '$years years ago';
    }
    // Today
    else {
      if (hoursDifference.abs() < 1) {
        if (minutesDifference.abs() < 1) return 'Just now';
        final absMinutes = minutesDifference.abs();
        return minutesDifference < 0
            ? '$absMinutes minutes ago'
            : 'In $absMinutes minutes';
      }
      final absHours = hoursDifference.abs();
      return hoursDifference < 0 ? '$absHours hours ago' : 'In $absHours hours';
    }
  }

  /// Returns a user-friendly booking period format
  /// Example: "03. Jan - 10. Jan 2025" or "03. Jan 2025 - 05. Feb 2025"
  static String formatBookingPeriod(DateTime? startDate, DateTime? endDate) {
    if (startDate == null || endDate == null) return 'N/A';

    // Same year
    if (startDate.year == endDate.year) {
      // Same month
      if (startDate.month == endDate.month) {
        return '${DateFormat('dd').format(startDate)} - ${formatPrimary(endDate)}';
      }
      // Different months, same year
      return '${formatDayMonth(startDate)} - ${formatPrimary(endDate)}';
    }

    // Different years
    return '${formatPrimary(startDate)} - ${formatPrimary(endDate)}';
  }

  /// Returns age in years from a birth date
  /// Useful for tenant information
  static int calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// Checks if a date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Checks if a date is in the current week
  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        date.isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  /// Checks if a date is in the current month
  static bool isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  /// Checks if a date is in the current year
  static bool isThisYear(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year;
  }

  /// Returns the start of the day (midnight)
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Returns the end of the day (23:59:59.999)
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  /// Returns the start of the month
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Returns the end of the month
  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59, 999);
  }

  /// Parses a string date in ISO format to DateTime
  /// Returns null if parsing fails
  static DateTime? parseISO(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Formats duration in a human-readable way
  /// Example: "2 hours 30 minutes", "3 days", "1 year 2 months"
  static String formatDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;

    if (days > 0) {
      if (days >= 365) {
        final years = days ~/ 365;
        final remainingDays = days % 365;
        final months = remainingDays ~/ 30;
        if (months > 0) {
          return '$years year${years > 1 ? 's' : ''} $months month${months > 1 ? 's' : ''}';
        }
        return '$years year${years > 1 ? 's' : ''}';
      } else if (days >= 30) {
        final months = days ~/ 30;
        final remainingDays = days % 30;
        if (remainingDays > 0) {
          return '$months month${months > 1 ? 's' : ''} $remainingDays day${remainingDays > 1 ? 's' : ''}';
        }
        return '$months month${months > 1 ? 's' : ''}';
      } else {
        return '$days day${days > 1 ? 's' : ''}';
      }
    } else if (hours > 0) {
      if (minutes > 0) {
        return '$hours hour${hours > 1 ? 's' : ''} $minutes minute${minutes > 1 ? 's' : ''}';
      }
      return '$hours hour${hours > 1 ? 's' : ''}';
    } else {
      return '$minutes minute${minutes > 1 ? 's' : ''}';
    }
  }

  /// Gets a formatted string for property management contexts
  /// Automatically chooses the best format based on the date's relationship to today
  static String formatSmart(DateTime? date) {
    if (date == null) return 'N/A';

    if (isToday(date)) {
      return 'Today, ${formatTimeOnly(date)}';
    } else if (isThisWeek(date)) {
      return formatWithWeekday(date);
    } else if (isThisYear(date)) {
      return formatDayMonth(date);
    } else {
      return formatPrimary(date);
    }
  }
}
