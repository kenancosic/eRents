import 'table_types.dart';

/// Filter configuration structures for table columns
///
/// This file contains the classes and structures used to define
/// filterable columns and their configuration options.

/// Filter configuration for table columns
class TableFilter {
  final String key;
  final String label;
  final FilterType type;
  final List<FilterOption>? options;
  final dynamic defaultValue;

  const TableFilter({
    required this.key,
    required this.label,
    required this.type,
    this.options,
    this.defaultValue,
  });
}
