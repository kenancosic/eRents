import 'package:e_rents_desktop/models/paged_result.dart';
import 'package:e_rents_desktop/utils/date_utils.dart';
import 'package:flutter/material.dart';
import '../core/table_query.dart';
import '../core/table_columns.dart';
import '../core/table_filters.dart';
import '../core/table_types.dart';
import '../config/table_config.dart';
import 'base_table_provider.dart';

/// Base class for Universal Table Providers - 90% automatic functionality
///
/// This provider extends BaseTableProvider to automatically handle:
/// - Backend Universal System integration
/// - Standard UI components and interactions
/// - Query parameter building and transformation
///
/// Only model-specific column definitions are required (10% custom code)
abstract class TableProvider<TModel> extends BaseTableProvider<TModel> {
  final Future<PagedResult<TModel>> Function(Map<String, dynamic>)
  fetchDataFunction;
  final UniversalTableConfig<TModel> config;

  TableProvider({required this.fetchDataFunction, required this.config});

  @override
  String get emptyStateMessage => config.emptyStateMessage;

  @override
  Future<PagedResult<TModel>> fetchData(TableQuery query) async {
    final params = _buildSearchParams(query);
    return await fetchDataFunction(params);
  }

  /// ✅ AUTOMATIC: Build search parameters from table query (mirrors backend Universal System)
  Map<String, dynamic> _buildSearchParams(TableQuery query) {
    final params = <String, dynamic>{
      'page': query.page + 1, // Backend expects 1-based
      'pageSize': query.pageSize,
    };

    // Add search term
    if (query.searchTerm?.isNotEmpty == true) {
      params['searchTerm'] = query.searchTerm;
    }

    // Add sorting
    if (query.sortBy?.isNotEmpty == true) {
      params['sortBy'] = query.sortBy;
      params['sortDesc'] = query.sortDescending;
    }

    // Add filters
    query.filters.forEach((key, value) {
      if (value != null) {
        params[key] = value;
      }
    });

    return params;
  }

  /// ✅ HELPERS: Create standard cells and columns

  /// Helper: Create standard column
  TableColumnConfig<TModel> createColumn({
    required String key,
    required String label,
    required Widget Function(TModel) cellBuilder,
    bool sortable = true,
    TableColumnWidth? width,
  }) {
    return TableColumnConfig<TModel>(
      key: key,
      label: config.columnLabels[key] ?? label,
      cellBuilder: config.customCellBuilders[key] ?? cellBuilder,
      sortable: sortable,
      width: config.columnWidths[key] ?? width ?? const FlexColumnWidth(1),
    );
  }

  /// Helper: Create standard filter
  TableFilter createFilter({
    required String key,
    required String label,
    required FilterType type,
    List<FilterOption>? options,
  }) {
    return TableFilter(key: key, label: label, type: type, options: options);
  }

  /// Helper: Create standard text cell
  Widget textCell(String text, {TextStyle? style}) {
    return Text(
      text,
      style: style ?? const TextStyle(fontSize: 14),
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Helper: Create status badge cell
  Widget statusCell(String status, {Color? color}) {
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
  Widget currencyCell(double amount, {String currency = 'BAM'}) {
    return textCell(
      '${amount.toStringAsFixed(2)} $currency',
      style: const TextStyle(fontWeight: FontWeight.w600),
    );
  }

  /// Helper: Create date cell
  Widget dateCell(DateTime? date) {
    if (date == null) return textCell('N/A');
    return textCell(AppDateUtils.formatShort(date));
  }

  /// Helper: Create action buttons cell
  Widget actionCell(List<Widget> actions) {
    return Row(mainAxisSize: MainAxisSize.min, children: actions);
  }

  /// Helper: Create priority badge cell
  Widget priorityCell(String priority, {Color? color}) {
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
  Widget linkCell({
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
  Widget iconActionCell({
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
