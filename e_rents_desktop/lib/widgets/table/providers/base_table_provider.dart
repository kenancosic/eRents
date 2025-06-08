import '../core/table_query.dart';
import '../core/table_columns.dart';
import '../core/table_filters.dart';

/// Base interface for table data providers
///
/// This file contains the abstract base class that all table data providers
/// must implement to ensure consistent behavior across different data sources.

/// Data provider interface for table data fetching
abstract class BaseTableProvider<T> {
  Future<PagedResult<T>> fetchData(TableQuery query);
  List<TableColumnConfig<T>> get columns;
  List<TableFilter> get availableFilters;
  String get emptyStateMessage;
}
