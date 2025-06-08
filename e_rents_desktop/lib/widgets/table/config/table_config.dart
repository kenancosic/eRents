import 'package:flutter/material.dart';

/// Universal Table Configuration - Define once, use everywhere
///
/// This file contains configuration classes for customizing table behavior
/// and appearance without modifying the core table logic.

class UniversalTableConfig<TModel> {
  final String title;
  final String searchHint;
  final String emptyStateMessage;
  final Map<String, String> columnLabels;
  final Map<String, Widget Function(TModel)> customCellBuilders;
  final Map<String, TableColumnWidth> columnWidths;
  final List<String> hiddenColumns;
  final List<dynamic> customFilters; // Will be typed properly later
  final Widget? headerActions;
  final void Function(TModel)? onRowTap;
  final void Function(TModel)? onRowDoubleTap;

  const UniversalTableConfig({
    this.title = '',
    this.searchHint = 'Search...',
    this.emptyStateMessage = 'No data available',
    this.columnLabels = const {},
    this.customCellBuilders = const {},
    this.columnWidths = const {},
    this.hiddenColumns = const [],
    this.customFilters = const [],
    this.headerActions,
    this.onRowTap,
    this.onRowDoubleTap,
  });
}
