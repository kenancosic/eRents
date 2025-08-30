import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/base/api_service_extensions.dart';
import 'package:e_rents_desktop/features/reports/models/financial_report_models.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

enum ReportType { financial } // Only financial reports for desktop

class ReportsProvider extends BaseProvider {
  ReportsProvider(super.api);

  // ─── State ─────────────────────────────────────────────────────────
  ReportType _currentReportType = ReportType.financial;
  ReportType get currentReportType => _currentReportType;

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime get startDate => _startDate;

  DateTime _endDate = DateTime.now();
  DateTime get endDate => _endDate;

  // Financial report specific state
  FinancialReportSummary? _financialReportSummary;
  FinancialReportSummary? get financialReportSummary => _financialReportSummary;

  // Report configuration
  FinancialReportGroupBy _groupBy = FinancialReportGroupBy.none;
  FinancialReportSortBy _sortBy = FinancialReportSortBy.startDate;
  bool _sortDescending = true;
  int? _selectedPropertyId;
  RentalType? _selectedRentalType;
  int _currentPage = 1;
  final int _pageSize = 50;

  // Getters for current configuration
  FinancialReportGroupBy get groupBy => _groupBy;
  FinancialReportSortBy get sortBy => _sortBy;
  bool get sortDescending => _sortDescending;
  int? get selectedPropertyId => _selectedPropertyId;
  RentalType? get selectedRentalType => _selectedRentalType;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;

  // Legacy compatibility
  List<Map<String, dynamic>> get financialReports {
    if (_financialReportSummary == null) return [];
    return _financialReportSummary!.reports.map((report) => {
      'bookingId': report.bookingId,
      'propertyName': report.propertyName,
      'tenantName': report.tenantName,
      'startDate': report.startDate.toIso8601String(),
      'endDate': report.endDate?.toIso8601String(),
      'rentalType': report.rentalType.displayName,
      'totalPrice': report.totalPrice,
      'currency': report.currency,
    }).toList();
  }

  // ─── Public API ─────────────────────────────────────────────────────────

  Future<void> setReportType(ReportType type) async {
    if (_currentReportType == type) return;
    _currentReportType = type;
    notifyListeners();
    if (_financialReportSummary == null) {
      await fetchCurrentReports();
    }
  }

  Future<void> setDateRange(DateTime startDate, DateTime endDate) async {
    if (_startDate == startDate && _endDate == endDate) return;
    _startDate = startDate;
    _endDate = endDate;
    await fetchCurrentReports(forceRefresh: true);
  }

  Future<void> setGroupBy(FinancialReportGroupBy groupBy) async {
    if (_groupBy == groupBy) return;
    _groupBy = groupBy;
    await fetchCurrentReports(forceRefresh: true);
  }

  Future<void> setSorting(FinancialReportSortBy sortBy, bool descending) async {
    if (_sortBy == sortBy && _sortDescending == descending) return;
    _sortBy = sortBy;
    _sortDescending = descending;
    await fetchCurrentReports(forceRefresh: true);
  }

  Future<void> setPropertyFilter(int? propertyId) async {
    if (_selectedPropertyId == propertyId) return;
    _selectedPropertyId = propertyId;
    _currentPage = 1; // Reset to first page
    await fetchCurrentReports(forceRefresh: true);
  }

  Future<void> setRentalTypeFilter(RentalType? rentalType) async {
    if (_selectedRentalType == rentalType) return;
    _selectedRentalType = rentalType;
    _currentPage = 1; // Reset to first page
    await fetchCurrentReports(forceRefresh: true);
  }

  Future<void> setPage(int page) async {
    if (_currentPage == page) return;
    _currentPage = page;
    await fetchCurrentReports(forceRefresh: true);
  }

  Future<void> fetchCurrentReports({bool forceRefresh = false}) async {
    final request = FinancialReportRequest(
      startDate: _startDate,
      endDate: _endDate,
      groupBy: _groupBy,
      sortBy: _sortBy,
      sortDescending: _sortDescending,
      propertyId: _selectedPropertyId,
      rentalType: _selectedRentalType,
      page: _currentPage,
      pageSize: _pageSize,
    );

    await executeWithState<FinancialReportSummary>(() async {
      final queryParams = request.toQueryParameters();
      final queryString = queryParams.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
          .join('&');
      final endpoint = 'financialreports?$queryString';
      
      final result = await api.getAndDecode<FinancialReportSummary>(
        endpoint,
        FinancialReportSummary.fromJson,
        authenticated: true,
      );
      _financialReportSummary = result;
      return result;
    });
  }

  Future<void> exportToPdf() async {
    if (isLoading) return;

    await executeWithState<void>(() async {
      // First, fetch all data without pagination for complete report
      final allDataRequest = FinancialReportRequest(
        startDate: _startDate,
        endDate: _endDate,
        groupBy: _groupBy,
        sortBy: _sortBy,
        sortDescending: _sortDescending,
        propertyId: _selectedPropertyId,
        rentalType: _selectedRentalType,
        page: 1,
        pageSize: 10000, // Get all records for PDF export
      );

      final queryParams = allDataRequest.toQueryParameters();
      final queryString = queryParams.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
          .join('&');
      final endpoint = 'financialreports?$queryString';
      
      final allDataSummary = await api.getAndDecode<FinancialReportSummary>(
        endpoint,
        FinancialReportSummary.fromJson,
        authenticated: true,
      );

      // Generate PDF using frontend
      final pdf = await _generatePdfReport(allDataSummary);
      
      // Save PDF to file and open it
      final bytes = await pdf.save();
      
      // Get directory based on platform
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/financial_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(bytes);
      
      // Open the PDF file
      await OpenFile.open(file.path);
    });
  }

  Future<pw.Document> _generatePdfReport(FinancialReportSummary reportData) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    // Add pages to PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Text(
                'Financial Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Report period
            pw.Text(
              'Period: ${dateFormat.format(_startDate)} - ${dateFormat.format(_endDate)}',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 20),
            
            // Summary section
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Summary',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total Revenue:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('${reportData.totalRevenue.toStringAsFixed(2)} BAM'),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total Bookings:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('${reportData.totalBookings}'),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Average Booking Value:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('${reportData.averageBookingValue.toStringAsFixed(2)} BAM'),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 30),
            
            // Data table
            if (reportData.reports.isNotEmpty) ...[
              pw.Text(
                'Booking Details',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2), // Property
                  1: const pw.FlexColumnWidth(2), // Tenant
                  2: const pw.FlexColumnWidth(1.5), // Start Date
                  3: const pw.FlexColumnWidth(1.5), // End Date
                  4: const pw.FlexColumnWidth(1.5), // Rental Type
                  5: const pw.FlexColumnWidth(1.5), // Price
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _buildTableCell('Property', isHeader: true),
                      _buildTableCell('Tenant', isHeader: true),
                      _buildTableCell('Start Date', isHeader: true),
                      _buildTableCell('End Date', isHeader: true),
                      _buildTableCell('Type', isHeader: true),
                      _buildTableCell('Price (BAM)', isHeader: true),
                    ],
                  ),
                  // Data rows
                  ...reportData.reports.map((report) => pw.TableRow(
                    children: [
                      _buildTableCell(report.propertyName),
                      _buildTableCell(report.tenantName),
                      _buildTableCell(dateFormat.format(report.startDate)),
                      _buildTableCell(report.endDate != null 
                          ? dateFormat.format(report.endDate!) 
                          : 'Ongoing'),
                      _buildTableCell(report.rentalType.displayName),
                      _buildTableCell('${report.totalPrice.toStringAsFixed(2)}'),
                    ],
                  )),
                ],
              ),
            ],
            
            // Group totals if applicable
            if (reportData.groupTotals.isNotEmpty) ...[
              pw.SizedBox(height: 30),
              pw.Text(
                'Group Totals',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              ...reportData.groupTotals.entries.map((entry) => 
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(entry.key, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('${entry.value.toStringAsFixed(2)} BAM'),
                  ],
                ),
              ),
            ],
          ];
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 1.0 * PdfPageFormat.cm),
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            ),
          );
        },
      ),
    );
    
    return pdf;
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  Future<void> clearFilters() async {
    _startDate = DateTime.now().subtract(const Duration(days: 30));
    _endDate = DateTime.now();
    _groupBy = FinancialReportGroupBy.none;
    _sortBy = FinancialReportSortBy.startDate;
    _sortDescending = true;
    _selectedPropertyId = null;
    _selectedRentalType = null;
    _currentPage = 1;
    await fetchCurrentReports(forceRefresh: true);
  }

  // ─── Helpers & Getters ────────────────────────────────────────

  static final DateFormat _displayDateFormat = DateFormat('dd/MM/yyyy');
  String get formattedStartDate => _displayDateFormat.format(_startDate);
  String get formattedEndDate => _displayDateFormat.format(_endDate);

  String get reportTitle {
    return 'Financial Report ($formattedStartDate - $formattedEndDate)';
  }

  bool get hasData => _financialReportSummary?.reports.isNotEmpty ?? false;
  bool get isExporting => isLoading;

  // Summary statistics
  double get totalRevenue => _financialReportSummary?.totalRevenue ?? 0.0;
  int get totalBookings => _financialReportSummary?.totalBookings ?? 0;
  double get averageBookingValue => _financialReportSummary?.averageBookingValue ?? 0.0;
  Map<String, double> get groupTotals => _financialReportSummary?.groupTotals ?? {};

  // Pagination
  int get totalPages => _financialReportSummary?.totalPages ?? 1;
  bool get hasNextPage => _currentPage < totalPages;
  bool get hasPreviousPage => _currentPage > 1;

  List<dynamic> get currentReports {
    switch (_currentReportType) {
      case ReportType.financial:
        return _financialReportSummary?.reports ?? [];
    }
  }
}
