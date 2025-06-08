import 'package:flutter/material.dart';
import '../core/table_query.dart';
import '../core/table_columns.dart';
import '../core/table_filters.dart';
import '../core/table_types.dart';
import '../universal_table_widget.dart';
import '../providers/base_table_provider.dart';

/// Universal Table Utilities - Helper methods for common table operations
///
/// This file contains static utility methods for creating tables, cells,
/// columns, and filters. Similar to ImageUtils for image handling.

class UniversalTable {
  /// Quick table creation using the modular table system
  static UniversalTableWidget<T> create<T>({
    required Future<PagedResult<T>> Function(Map<String, dynamic>) fetchData,
    required List<TableColumnConfig<T>> columns,
    String title = '',
    String searchHint = 'Search...',
    String emptyStateMessage = 'No data available',
    List<TableFilter>? filters,
    Widget? headerActions,
    void Function(T)? onRowTap,
    void Function(T)? onRowDoubleTap,
    int defaultPageSize = 25,
  }) {
    // Create a simple provider for the quick table
    final provider = _QuickTableProvider<T>(
      fetchDataFunction: fetchData,
      columns: columns,
      filters: filters ?? [],
      emptyMessage: emptyStateMessage,
    );

    return UniversalTableWidget<T>(
      dataProvider: provider,
      title: title,
      searchHint: searchHint,
      headerActions: headerActions,
      onRowTap: onRowTap,
      onRowDoubleTap: onRowDoubleTap,
      defaultPageSize: defaultPageSize,
    );
  }

  /// Helper: Create standard text cell
  static Widget textCell(String text, {TextStyle? style}) {
    return Text(
      text,
      style: style ?? const TextStyle(fontSize: 14),
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Helper: Create status badge cell
  static Widget statusCell(String status, {Color? color}) {
    final statusColor = color ?? Colors.blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color ?? Colors.blue,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  /// Helper: Create currency cell
  static Widget currencyCell(double amount, {String currency = 'BAM'}) {
    return textCell(
      '${amount.toStringAsFixed(2)} $currency',
      style: const TextStyle(fontWeight: FontWeight.w600),
    );
  }

  /// Helper: Create date cell
  static Widget dateCell(DateTime? date) {
    if (date == null) return textCell('N/A');
    return textCell(date.toLocal().toString().split(' ')[0]);
  }

  /// Helper: Create column configuration
  static TableColumnConfig<T> column<T>({
    required String key,
    required String label,
    required Widget Function(T) cellBuilder,
    bool sortable = true,
    TableColumnWidth? width,
  }) {
    return TableColumnConfig<T>(
      key: key,
      label: label,
      cellBuilder: cellBuilder,
      sortable: sortable,
      width: width ?? const FlexColumnWidth(1),
    );
  }

  /// Helper: Create filter configuration
  static TableFilter filter({
    required String key,
    required String label,
    required FilterType type,
    List<FilterOption>? options,
  }) {
    return TableFilter(key: key, label: label, type: type, options: options);
  }

  /// Helper: Create priority badge cell
  static Widget priorityCell(String priority, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color ?? Colors.grey,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          priority,
          style: const TextStyle(fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// Helper: Create clickable link cell with icon
  static Widget linkCell({
    required String text,
    required VoidCallback onTap,
    IconData? icon,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(icon, size: 18, color: Colors.grey[600]),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, color: color ?? Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper: Create icon action button cell
  static Widget iconActionCell({
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
    Color? color,
  }) {
    return IconButton(
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      constraints: const BoxConstraints(),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      color: color,
      onPressed: onPressed,
    );
  }
}

/// Simple implementation for quick tables
class _QuickTableProvider<T> extends BaseTableProvider<T> {
  final Future<PagedResult<T>> Function(Map<String, dynamic>) fetchDataFunction;
  final List<TableColumnConfig<T>> _columns;
  final List<TableFilter> _filters;
  final String emptyMessage;

  _QuickTableProvider({
    required this.fetchDataFunction,
    required List<TableColumnConfig<T>> columns,
    required List<TableFilter> filters,
    required this.emptyMessage,
  }) : _columns = columns,
       _filters = filters;

  @override
  List<TableColumnConfig<T>> get columns => _columns;

  @override
  List<TableFilter> get availableFilters => _filters;

  @override
  String get emptyStateMessage => emptyMessage;

  @override
  Future<PagedResult<T>> fetchData(TableQuery query) async {
    final params = <String, dynamic>{
      'page': query.page + 1, // Backend expects 1-based
      'pageSize': query.pageSize,
    };

    if (query.searchTerm?.isNotEmpty == true) {
      params['searchTerm'] = query.searchTerm;
    }

    if (query.sortBy?.isNotEmpty == true) {
      params['sortBy'] = query.sortBy;
      params['sortDesc'] = query.sortDescending;
    }

    query.filters.forEach((key, value) {
      if (value != null) {
        params[key] = value;
      }
    });

    return await fetchDataFunction(params);
  }
}
