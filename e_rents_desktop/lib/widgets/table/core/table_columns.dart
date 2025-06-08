import 'package:flutter/material.dart';
import 'table_filters.dart';

/// Column configuration structures for table columns
///
/// This file contains the classes and structures used to define
/// table columns, their behavior, and display properties.

/// Column configuration for tables
class TableColumnConfig<T> {
  final String key;
  final String label;
  final bool sortable;
  final bool filterable;
  final TableColumnWidth width;
  final Widget Function(T item) cellBuilder;
  final TableFilter? filter;

  const TableColumnConfig({
    required this.key,
    required this.label,
    required this.cellBuilder,
    this.sortable = true,
    this.filterable = false,
    this.width = const FlexColumnWidth(1),
    this.filter,
  });
}
