import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/features/reports/providers/reports_provider.dart';
import 'package:e_rents_desktop/features/reports/providers/financial_report_provider.dart';
import 'package:e_rents_desktop/features/reports/providers/tenant_report_provider.dart';
import 'package:e_rents_desktop/features/reports/widgets/financial_report_table.dart';
import 'package:e_rents_desktop/features/reports/widgets/tenant_report_table.dart';
import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:flutter/foundation.dart';

class ReportTable extends StatelessWidget {
  const ReportTable({super.key});

  // Store a map to track refresh attempts by provider type
  static final Map<String, bool> _refreshAttempted = {};

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportsProvider>(
      builder: (context, reportsProvider, child) {
        final reportType = reportsProvider.currentReportType;
        debugPrint('ReportTable.build: Current report type: $reportType');

        // Return the appropriate table based on report type
        switch (reportType) {
          case ReportType.financial:
            // Use the provider managed by ReportsProvider
            final provider = reportsProvider.financialProvider;
            return ListenableBuilder(
              listenable: provider,
              builder: (context, child) {
                debugPrint(
                  'ReportTable: Financial provider state=${provider.state}, itemCount=${provider.items.length}',
                );
                return _buildTableWithErrorHandling(
                  context: context,
                  provider: provider,
                  reportType: reportType,
                  child: const FinancialReportTable(),
                );
              },
            );
          case ReportType.tenant:
            // Use the provider managed by ReportsProvider
            final provider = reportsProvider.tenantProvider;
            return ListenableBuilder(
              listenable: provider,
              builder: (context, child) {
                debugPrint(
                  'ReportTable: Tenant provider state=${provider.state}, itemCount=${provider.items.length}',
                );
                return _buildTableWithErrorHandling(
                  context: context,
                  provider: provider,
                  reportType: reportType,
                  child: const TenantReportTable(),
                );
              },
            );
        }
      },
    );
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
      debugPrint('ReportTable: Showing error state for $reportType');
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
      debugPrint('ReportTable: Showing loading state for $reportType');
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
      debugPrint('ReportTable: Showing empty state for $reportType');
      switch (reportType) {
        case ReportType.financial:
          return const Center(
            child: Text('No financial data available for the selected period'),
          );
        case ReportType.tenant:
          return const Center(child: Text('No tenant data available'));
      }
    }

    // Show the actual table with data
    debugPrint(
      'ReportTable: Showing table with ${provider.items.length} items for $reportType',
    );
    return child;
  }
}
