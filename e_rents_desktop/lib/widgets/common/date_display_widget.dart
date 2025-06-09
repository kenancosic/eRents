import 'package:flutter/material.dart';
import 'package:e_rents_desktop/utils/date_utils.dart';

/// Reusable date display widget that uses AppDateUtils for consistent formatting
///
/// Provides different display modes for various contexts in the eRents application
class DateDisplayWidget extends StatelessWidget {
  final DateTime? date;
  final DateDisplayMode mode;
  final TextStyle? style;
  final IconData? icon;
  final Color? iconColor;
  final String fallbackText;

  const DateDisplayWidget({
    super.key,
    required this.date,
    this.mode = DateDisplayMode.primary,
    this.style,
    this.icon,
    this.iconColor,
    this.fallbackText = 'N/A',
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = _getFormattedDate();

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: iconColor ?? Theme.of(context).textTheme.bodyMedium?.color,
          ),
          const SizedBox(width: 6),
          Text(
            formattedDate,
            style: style ?? Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      );
    }

    return Text(
      formattedDate,
      style: style ?? Theme.of(context).textTheme.bodyMedium,
    );
  }

  String _getFormattedDate() {
    if (date == null) return fallbackText;

    switch (mode) {
      case DateDisplayMode.primary:
        return AppDateUtils.formatPrimary(date);
      case DateDisplayMode.short:
        return AppDateUtils.formatShort(date);
      case DateDisplayMode.withTime:
        return AppDateUtils.formatWithTime(date);
      case DateDisplayMode.shortWithTime:
        return AppDateUtils.formatShortWithTime(date);
      case DateDisplayMode.monthYear:
        return AppDateUtils.formatMonthYear(date);
      case DateDisplayMode.dayMonth:
        return AppDateUtils.formatDayMonth(date);
      case DateDisplayMode.timeOnly:
        return AppDateUtils.formatTimeOnly(date);
      case DateDisplayMode.withWeekday:
        return AppDateUtils.formatWithWeekday(date);
      case DateDisplayMode.relative:
        return AppDateUtils.formatRelative(date);
      case DateDisplayMode.smart:
        return AppDateUtils.formatSmart(date);
      case DateDisplayMode.us:
        return AppDateUtils.formatUS(date);
    }
  }
}

/// Different date display modes for various contexts
enum DateDisplayMode {
  /// Primary format: "03. Jan. 2025"
  primary,

  /// Short numeric format: "03.01.2025"
  short,

  /// With time long format: "03. Jan. 2025, 14:30"
  withTime,

  /// With time short format: "03.01.2025 14:30"
  shortWithTime,

  /// Month and year only: "Jan 2025"
  monthYear,

  /// Day and month only: "03. Jan"
  dayMonth,

  /// Time only: "14:30"
  timeOnly,

  /// With weekday: "Monday, 03. Jan"
  withWeekday,

  /// Relative format: "2 days ago", "Tomorrow", "Just now"
  relative,

  /// Smart format: Automatically chooses best format based on date
  smart,

  /// US format: "Jan 03, 2025"
  us,
}

/// Specialized widgets for common date display scenarios
class DateDisplayWidgets {
  DateDisplayWidgets._();

  /// For property creation/update dates
  static Widget propertyDate(DateTime? date, {TextStyle? style}) {
    return DateDisplayWidget(
      date: date,
      mode: DateDisplayMode.primary,
      icon: Icons.calendar_today,
      style: style,
    );
  }

  /// For maintenance issue dates with urgency indication
  static Widget maintenanceDate(
    DateTime? date, {
    bool isUrgent = false,
    TextStyle? style,
  }) {
    return DateDisplayWidget(
      date: date,
      mode: DateDisplayMode.relative,
      icon: isUrgent ? Icons.warning_amber : Icons.build,
      iconColor: isUrgent ? Colors.red : null,
      style: style?.copyWith(
        color: isUrgent ? Colors.red : null,
        fontWeight: isUrgent ? FontWeight.bold : null,
      ),
    );
  }

  /// For booking periods
  static Widget bookingPeriod(
    DateTime? startDate,
    DateTime? endDate, {
    TextStyle? style,
  }) {
    final periodText = AppDateUtils.formatBookingPeriod(startDate, endDate);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.event_note, size: 16),
        const SizedBox(width: 6),
        Text(periodText, style: style ?? const TextStyle()),
      ],
    );
  }

  /// For user registration dates
  static Widget memberSince(DateTime? date, {TextStyle? style}) {
    return DateDisplayWidget(
      date: date,
      mode: DateDisplayMode.monthYear,
      icon: Icons.person_add,
      style: style,
    );
  }

  /// For last activity/login dates
  static Widget lastActivity(DateTime? date, {TextStyle? style}) {
    return DateDisplayWidget(
      date: date,
      mode: DateDisplayMode.relative,
      icon: Icons.access_time,
      style: style?.copyWith(color: Colors.grey[600], fontSize: 12),
    );
  }

  /// For review dates
  static Widget reviewDate(DateTime? date, {TextStyle? style}) {
    return DateDisplayWidget(
      date: date,
      mode: DateDisplayMode.smart,
      icon: Icons.rate_review,
      style: style,
    );
  }

  /// For upcoming events/bookings
  static Widget upcomingEvent(DateTime? date, {TextStyle? style}) {
    final isToday = date != null && AppDateUtils.isToday(date);
    final isThisWeek = date != null && AppDateUtils.isThisWeek(date);

    return DateDisplayWidget(
      date: date,
      mode:
          isToday || isThisWeek
              ? DateDisplayMode.relative
              : DateDisplayMode.primary,
      icon: Icons.event,
      iconColor: isToday ? Colors.green : (isThisWeek ? Colors.orange : null),
      style: style?.copyWith(
        color: isToday ? Colors.green : (isThisWeek ? Colors.orange : null),
        fontWeight: isToday ? FontWeight.bold : null,
      ),
    );
  }
}

/// Extension widget for displaying age from birth date
class AgeDisplayWidget extends StatelessWidget {
  final DateTime? birthDate;
  final TextStyle? style;
  final bool showIcon;

  const AgeDisplayWidget({
    super.key,
    required this.birthDate,
    this.style,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    if (birthDate == null) {
      return Text('N/A', style: style);
    }

    final age = AppDateUtils.calculateAge(birthDate!);
    final ageText = '$age years old';

    if (showIcon) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cake, size: 16),
          const SizedBox(width: 6),
          Text(ageText, style: style),
        ],
      );
    }

    return Text(ageText, style: style);
  }
}
