import 'package:flutter/material.dart';
import 'package:e_rents_desktop/widgets/filters/date_range_filter.dart';

/// Specialized filter component for Reports and Statistics screens
class ReportFilters extends StatelessWidget {
  final Function(DateTime, DateTime) onDateRangeChanged;
  final Function(List<String>)? onPropertyFilterChanged;
  final String? customTitle;
  final bool showPropertyFilter;

  const ReportFilters({
    super.key,
    required this.onDateRangeChanged,
    this.onPropertyFilterChanged,
    this.customTitle,
    this.showPropertyFilter = false,
  });

  @override
  Widget build(BuildContext context) {
    return DateRangeFilter(
      onDateRangeChanged: onDateRangeChanged,
      onPropertyFilterChanged: onPropertyFilterChanged,
      config: DateRangeFilterConfig(
        title: customTitle ?? 'Filter Reports',
        presetRanges: const [
          'Last 7 Days',
          'Last 30 Days',
          'This Month',
          'Last Month',
          'Last 90 Days',
          'This Year',
          'Last Year',
        ],
        showPresets: true,
        showPropertyFilter: showPropertyFilter,
        firstDate: DateTime(2020),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      ),
    );
  }
}

/// Specialized filter component for Statistics with different defaults
class StatisticsFilters extends StatelessWidget {
  final Function(DateTime, DateTime) onDateRangeChanged;
  final Function(List<String>)? onPropertyFilterChanged;

  const StatisticsFilters({
    super.key,
    required this.onDateRangeChanged,
    this.onPropertyFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DateRangeFilter(
      onDateRangeChanged: onDateRangeChanged,
      onPropertyFilterChanged: onPropertyFilterChanged,
      config: const DateRangeFilterConfig(
        title: 'Filter Statistics',
        presetRanges: [
          'Last 7 Days',
          'Last 30 Days',
          'This Month',
          'Last 3 Months',
          'This Year',
          'Last Year',
        ],
        showPresets: true,
        showPropertyFilter:
            false, // Statistics typically don't filter by property
        firstDate: null, // Use defaults
        lastDate: null,
      ),
    );
  }
}
