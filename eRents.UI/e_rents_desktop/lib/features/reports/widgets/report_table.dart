import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/widgets/custom_table_widget.dart';
import 'package:e_rents_desktop/features/reports/providers/reports_provider.dart';
import 'package:e_rents_desktop/models/reports/reports.dart';

class ReportTable extends StatelessWidget {
  const ReportTable({super.key});

  @override
  Widget build(BuildContext context) {
    final reportsProvider = Provider.of<ReportsProvider>(context);
    final reportType = reportsProvider.currentReportType;

    // Show loading indicator if data is loading
    if (reportsProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Get the appropriate report data and columns based on type
    final columns = _getColumns(reportType);
    final columnWidths = _getColumnWidths(reportType);

    // Return the appropriate table based on report type
    switch (reportType) {
      case ReportType.financial:
        return _buildFinancialTable(
          context,
          reportsProvider,
          columns,
          columnWidths,
        );
      case ReportType.occupancy:
        return _buildOccupancyTable(
          context,
          reportsProvider,
          columns,
          columnWidths,
        );
      case ReportType.maintenance:
        return _buildMaintenanceTable(
          context,
          reportsProvider,
          columns,
          columnWidths,
        );
      case ReportType.tenant:
        return _buildTenantTable(
          context,
          reportsProvider,
          columns,
          columnWidths,
        );
    }
  }

  // Generate columns based on report type
  List<DataColumn> _getColumns(ReportType reportType) {
    switch (reportType) {
      case ReportType.financial:
        return [
          const DataColumn(label: Text('Date')),
          const DataColumn(label: Text('Property')),
          const DataColumn(label: Text('Unit')),
          const DataColumn(label: Text('Transaction Type')),
          const DataColumn(label: Text('Amount')),
          const DataColumn(label: Text('Balance')),
        ];
      case ReportType.occupancy:
        return [
          const DataColumn(label: Text('Property')),
          const DataColumn(label: Text('Total Units')),
          const DataColumn(label: Text('Occupied')),
          const DataColumn(label: Text('Vacant')),
          const DataColumn(label: Text('Occupancy Rate')),
          const DataColumn(label: Text('Avg. Rent')),
        ];
      case ReportType.maintenance:
        return [
          const DataColumn(label: Text('Date')),
          const DataColumn(label: Text('Property')),
          const DataColumn(label: Text('Unit')),
          const DataColumn(label: Text('Issue Type')),
          const DataColumn(label: Text('Status')),
          const DataColumn(label: Text('Priority')),
          const DataColumn(label: Text('Cost')),
        ];
      case ReportType.tenant:
        return [
          const DataColumn(label: Text('Tenant')),
          const DataColumn(label: Text('Property')),
          const DataColumn(label: Text('Unit')),
          const DataColumn(label: Text('Lease Start')),
          const DataColumn(label: Text('Lease End')),
          const DataColumn(label: Text('Rent')),
          const DataColumn(label: Text('Status')),
        ];
    }
  }

  // Set column widths based on report type
  Map<int, TableColumnWidth> _getColumnWidths(ReportType reportType) {
    switch (reportType) {
      case ReportType.financial:
        return {
          0: const FlexColumnWidth(1.0), // Date
          1: const FlexColumnWidth(1.2), // Property
          2: const FlexColumnWidth(0.8), // Unit
          3: const FlexColumnWidth(1.2), // Transaction Type
          4: const FlexColumnWidth(0.8), // Amount
          5: const FlexColumnWidth(0.8), // Balance
        };
      case ReportType.occupancy:
        return {
          0: const FlexColumnWidth(1.5), // Property
          1: const FlexColumnWidth(1.0), // Total Units
          2: const FlexColumnWidth(1.0), // Occupied
          3: const FlexColumnWidth(1.0), // Vacant
          4: const FlexColumnWidth(1.2), // Occupancy Rate
          5: const FlexColumnWidth(1.0), // Avg. Rent
        };
      case ReportType.maintenance:
        return {
          0: const FlexColumnWidth(1.0), // Date
          1: const FlexColumnWidth(1.2), // Property
          2: const FlexColumnWidth(0.8), // Unit
          3: const FlexColumnWidth(1.2), // Issue Type
          4: const FlexColumnWidth(1.0), // Status
          5: const FlexColumnWidth(0.8), // Priority
          6: const FlexColumnWidth(0.8), // Cost
        };
      case ReportType.tenant:
        return {
          0: const FlexColumnWidth(1.2), // Tenant
          1: const FlexColumnWidth(1.2), // Property
          2: const FlexColumnWidth(0.8), // Unit
          3: const FlexColumnWidth(1.0), // Lease Start
          4: const FlexColumnWidth(1.0), // Lease End
          5: const FlexColumnWidth(0.8), // Rent
          6: const FlexColumnWidth(1.0), // Status
        };
    }
  }

  // Build Financial Report Table
  Widget _buildFinancialTable(
    BuildContext context,
    ReportsProvider provider,
    List<DataColumn> columns,
    Map<int, TableColumnWidth> columnWidths,
  ) {
    final data = provider.financialReportData;

    return CustomTableWidget<FinancialReportItem>(
      title: provider.getReportTypeString(),
      data: data,
      columns: columns,
      columnWidths: columnWidths,
      cellsBuilder:
          (item) => [
            DataCell(Text(item.date)),
            DataCell(Text(item.property)),
            DataCell(Text(item.unit)),
            DataCell(Text(item.transactionType)),
            DataCell(Text(item.formattedAmount)),
            DataCell(Text(item.formattedBalance)),
          ],
      searchStringBuilder:
          (item) =>
              '${item.date} ${item.property} ${item.unit} ${item.transactionType}'
                  .toLowerCase(),
      emptyStateWidget: const Center(
        child: Text('No financial data available for the selected period'),
      ),
    );
  }

  // Build Occupancy Report Table
  Widget _buildOccupancyTable(
    BuildContext context,
    ReportsProvider provider,
    List<DataColumn> columns,
    Map<int, TableColumnWidth> columnWidths,
  ) {
    final data = provider.occupancyReportData;

    return CustomTableWidget<OccupancyReportItem>(
      title: provider.getReportTypeString(),
      data: data,
      columns: columns,
      columnWidths: columnWidths,
      cellsBuilder:
          (item) => [
            DataCell(Text(item.property)),
            DataCell(Text(item.totalUnits.toString())),
            DataCell(Text(item.occupied.toString())),
            DataCell(Text(item.vacant.toString())),
            DataCell(Text(item.formattedOccupancyRate)),
            DataCell(Text(item.formattedAvgRent)),
          ],
      searchStringBuilder: (item) => item.property.toLowerCase(),
      emptyStateWidget: const Center(
        child: Text('No occupancy data available'),
      ),
    );
  }

  // Build Maintenance Report Table
  Widget _buildMaintenanceTable(
    BuildContext context,
    ReportsProvider provider,
    List<DataColumn> columns,
    Map<int, TableColumnWidth> columnWidths,
  ) {
    final data = provider.maintenanceReportData;

    return CustomTableWidget<MaintenanceReportItem>(
      title: provider.getReportTypeString(),
      data: data,
      columns: columns,
      columnWidths: columnWidths,
      cellsBuilder:
          (item) => [
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
          ],
      searchStringBuilder:
          (item) =>
              '${item.date} ${item.property} ${item.unit} ${item.issueType} ${item.status} ${item.priorityLabel}'
                  .toLowerCase(),
      emptyStateWidget: const Center(
        child: Text('No maintenance data available for the selected period'),
      ),
    );
  }

  // Build Tenant Report Table
  Widget _buildTenantTable(
    BuildContext context,
    ReportsProvider provider,
    List<DataColumn> columns,
    Map<int, TableColumnWidth> columnWidths,
  ) {
    final data = provider.tenantReportData;

    return CustomTableWidget<TenantReportItem>(
      title: provider.getReportTypeString(),
      data: data,
      columns: columns,
      columnWidths: columnWidths,
      cellsBuilder:
          (item) => [
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
          ],
      searchStringBuilder:
          (item) =>
              '${item.tenant} ${item.property} ${item.unit} ${item.leaseStart} ${item.leaseEnd}'
                  .toLowerCase(),
      emptyStateWidget: const Center(child: Text('No tenant data available')),
    );
  }

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
