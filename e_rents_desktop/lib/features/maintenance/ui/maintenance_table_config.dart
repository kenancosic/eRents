import 'package:flutter/material.dart';

/// Centralized table column configuration for Maintenance list screens.
/// Keeps column titles, order and sort field mapping in one place to avoid duplication.
class MaintenanceTableConfig {
  MaintenanceTableConfig._();

  /// Columns shown in the DesktopDataTable for Maintenance issues.
  static const List<DataColumn> columns = <DataColumn>[
    DataColumn(label: Text('Priority')),
    DataColumn(label: Text('Title')),
    DataColumn(label: Text('Status')),
    DataColumn(label: Text('Reported By')),
    DataColumn(label: Text('Date')),
    DataColumn(label: Text('Actions')),
  ];

  /// Maps DataTable column index to API sort field.
  /// Returns null when the column is not sortable.
  static String? sortFieldForIndex(int columnIndex) {
    switch (columnIndex) {
      case 0:
        // Sort by severity weight (highest first when ascending=false)
        return 'prioritySeverity';
      case 1:
        return 'title';
      case 2:
        return 'status';
      case 3:
        return null; // reported by - not sortable
      case 4:
        return 'createdAt';
      case 5:
        return null; // actions column not sortable
      default:
        return null;
    }
  }
}