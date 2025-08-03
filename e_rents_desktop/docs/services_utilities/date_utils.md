# eRents Desktop Application Date Utilities Documentation

## Overview

This document provides documentation for the date utilities used in the eRents desktop application. The date utilities provide comprehensive date formatting, parsing, and calculation functions for consistent date handling across the rental management system. The utilities are implemented as a static class with various helper methods for common date operations.

## Utility Structure

The date utilities are located in the `lib/utils/date_utils.dart` file and provide:

1. Standardized date formatting for various contexts
2. Relative date calculations
3. Date parsing from string formats
4. Date boundary calculations
5. Duration formatting
6. Smart date formatting based on context

## Core Features

### Date Formatting

Multiple standardized date formatting options:

- `formatPrimary()` - Primary app format: "03. Jan. 2025"
- `formatShort()` - Short numeric format: "03.01.2025"
- `formatWithTime()` - Date with time: "03. Jan. 2025, 14:30"
- `formatShortWithTime()` - Short date with time: "03.01.2025 14:30"
- `formatMonthYear()` - Month and year only: "Jan 2025"
- `formatDayMonth()` - Day and month only: "03. Jan"
- `formatTimeOnly()` - Time only: "14:30"
- `formatWithWeekday()` - With weekday: "Monday, 03. Jan"
- `formatUS()` - US style format: "Jan 03, 2025"
- `formatISO()` - ISO format: "2025-01-03"

### Relative Date Formatting

Context-aware relative date formatting:

- `formatRelative()` - Relative time descriptions: "2 days ago", "In 3 days", "Today"
- `formatBookingPeriod()` - Booking period formatting: "03. Jan - 10. Jan 2025"
- `formatSmart()` - Context-sensitive formatting based on date relationship to today

### Date Calculations

Common date calculations and checks:

- `calculateAge()` - Calculate age from birth date
- `isToday()` - Check if date is today
- `isThisWeek()` - Check if date is in current week
- `isThisMonth()` - Check if date is in current month
- `isThisYear()` - Check if date is in current year
- `startOfDay()` - Get start of day (midnight)
- `endOfDay()` - Get end of day (23:59:59.999)
- `startOfMonth()` - Get start of month
- `endOfMonth()` - Get end of month

### Duration Formatting

Human-readable duration formatting:

- `formatDuration()` - Format durations: "2 hours 30 minutes", "3 days", "1 year 2 months"

### Date Parsing

String to date conversion:

- `parseISO()` - Parse ISO format strings to DateTime

## Implementation Details

### Class Structure

```dart
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
  // ...
}
```

### Primary Formatting Methods

```dart
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
```

### Relative Date Formatting

```dart
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
    if (daysDifference < 30) return 'In ${daysDifference ~/ 7} weeks';
    return formatPrimary(date);
  }
  
  // Past dates
  if (daysDifference < 0) {
    final absDays = daysDifference.abs();
    if (absDays == 1) return 'Yesterday';
    if (absDays < 7) return '$absDays days ago';
    if (absDays < 30) return '${absDays ~/ 7} weeks ago';
    if (absDays < 365) return '${absDays ~/ 30} months ago';
    return '${absDays ~/ 365} years ago';
  }
  
  // Today
  if (hoursDifference < 0) {
    final absHours = hoursDifference.abs();
    if (absHours > 0) return '$absHours hours ago';
    
    if (minutesDifference < 0) {
      final absMinutes = minutesDifference.abs();
      if (absMinutes > 0) return '$absMinutes minutes ago';
      return 'Just now';
    }
    
    if (minutesDifference > 0) return 'In $minutesDifference minutes';
    return 'Just now';
  }
  
  if (hoursDifference > 0) return 'In $hoursDifference hours';
  return 'Today';
}
```

### Smart Date Formatting

```dart
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
```

### Duration Formatting

```dart
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
```

## Usage Examples

### Basic Date Formatting

```dart
final date = DateTime(2025, 1, 3, 14, 30);

// Primary format
final primary = AppDateUtils.formatPrimary(date); // "03. Jan. 2025"

// Short format
final short = AppDateUtils.formatShort(date); // "03.01.2025"

// With time
final withTime = AppDateUtils.formatWithTime(date); // "03. Jan. 2025, 14:30"

// Time only
final timeOnly = AppDateUtils.formatTimeOnly(date); // "14:30"

// ISO format
final iso = AppDateUtils.formatISO(date); // "2025-01-03"
```

### Relative Date Formatting

```dart
final pastDate = DateTime.now().subtract(Duration(days: 2));
final futureDate = DateTime.now().add(Duration(days: 3));

// Relative formatting
final pastRelative = AppDateUtils.formatRelative(pastDate); // "2 days ago"
final futureRelative = AppDateUtils.formatRelative(futureDate); // "In 3 days"

// Booking period
final startDate = DateTime(2025, 1, 3);
final endDate = DateTime(2025, 1, 10);
final period = AppDateUtils.formatBookingPeriod(startDate, endDate); // "03. Jan - 10. Jan 2025"
```

### Date Calculations

```dart
final date = DateTime(2025, 1, 3, 14, 30);

// Date boundaries
final startOfDay = AppDateUtils.startOfDay(date); // 2025-01-03 00:00:00.000
final endOfDay = AppDateUtils.endOfDay(date); // 2025-01-03 23:59:59.999

// Date checks
final isToday = AppDateUtils.isToday(date);
final isThisWeek = AppDateUtils.isThisWeek(date);
final isThisMonth = AppDateUtils.isThisMonth(date);
final isThisYear = AppDateUtils.isThisYear(date);

// Age calculation
final birthDate = DateTime(1990, 5, 15);
final age = AppDateUtils.calculateAge(birthDate); // 34 (as of 2025)
```

### Duration Formatting

```dart
// Duration formatting
final duration1 = Duration(hours: 2, minutes: 30);
final formatted1 = AppDateUtils.formatDuration(duration1); // "2 hours 30 minutes"

final duration2 = Duration(days: 3);
final formatted2 = AppDateUtils.formatDuration(duration2); // "3 days"

final duration3 = Duration(days: 400);
final formatted3 = AppDateUtils.formatDuration(duration3); // "1 year 1 month"
```

### Smart Formatting

```dart
// Smart formatting based on date context
final today = DateTime.now();
final thisWeek = DateTime.now().add(Duration(days: 2));
final thisYear = DateTime(2025, 6, 15);
final futureYear = DateTime(2026, 3, 10);

final smartToday = AppDateUtils.formatSmart(today); // "Today, 14:30"
final smartWeek = AppDateUtils.formatSmart(thisWeek); // "Monday, 05. Jan"
final smartYear = AppDateUtils.formatSmart(thisYear); // "15. Jun"
final smartFuture = AppDateUtils.formatSmart(futureYear); // "10. Mar. 2026"
```

## Integration with Providers

The date utilities integrate with providers for consistent date handling:

```dart
// In PropertyProvider
String formatPropertyDate(DateTime? date) {
  return AppDateUtils.formatPrimary(date);
}

String formatPropertyPeriod(DateTime? start, DateTime? end) {
  return AppDateUtils.formatBookingPeriod(start, end);
}

String formatPropertyRelativeDate(DateTime? date) {
  return AppDateUtils.formatRelative(date);
}

// In BookingProvider
String formatBookingDate(DateTime? date) {
  return AppDateUtils.formatWithTime(date);
}

String formatBookingDuration(Duration duration) {
  return AppDateUtils.formatDuration(duration);
}
```

## Integration with Widgets

Widgets use the date utilities for consistent date display:

```dart
// In PropertyCardWidget
Text(AppDateUtils.formatPrimary(property.createdAt));

// In BookingTimelineWidget
Text(AppDateUtils.formatRelative(booking.startDate));

// In DurationDisplayWidget
Text(AppDateUtils.formatDuration(booking.duration));

// In SmartDateWidget
Text(AppDateUtils.formatSmart(date));
```

## Best Practices

1. **Consistency**: Use standardized formats throughout the application
2. **Context Awareness**: Choose appropriate formats for different contexts
3. **Null Safety**: Handle null dates gracefully
4. **Localization**: Consider localization requirements for date formats
5. **Performance**: Date formatting is lightweight but avoid excessive calls
6. **Testing**: Test date formatting with various date values
7. **Boundary Cases**: Handle edge cases like leap years and month boundaries
8. **Time Zones**: Be aware of time zone implications for date operations
9. **User Experience**: Use relative dates for better user experience
10. **Documentation**: Document format choices and their purposes

## Extensibility

The date utilities support easy extension:

1. **New Formats**: Add new formatting methods for specific use cases
2. **Custom Locales**: Add support for additional locales
3. **Format Configuration**: Add configurable format options
4. **Business Logic**: Add business-specific date calculations
5. **Time Zone Support**: Add time zone conversion methods
6. **Calendar Integration**: Add calendar-specific formatting
7. **Age Ranges**: Add age range categorization
8. **Holiday Calculations**: Add holiday-aware date calculations

This date utilities documentation ensures consistent implementation of date handling and provides a solid foundation for future development.
