import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/features/reports/providers/reports_provider.dart';
import 'package:e_rents_desktop/features/reports/widgets/financial_report_filters.dart';
import 'package:e_rents_desktop/features/reports/widgets/financial_report_table.dart';
import 'package:e_rents_desktop/features/auth/providers/auth_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated) {
        final reportsProvider = Provider.of<ReportsProvider>(
          context,
          listen: false,
        );
        reportsProvider.fetchCurrentReports();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ReportsProvider, AuthProvider>(
      builder: (context, reportsProvider, authProvider, _) {
        if (!authProvider.isAuthenticated) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 64),
                SizedBox(height: 16),
                Text('Please log in to view reports'),
              ],
            ),
          );
        }

        return _FinancialReportContent(reportsProvider: reportsProvider);
      },
    );
  }
}

class _FinancialReportContent extends StatelessWidget {
  final ReportsProvider reportsProvider;

  const _FinancialReportContent({required this.reportsProvider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: FinancialReportFilters(
              startDate: reportsProvider.startDate,
              endDate: reportsProvider.endDate,
              groupBy: reportsProvider.groupBy,
              sortBy: reportsProvider.sortBy,
              sortDescending: reportsProvider.sortDescending,
              selectedRentalType: reportsProvider.selectedRentalType,
              isExporting: reportsProvider.isLoading,
              onDateRangeChanged: (start, end) {
                reportsProvider.setDateRange(start, end);
              },
              onGroupByChanged: (groupBy) {
                reportsProvider.setGroupBy(groupBy);
              },
              onSortingChanged: (sortBy, descending) {
                reportsProvider.setSorting(sortBy, descending);
              },
              onRentalTypeChanged: (rentalType) {
                reportsProvider.setRentalTypeFilter(rentalType);
              },
              onClearFilters: () async {
                await reportsProvider.clearFilters();
              },
              onExportToPdf: () async {
                await reportsProvider.exportToPdf();
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (reportsProvider.isLoading) {
      return const SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading financial reports...'),
            ],
          ),
        ),
      );
    }

    if (reportsProvider.error != null) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error: ${reportsProvider.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    reportsProvider.fetchCurrentReports(forceRefresh: true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final reportSummary = reportsProvider.financialReportSummary;
    if (reportSummary == null || reportSummary.reports.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assessment_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('No financial data available for the selected filters.'),
            ],
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: FinancialReportTable(
        reportSummary: reportSummary,
        currentPage: reportsProvider.currentPage,
        totalPages: reportsProvider.totalPages,
        onPageChanged: (page) {
          reportsProvider.setPage(page);
        },
      ),
    );
  }
}
