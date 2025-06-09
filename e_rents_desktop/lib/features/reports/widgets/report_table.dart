import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/features/reports/providers/reports_state_provider.dart';
import 'package:e_rents_desktop/models/reports/financial_report_item.dart';
import 'package:e_rents_desktop/models/reports/tenant_report_item.dart';
import 'package:e_rents_desktop/widgets/table/custom_table.dart';
import 'package:e_rents_desktop/utils/formatters.dart';

class ReportTable extends StatelessWidget {
  const ReportTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportsStateProvider>(
      builder: (context, reportsProvider, child) {
        // Handle loading state
        if (reportsProvider.isLoading) {
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

        // Handle error state
        if (reportsProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error loading data: ${reportsProvider.error?.message ?? "Unknown error"}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  onPressed: () {
                    reportsProvider.loadCurrentReportData(forceRefresh: true);
                  },
                ),
              ],
            ),
          );
        }

        // Handle empty data state
        final currentData = reportsProvider.currentReportData;
        if (currentData == null || currentData.isEmpty) {
          final message =
              reportsProvider.currentReportType == ReportType.financial
                  ? 'No financial data available for the selected period'
                  : 'No tenant data available for the selected period';

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.folder_open, color: Colors.grey, size: 48),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  onPressed: () {
                    reportsProvider.loadCurrentReportData(forceRefresh: true);
                  },
                ),
              ],
            ),
          );
        }

        // Show the appropriate table based on report type
        switch (reportsProvider.currentReportType) {
          case ReportType.financial:
            return _FinancialReportUniversalTable(
              reportItems: reportsProvider.financialReportData!,
              dateRange:
                  '${reportsProvider.formattedStartDate} - ${reportsProvider.formattedEndDate}',
            );
          case ReportType.tenant:
            return _TenantReportUniversalTable(
              reportItems: reportsProvider.tenantReportData!,
              dateRange:
                  '${reportsProvider.formattedStartDate} - ${reportsProvider.formattedEndDate}',
            );
        }
      },
    );
  }
}

class _FinancialReportUniversalTable extends StatelessWidget {
  final List<FinancialReportItem> reportItems;
  final String dateRange;

  const _FinancialReportUniversalTable({
    required this.reportItems,
    required this.dateRange,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTable.create<FinancialReportItem>(
      fetchData: (params) async {
        // Since this is static data (already loaded), we simulate server response
        final searchTerm = params['searchTerm']?.toString().toLowerCase() ?? '';

        // Apply search filter
        var filteredItems = reportItems;
        if (searchTerm.isNotEmpty) {
          filteredItems =
              reportItems.where((item) {
                return item.property.toLowerCase().contains(searchTerm) ||
                    item.dateFrom.toLowerCase().contains(searchTerm) ||
                    item.dateTo.toLowerCase().contains(searchTerm);
              }).toList();
        }

        // Apply sorting
        final sortBy = params['sortBy']?.toString();
        final sortDesc = params['sortDesc'] as bool? ?? false;

        if (sortBy != null) {
          filteredItems.sort((a, b) {
            dynamic aValue, bValue;
            switch (sortBy) {
              case 'dateFrom':
                aValue = a.dateFrom;
                bValue = b.dateFrom;
                break;
              case 'dateTo':
                aValue = a.dateTo;
                bValue = b.dateTo;
                break;
              case 'property':
                aValue = a.property;
                bValue = b.property;
                break;
              case 'totalRent':
                aValue = a.totalRent;
                bValue = b.totalRent;
                break;
              case 'maintenanceCosts':
                aValue = a.maintenanceCosts;
                bValue = b.maintenanceCosts;
                break;
              case 'total':
                aValue = a.total;
                bValue = b.total;
                break;
              default:
                return 0;
            }

            int comparison = Comparable.compare(aValue, bValue);
            return sortDesc ? -comparison : comparison;
          });
        }

        // Apply pagination
        final page = (params['page'] as int? ?? 1) - 1; // Convert to 0-based
        final pageSize = params['pageSize'] as int? ?? 25;
        final startIndex = page * pageSize;
        final endIndex = (startIndex + pageSize).clamp(0, filteredItems.length);

        final pageItems = filteredItems.sublist(
          startIndex.clamp(0, filteredItems.length),
          endIndex,
        );

        return PagedResult<FinancialReportItem>(
          items: pageItems,
          totalCount: filteredItems.length,
          page: page,
          pageSize: pageSize,
          totalPages: (filteredItems.length / pageSize).ceil(),
        );
      },
      columns: [
        CustomTable.column<FinancialReportItem>(
          key: 'dateFrom',
          label: 'Date From',
          cellBuilder: (item) => CustomTable.textCell(item.dateFrom),
          width: const FlexColumnWidth(1),
        ),
        CustomTable.column<FinancialReportItem>(
          key: 'dateTo',
          label: 'Date To',
          cellBuilder: (item) => CustomTable.textCell(item.dateTo),
          width: const FlexColumnWidth(1),
        ),
        CustomTable.column<FinancialReportItem>(
          key: 'property',
          label: 'Property',
          cellBuilder: (item) => CustomTable.textCell(item.property),
          width: const FlexColumnWidth(2),
        ),
        CustomTable.column<FinancialReportItem>(
          key: 'totalRent',
          label: 'Total Rent',
          cellBuilder: (item) => CustomTable.currencyCell(item.totalRent),
          width: const FlexColumnWidth(1),
        ),
        CustomTable.column<FinancialReportItem>(
          key: 'maintenanceCosts',
          label: 'Maintenance Costs',
          cellBuilder:
              (item) => CustomTable.currencyCell(item.maintenanceCosts),
          width: const FlexColumnWidth(1.2),
        ),
        CustomTable.column<FinancialReportItem>(
          key: 'total',
          label: 'Total',
          cellBuilder: (item) => CustomTable.currencyCell(item.total),
          width: const FlexColumnWidth(1),
        ),
      ],
      title: 'Financial Report ($dateRange)',
      searchHint: 'Search properties, dates...',
      emptyStateMessage: 'No financial data available for the selected period',
      defaultPageSize: 25,
    );
  }
}

class _TenantReportUniversalTable extends StatelessWidget {
  final List<TenantReportItem> reportItems;
  final String dateRange;

  const _TenantReportUniversalTable({
    required this.reportItems,
    required this.dateRange,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTable.create<TenantReportItem>(
      fetchData: (params) async {
        // Since this is static data (already loaded), we simulate server response
        final searchTerm = params['searchTerm']?.toString().toLowerCase() ?? '';

        // Apply search filter
        var filteredItems = reportItems;
        if (searchTerm.isNotEmpty) {
          filteredItems =
              reportItems.where((item) {
                return item.tenantName.toLowerCase().contains(searchTerm) ||
                    item.propertyName.toLowerCase().contains(searchTerm) ||
                    item.dateFrom.toLowerCase().contains(searchTerm) ||
                    item.dateTo.toLowerCase().contains(searchTerm);
              }).toList();
        }

        // Apply sorting
        final sortBy = params['sortBy']?.toString();
        final sortDesc = params['sortDesc'] as bool? ?? false;

        if (sortBy != null) {
          filteredItems.sort((a, b) {
            dynamic aValue, bValue;
            switch (sortBy) {
              case 'tenantName':
                aValue = a.tenantName;
                bValue = b.tenantName;
                break;
              case 'propertyName':
                aValue = a.propertyName;
                bValue = b.propertyName;
                break;
              case 'dateFrom':
                aValue = a.dateFrom;
                bValue = b.dateFrom;
                break;
              case 'dateTo':
                aValue = a.dateTo;
                bValue = b.dateTo;
                break;
              case 'costOfRent':
                aValue = a.costOfRent;
                bValue = b.costOfRent;
                break;
              case 'totalPaidRent':
                aValue = a.totalPaidRent;
                bValue = b.totalPaidRent;
                break;
              default:
                return 0;
            }

            int comparison = Comparable.compare(aValue, bValue);
            return sortDesc ? -comparison : comparison;
          });
        }

        // Apply pagination
        final page = (params['page'] as int? ?? 1) - 1; // Convert to 0-based
        final pageSize = params['pageSize'] as int? ?? 25;
        final startIndex = page * pageSize;
        final endIndex = (startIndex + pageSize).clamp(0, filteredItems.length);

        final pageItems = filteredItems.sublist(
          startIndex.clamp(0, filteredItems.length),
          endIndex,
        );

        return PagedResult<TenantReportItem>(
          items: pageItems,
          totalCount: filteredItems.length,
          page: page,
          pageSize: pageSize,
          totalPages: (filteredItems.length / pageSize).ceil(),
        );
      },
      columns: [
        CustomTable.column<TenantReportItem>(
          key: 'tenantName',
          label: 'Tenant',
          cellBuilder: (item) => CustomTable.textCell(item.tenantName),
          width: const FlexColumnWidth(1.5),
        ),
        CustomTable.column<TenantReportItem>(
          key: 'propertyName',
          label: 'Property',
          cellBuilder: (item) => CustomTable.textCell(item.propertyName),
          width: const FlexColumnWidth(2),
        ),
        CustomTable.column<TenantReportItem>(
          key: 'dateFrom',
          label: 'Lease Start',
          cellBuilder: (item) => CustomTable.textCell(item.dateFrom),
          width: const FlexColumnWidth(1),
        ),
        CustomTable.column<TenantReportItem>(
          key: 'dateTo',
          label: 'Lease End',
          cellBuilder: (item) => CustomTable.textCell(item.dateTo),
          width: const FlexColumnWidth(1),
        ),
        CustomTable.column<TenantReportItem>(
          key: 'costOfRent',
          label: 'Cost of Rent',
          cellBuilder: (item) => CustomTable.currencyCell(item.costOfRent),
          width: const FlexColumnWidth(1),
        ),
        CustomTable.column<TenantReportItem>(
          key: 'totalPaidRent',
          label: 'Total Paid Rent',
          cellBuilder: (item) => CustomTable.currencyCell(item.totalPaidRent),
          width: const FlexColumnWidth(1),
        ),
      ],
      title: 'Tenant Report ($dateRange)',
      searchHint: 'Search tenants, properties, dates...',
      emptyStateMessage: 'No tenant data available for the selected period',
      defaultPageSize: 25,
    );
  }
}
