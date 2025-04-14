import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/features/reports/providers/reports_provider.dart';
import 'package:e_rents_desktop/features/reports/providers/financial_report_provider.dart';
import 'package:e_rents_desktop/features/reports/providers/occupancy_report_provider.dart';
import 'package:e_rents_desktop/features/reports/providers/maintenance_report_provider.dart';
import 'package:e_rents_desktop/features/reports/providers/tenant_report_provider.dart';
import 'package:e_rents_desktop/features/reports/widgets/generic_report_table.dart';
import 'package:e_rents_desktop/models/reports/reports.dart';
import 'package:e_rents_desktop/base/base_provider.dart';

class ReportTable extends StatelessWidget {
  const ReportTable({super.key});

  // Store a map to track refresh attempts by provider type
  static final Map<String, bool> _refreshAttempted = {};

  @override
  Widget build(BuildContext context) {
    final reportsProvider = Provider.of<ReportsProvider>(context);
    final reportType = reportsProvider.currentReportType;

    // Get the appropriate report data and columns based on type
    final columns = _getColumns(reportType);
    final columnWidths = _getColumnWidths(reportType);

    // Return the appropriate table based on report type
    switch (reportType) {
      case ReportType.financial:
        final provider = Provider.of<FinancialReportProvider>(context);
        return _buildTableWithErrorHandling(
          context: context,
          provider: provider,
          reportType: reportType,
          child:
              GenericReportTable<FinancialReportItem, FinancialReportProvider>(
                provider: provider,
                columns: columns,
                columnWidths: columnWidths,
                cellsBuilder: _buildFinancialCells,
                searchStringBuilder: _buildFinancialSearchString,
                emptyStateWidget: const Center(
                  child: Text(
                    'No financial data available for the selected period',
                  ),
                ),
              ),
        );
      case ReportType.occupancy:
        final provider = Provider.of<OccupancyReportProvider>(context);
        return _buildTableWithErrorHandling(
          context: context,
          provider: provider,
          reportType: reportType,
          child:
              GenericReportTable<OccupancyReportItem, OccupancyReportProvider>(
                provider: provider,
                columns: columns,
                columnWidths: columnWidths,
                cellsBuilder: _buildOccupancyCells,
                searchStringBuilder: _buildOccupancySearchString,
                emptyStateWidget: const Center(
                  child: Text('No occupancy data available'),
                ),
              ),
        );
      case ReportType.maintenance:
        final provider = Provider.of<MaintenanceReportProvider>(context);
        return _buildTableWithErrorHandling(
          context: context,
          provider: provider,
          reportType: reportType,
          child: GenericReportTable<
            MaintenanceReportItem,
            MaintenanceReportProvider
          >(
            provider: provider,
            columns: columns,
            columnWidths: columnWidths,
            cellsBuilder: _buildMaintenanceCells,
            searchStringBuilder: _buildMaintenanceSearchString,
            emptyStateWidget: const Center(
              child: Text(
                'No maintenance data available for the selected period',
              ),
            ),
          ),
        );
      case ReportType.tenant:
        final provider = Provider.of<TenantReportProvider>(context);
        return _buildTableWithErrorHandling(
          context: context,
          provider: provider,
          reportType: reportType,
          child: GenericReportTable<TenantReportItem, TenantReportProvider>(
            provider: provider,
            columns: columns,
            columnWidths: columnWidths,
            cellsBuilder: _buildTenantCells,
            searchStringBuilder: _buildTenantSearchString,
            emptyStateWidget: const Center(
              child: Text('No tenant data available'),
            ),
          ),
        );
    }
  }

  // Helper method to add error handling and retry functionality
  Widget _buildTableWithErrorHandling({
    required BuildContext context,
    required BaseProvider provider,
    required ReportType reportType,
    required Widget child,
  }) {
    debugPrint(
      'ReportTable._buildTableWithErrorHandling: provider state=${provider.state}, itemCount=${provider.items.length}',
    );

    final String providerKey = reportType.toString();

    // Check if provider is in error state
    if (provider.state == ViewState.Error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error loading data: ${provider.errorMessage ?? "Unknown error"}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: () {
                debugPrint('Retry button pressed for $reportType');
                _refreshAttempted[providerKey] = false; // Reset the flag
                provider.fetchItems();
              },
            ),
          ],
        ),
      );
    }

    // Check if provider is in loading state
    if (provider.state == ViewState.Busy) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading data...'),
          ],
        ),
      );
    }

    // If items are empty but not in loading state, force a refresh ONCE
    if (provider.items.isEmpty &&
        provider.state != ViewState.Busy &&
        !(_refreshAttempted[providerKey] ?? false)) {
      debugPrint(
        'ReportTable: No data but not in loading state for $reportType. Forcing refresh.',
      );
      _refreshAttempted[providerKey] =
          true; // Mark that we've attempted a refresh
      Future.microtask(() => provider.fetchItems());

      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading initial data...'),
          ],
        ),
      );
    }

    // If we've refreshed and still have no data, show empty state
    if (provider.items.isEmpty) {
      switch (reportType) {
        case ReportType.financial:
          return const Center(
            child: Text('No financial data available for the selected period'),
          );
        case ReportType.occupancy:
          return const Center(child: Text('No occupancy data available'));
        case ReportType.maintenance:
          return const Center(
            child: Text(
              'No maintenance data available for the selected period',
            ),
          );
        case ReportType.tenant:
          return const Center(child: Text('No tenant data available'));
      }
    }

    return child;
  }

  // Generate columns based on report type
  List<DataColumn> _getColumns(ReportType reportType) {
    switch (reportType) {
      case ReportType.financial:
        return [
          const DataColumn(label: Text('Date', softWrap: true)),
          const DataColumn(label: Text('Property', softWrap: true)),
          const DataColumn(label: Text('Unit', softWrap: true)),
          const DataColumn(label: Text('Transaction Type', softWrap: true)),
          const DataColumn(label: Text('Amount', softWrap: true)),
          const DataColumn(label: Text('Balance', softWrap: true)),
        ];
      case ReportType.occupancy:
        return [
          const DataColumn(label: Text('Property', softWrap: true)),
          const DataColumn(label: Text('Total Units', softWrap: true)),
          const DataColumn(label: Text('Occupied', softWrap: true)),
          const DataColumn(label: Text('Vacant', softWrap: true)),
          const DataColumn(label: Text('Occupancy Rate', softWrap: true)),
          const DataColumn(label: Text('Avg. Rent', softWrap: true)),
        ];
      case ReportType.maintenance:
        return [
          const DataColumn(label: Text('Date', softWrap: true)),
          const DataColumn(label: Text('Property', softWrap: true)),
          const DataColumn(label: Text('Unit', softWrap: true)),
          const DataColumn(label: Text('Issue Type', softWrap: true)),
          const DataColumn(label: Text('Status', softWrap: true)),
          const DataColumn(label: Text('Priority', softWrap: true)),
          const DataColumn(label: Text('Cost', softWrap: true)),
        ];
      case ReportType.tenant:
        return [
          const DataColumn(label: Text('Tenant', softWrap: true)),
          const DataColumn(label: Text('Property', softWrap: true)),
          const DataColumn(label: Text('Unit', softWrap: true)),
          const DataColumn(label: Text('Lease Start', softWrap: true)),
          const DataColumn(label: Text('Lease End', softWrap: true)),
          const DataColumn(label: Text('Rent', softWrap: true)),
          const DataColumn(label: Text('Status', softWrap: true)),
          const DataColumn(label: Text('Days Left', softWrap: true)),
        ];
    }
  }

  // Set column widths based on report type
  Map<int, TableColumnWidth> _getColumnWidths(ReportType reportType) {
    switch (reportType) {
      case ReportType.financial:
        return {
          0: const FlexColumnWidth(1.2), // Date
          1: const FlexColumnWidth(2.0), // Property
          2: const FlexColumnWidth(1.0), // Unit
          3: const FlexColumnWidth(1.5), // Transaction Type
          4: const FlexColumnWidth(1.2), // Amount
          5: const FlexColumnWidth(1.2), // Balance
        };
      case ReportType.occupancy:
        return {
          0: const FlexColumnWidth(2.5), // Property
          1: const FlexColumnWidth(1.2), // Total Units
          2: const FlexColumnWidth(1.2), // Occupied
          3: const FlexColumnWidth(1.2), // Vacant
          4: const FlexColumnWidth(1.5), // Occupancy Rate
          5: const FlexColumnWidth(1.5), // Avg. Rent
        };
      case ReportType.maintenance:
        return {
          0: const FlexColumnWidth(1.2), // Date
          1: const FlexColumnWidth(2.0), // Property
          2: const FlexColumnWidth(1.0), // Unit
          3: const FlexColumnWidth(1.8), // Issue Type
          4: const FlexColumnWidth(1.2), // Status
          5: const FlexColumnWidth(1.0), // Priority
          6: const FlexColumnWidth(1.2), // Cost
        };
      case ReportType.tenant:
        return {
          0: const FlexColumnWidth(2.0), // Tenant
          1: const FlexColumnWidth(2.0), // Property
          2: const FlexColumnWidth(1.0), // Unit
          3: const FlexColumnWidth(1.2), // Lease Start
          4: const FlexColumnWidth(1.2), // Lease End
          5: const FlexColumnWidth(1.2), // Rent
          6: const FlexColumnWidth(1.2), // Status
          7: const FlexColumnWidth(1.0), // Days Left
        };
    }
  }

  // Cell builders for each report type
  List<DataCell> _buildFinancialCells(FinancialReportItem item) => [
    DataCell(Text(item.date)),
    DataCell(Text(item.property)),
    DataCell(Text(item.unit)),
    DataCell(Text(item.transactionType)),
    DataCell(Text(item.formattedAmount)),
    DataCell(Text(item.formattedBalance)),
  ];

  List<DataCell> _buildOccupancyCells(OccupancyReportItem item) => [
    DataCell(Text(item.property)),
    DataCell(Text(item.totalUnits.toString())),
    DataCell(Text(item.occupied.toString())),
    DataCell(Text(item.vacant.toString())),
    DataCell(Text(item.formattedOccupancyRate)),
    DataCell(Text(item.formattedAvgRent)),
  ];

  List<DataCell> _buildMaintenanceCells(MaintenanceReportItem item) => [
    DataCell(Text(item.date)),
    DataCell(Text(item.property)),
    DataCell(Text(item.unit)),
    DataCell(Text(item.issueType)),
    DataCell(Text(item.status)),
    DataCell(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getPriorityColor(item.priority),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          item.priorityLabel,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    ),
    DataCell(Text(item.formattedCost)),
  ];

  List<DataCell> _buildTenantCells(TenantReportItem item) => [
    DataCell(Text(item.tenant)),
    DataCell(Text(item.property)),
    DataCell(Text(item.unit)),
    DataCell(Text(item.leaseStart)),
    DataCell(Text(item.leaseEnd)),
    DataCell(Text(item.formattedRent)),
    DataCell(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getStatusColor(item.status),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          item.statusLabel,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    ),
    DataCell(
      Text(
        item.daysRemaining > 0 ? item.daysRemaining.toString() : 'Expired',
        style: TextStyle(
          color:
              item.daysRemaining <= 30
                  ? Colors.red
                  : item.daysRemaining <= 60
                  ? Colors.orange
                  : Colors.black,
          fontWeight:
              item.daysRemaining <= 30 ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    ),
  ];

  // Search string builders for each report type
  String _buildFinancialSearchString(FinancialReportItem item) =>
      '${item.date} ${item.property} ${item.unit} ${item.transactionType}'
          .toLowerCase();

  String _buildOccupancySearchString(OccupancyReportItem item) =>
      '${item.property}'.toLowerCase();

  String _buildMaintenanceSearchString(MaintenanceReportItem item) =>
      '${item.date} ${item.property} ${item.unit} ${item.issueType} ${item.status} ${item.priorityLabel}'
          .toLowerCase();

  String _buildTenantSearchString(TenantReportItem item) =>
      '${item.tenant} ${item.property} ${item.unit} ${item.leaseStart} ${item.leaseEnd}'
          .toLowerCase();

  // Helper functions for cell styling
  Color _getPriorityColor(MaintenancePriority priority) {
    switch (priority) {
      case MaintenancePriority.high:
        return Colors.red;
      case MaintenancePriority.medium:
        return Colors.orange;
      case MaintenancePriority.low:
        return Colors.blue;
    }
  }

  Color _getStatusColor(TenantStatus status) {
    switch (status) {
      case TenantStatus.active:
        return Colors.green;
      case TenantStatus.latePayment:
        return Colors.red;
      case TenantStatus.endingSoon:
        return Colors.orange;
      case TenantStatus.ended:
        return Colors.grey;
    }
  }
}
