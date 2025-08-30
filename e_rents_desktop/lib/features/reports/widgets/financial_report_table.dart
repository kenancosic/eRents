import 'package:flutter/material.dart';
import 'package:e_rents_desktop/features/reports/models/financial_report_models.dart';
import 'package:intl/intl.dart';

class FinancialReportTable extends StatelessWidget {
  final FinancialReportSummary reportSummary;
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;

  const FinancialReportTable({
    super.key,
    required this.reportSummary,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (reportSummary.reports.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assessment_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No financial data found for the selected period.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Cards
        _buildSummaryCards(context),
        const SizedBox(height: 24),

        // Data Table
        _buildDataTableCard(context),
      ],
    );
  }

  Widget _buildSummaryCards(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '', decimalDigits: 2);

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            context,
            'Total Revenue',
            '${currencyFormat.format(reportSummary.totalRevenue)} BAM',
            Icons.monetization_on_outlined,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            context,
            'Total Bookings',
            reportSummary.totalBookings.toString(),
            Icons.book_online_outlined,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            context,
            'Average Booking Value',
            '${currencyFormat.format(reportSummary.averageBookingValue)} BAM',
            Icons.trending_up,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color),
          ),
          title: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          subtitle: Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataTableCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Table Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Financial Report Results',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Text(
                  'Page $currentPage of $totalPages (${reportSummary.totalBookings} total bookings)',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),

          // Table Content
          SizedBox(
            width: double.infinity,
            child: _buildDataTable(context),
          ),

          // Pagination
          if (totalPages > 1) _buildPagination(context),
        ],
      ),
    );
  }

  Widget _buildDataTable(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '', decimalDigits: 2);
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Group reports if they have group information
    final groupedReports = <String, List<FinancialReportResponse>>{};
    for (final report in reportSummary.reports) {
      final groupKey = report.groupKey ?? 'default';
      groupedReports.putIfAbsent(groupKey, () => []).add(report);
    }

    return DataTable(
      columnSpacing: 24,
      horizontalMargin: 16,
      headingRowColor: WidgetStateProperty.resolveWith(
        (states) => Colors.grey[100],
      ),
      headingTextStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      columns: const [
        DataColumn(label: Text('Property Name')),
        DataColumn(label: Text('Tenant Name')),
        DataColumn(label: Text('Start Date')),
        DataColumn(label: Text('End Date')),
        DataColumn(label: Text('Rental Type')),
        DataColumn(label: Text('Total Price'), numeric: true),
      ],
      rows: _buildDataRows(groupedReports, dateFormat, currencyFormat),
    );
  }

  List<DataRow> _buildDataRows(
    Map<String, List<FinancialReportResponse>> groupedReports,
    DateFormat dateFormat,
    NumberFormat currencyFormat,
  ) {
    final rows = <DataRow>[];

    for (final entry in groupedReports.entries) {
      final groupKey = entry.key;
      final reports = entry.value;

      // Add group header if there's grouping
      if (groupKey != 'default' && reports.isNotEmpty) {
        final firstReport = reports.first;
        if (firstReport.groupLabel != null) {
          rows.add(DataRow(
            color: WidgetStateProperty.resolveWith(
              (states) => Colors.blue.withOpacity(0.05),
            ),
            cells: [
              DataCell(
                Text(
                  firstReport.groupLabel!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              DataCell(
                Text(
                  '${firstReport.groupCount} bookings',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              const DataCell(Text('')), // Empty cells for alignment
              const DataCell(Text('')), // Empty cells for alignment
              const DataCell(Text('')), // Empty cells for alignment
              DataCell(
                Text(
                  '${currencyFormat.format(firstReport.groupTotal ?? 0)} BAM',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ));
        }
      }

      // Add individual report rows
      for (final report in reports) {
        rows.add(DataRow(
          cells: [
            DataCell(Text(report.propertyName)),
            DataCell(Text(report.tenantName)),
            DataCell(Text(dateFormat.format(report.startDate))),
            DataCell(
              Text(report.endDate != null
                  ? dateFormat.format(report.endDate!)
                  : 'Ongoing'),
            ),
            DataCell(Text(report.rentalType.displayName)),
            DataCell(
              Text(
                '${currencyFormat.format(report.totalPrice)} ${report.currency}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ));
      }
    }

    return rows;
  }

  Widget _buildPagination(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous Page',
          ),
          const SizedBox(width: 16),
          _buildPageNumbers(context),
          const SizedBox(width: 16),
          IconButton(
            onPressed:
                currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next Page',
          ),
        ],
      ),
    );
  }

  Widget _buildPageNumbers(BuildContext context) {
    // Determine the range of page numbers to display
    const int maxPagesToShow = 5;
    int startPage;
    int endPage;

    if (totalPages <= maxPagesToShow) {
      startPage = 1;
      endPage = totalPages;
    } else {
      startPage = (currentPage - (maxPagesToShow ~/ 2)).clamp(1, totalPages - maxPagesToShow + 1);
      endPage = startPage + maxPagesToShow - 1;
    }

    final pageNumbers = List.generate(endPage - startPage + 1, (index) => startPage + index);

    return Row(
      children: [
        if (startPage > 1)
          ...[
            _buildPageButton(context, 1),
            if (startPage > 2) const Text('...'),
          ],
        ...pageNumbers.map((page) => _buildPageButton(context, page)),
        if (endPage < totalPages)
          ...[
            if (endPage < totalPages - 1) const Text('...'),
            _buildPageButton(context, totalPages),
          ],
      ],
    );
  }

  Widget _buildPageButton(BuildContext context, int pageNumber) {
    final isCurrent = pageNumber == currentPage;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: isCurrent
          ? Chip(
              label: Text(pageNumber.toString()),
              backgroundColor: Theme.of(context).primaryColor,
              labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            )
          : TextButton(
              onPressed: () => onPageChanged(pageNumber),
              child: Text(pageNumber.toString()),
            ),
    );
  }
}
