/// Core types and enums for the Universal Table System
///
/// This file contains common types, enums, and interfaces used throughout
/// the table system to ensure consistency and type safety.
library;

/// Filter types for table columns
enum FilterType { dropdown, dateRange, checkbox, multiSelect, text }

/// Filter option for dropdowns and multi-select
class FilterOption {
  final String label;
  final dynamic value;

  const FilterOption({required this.label, required this.value});
}
