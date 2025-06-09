import 'package:flutter/material.dart';
import 'package:e_rents_desktop/utils/date_utils.dart';
import '../custom_table.dart';

/// Base Table Factory
///
/// Provides common table creation patterns, column builders, and utilities
/// that can be used across all specific table factories to reduce duplication.
///
/// Features:
/// - Common column builders (ID, date, status, actions)
/// - Standardized cell components (text, badge, icon, link)
/// - Default filter configurations
/// - Consistent table configuration options
abstract class BaseTableFactory {
  // =============================================================================
  // COMMON COLUMN BUILDERS
  // =============================================================================

  /// Create an ID column with consistent styling
  static TableColumnConfig<T> idColumn<T>({
    required String key,
    required String Function(T) idExtractor,
    String label = 'ID',
    String prefix = '#',
    FlexColumnWidth width = const FlexColumnWidth(0.6),
  }) {
    return TableColumnConfig<T>(
      key: key,
      label: label,
      cellBuilder: (item) => _buildIdCell(prefix + idExtractor(item)),
      width: width,
    );
  }

  /// Create a date column with consistent formatting
  static TableColumnConfig<T> dateColumn<T>({
    required String key,
    required DateTime Function(T) dateExtractor,
    required String label,
    DateFormat format = DateFormat.short,
    FlexColumnWidth width = const FlexColumnWidth(1.0),
  }) {
    return TableColumnConfig<T>(
      key: key,
      label: label,
      cellBuilder: (item) => _buildDateCell(dateExtractor(item), format),
      width: width,
    );
  }

  /// Create a status column with color coding
  static TableColumnConfig<T> statusColumn<T>({
    required String key,
    required String Function(T) statusExtractor,
    required Color Function(T) colorExtractor,
    String label = 'Status',
    FlexColumnWidth width = const FlexColumnWidth(0.8),
  }) {
    return TableColumnConfig<T>(
      key: key,
      label: label,
      cellBuilder:
          (item) =>
              _buildStatusCell(statusExtractor(item), colorExtractor(item)),
      width: width,
    );
  }

  /// Create a link column that navigates to another page
  static TableColumnConfig<T> linkColumn<T>({
    required String key,
    required String Function(T) textExtractor,
    required VoidCallback Function(T) navigationBuilder,
    required String label,
    IconData? icon,
    FlexColumnWidth width = const FlexColumnWidth(1.5),
  }) {
    return TableColumnConfig<T>(
      key: key,
      label: label,
      cellBuilder:
          (item) => _buildLinkCell(
            textExtractor(item),
            navigationBuilder(item),
            icon,
          ),
      width: width,
    );
  }

  /// Create an actions column with multiple action buttons
  static TableColumnConfig<T> actionsColumn<T>({
    required List<ActionCellButton> Function(T) actionsBuilder,
    String label = 'Actions',
    FlexColumnWidth width = const FlexColumnWidth(1.0),
  }) {
    return TableColumnConfig<T>(
      key: 'actions',
      label: label,
      cellBuilder: (item) => _buildActionsCell(actionsBuilder(item)),
      sortable: false,
      width: width,
    );
  }

  // =============================================================================
  // COMMON CELL BUILDERS
  // =============================================================================

  static Widget _buildIdCell(String id) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        id,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontFamily: 'monospace',
          fontSize: 13,
        ),
      ),
    );
  }

  static Widget _buildDateCell(DateTime date, DateFormat format) {
    String formattedDate;
    switch (format) {
      case DateFormat.short:
        formattedDate = AppDateUtils.formatShort(date);
        break;
      case DateFormat.primary:
        formattedDate = AppDateUtils.formatPrimary(date);
        break;
      case DateFormat.relative:
        formattedDate = AppDateUtils.formatRelative(date);
        break;
      case DateFormat.shortWithTime:
        formattedDate = AppDateUtils.formatShortWithTime(date);
        break;
    }

    return Text(formattedDate, style: const TextStyle(fontSize: 14));
  }

  static Widget _buildStatusCell(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  static Widget _buildLinkCell(
    String text,
    VoidCallback onTap,
    IconData? icon,
  ) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildActionsCell(List<ActionCellButton> actions) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children:
          actions.map((action) {
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Tooltip(
                message: action.tooltip,
                child: IconButton(
                  onPressed: action.onPressed,
                  icon: Icon(action.icon, size: 18),
                  iconSize: 18,
                  constraints: const BoxConstraints.tightFor(
                    width: 32,
                    height: 32,
                  ),
                  padding: EdgeInsets.zero,
                  color: action.color ?? Colors.grey.shade600,
                ),
              ),
            );
          }).toList(),
    );
  }

  // =============================================================================
  // COMMON FILTER BUILDERS
  // =============================================================================

  /// Create a status filter dropdown
  static TableFilter statusFilter({
    required List<FilterOption> statusOptions,
    String key = 'Status',
    String label = 'Status',
  }) {
    return TableFilter(
      key: key,
      label: label,
      type: FilterType.dropdown,
      options: statusOptions,
    );
  }

  /// Create a date range filter
  static TableFilter dateRangeFilter({
    required String key,
    required String label,
  }) {
    return TableFilter(key: key, label: label, type: FilterType.dateRange);
  }

  /// Create a text search filter
  static TableFilter textFilter({required String key, required String label}) {
    return TableFilter(key: key, label: label, type: FilterType.text);
  }

  /// Create a checkbox filter
  static TableFilter checkboxFilter({
    required String key,
    required String label,
  }) {
    return TableFilter(key: key, label: label, type: FilterType.checkbox);
  }

  // =============================================================================
  // COMMON TABLE CONFIGURATIONS
  // =============================================================================

  /// Create a standard table configuration with common defaults
  static TableConfig createTableConfig({
    required String title,
    required String searchHint,
    required String emptyStateMessage,
    Widget? headerActions,
    void Function(dynamic)? onRowTap,
    void Function(dynamic)? onRowDoubleTap,
    int defaultPageSize = 25,
  }) {
    return TableConfig(
      title: title,
      searchHint: searchHint,
      emptyStateMessage: emptyStateMessage,
      headerActions: headerActions,
      onRowTap: onRowTap,
      onRowDoubleTap: onRowDoubleTap,
      defaultPageSize: defaultPageSize,
    );
  }
}

// =============================================================================
// SUPPORTING TYPES
// =============================================================================

/// Date format options for date columns
enum DateFormat {
  short, // DD/MM/YYYY
  primary, // 03. Jan. 2025
  relative, // 2 days ago
  shortWithTime, // DD/MM/YYYY HH:MM
}

/// Configuration for action buttons in action columns
class ActionCellButton {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  const ActionCellButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });
}

/// Table configuration wrapper
class TableConfig {
  final String title;
  final String searchHint;
  final String emptyStateMessage;
  final Widget? headerActions;
  final void Function(dynamic)? onRowTap;
  final void Function(dynamic)? onRowDoubleTap;
  final int defaultPageSize;

  const TableConfig({
    required this.title,
    required this.searchHint,
    required this.emptyStateMessage,
    this.headerActions,
    this.onRowTap,
    this.onRowDoubleTap,
    this.defaultPageSize = 25,
  });
}
