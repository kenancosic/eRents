import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/base/api_service_extensions.dart';
import 'package:e_rents_desktop/models/reports/financial_report_item.dart';
import 'package:e_rents_desktop/models/reports/tenant_report_item.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

enum ReportType { financial, tenant }

class ReportsProviderRefactored extends BaseProvider {
  ReportsProviderRefactored(super.api);

  // ─── State ──────────────────────────────────────────────────────────────
  ReportType _currentReportType = ReportType.financial;
  ReportType get currentReportType => _currentReportType;

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime get startDate => _startDate;

  DateTime _endDate = DateTime.now();
  DateTime get endDate => _endDate;

  List<FinancialReportItem> _financialReports = [];
  List<FinancialReportItem> get financialReports => _financialReports;

  List<TenantReportItem> _tenantReports = [];
  List<TenantReportItem> get tenantReports => _tenantReports;

  // ─── Public API ─────────────────────────────────────────────────────────

  Future<void> setReportType(ReportType type) async {
    if (_currentReportType == type) return;
    _currentReportType = type;
    notifyListeners();
    if (currentReports.isEmpty) {
      await fetchCurrentReports();
    }
  }

  Future<void> setDateRange(DateTime startDate, DateTime endDate) async {
    if (_startDate == startDate && _endDate == endDate) return;
    _startDate = startDate;
    _endDate = endDate;
    await fetchCurrentReports(forceRefresh: true);
  }

  Future<void> fetchCurrentReports({bool forceRefresh = false}) async {
    final cacheKey = _buildCacheKey(_currentReportType.name, _startDate, _endDate);
    final endpoint = _buildReportEndpoint(_currentReportType.name, _startDate, _endDate);

    await executeWithState(() async {
      if (_currentReportType == ReportType.financial) {
        if (forceRefresh) invalidateCache(cacheKey);
        _financialReports = await getCachedOrExecute<List<FinancialReportItem>>(
          cacheKey,
          () async {
            final json = await api.getAndDecode(endpoint, (data) => data, authenticated: true);
            return (json as List).map((i) => FinancialReportItem.fromJson(i)).toList();
          },
        );
      } else {
        if (forceRefresh) invalidateCache(cacheKey);
        _tenantReports = await getCachedOrExecute<List<TenantReportItem>>(
          cacheKey,
          () async {
            final json = await api.getAndDecode(endpoint, (data) => data, authenticated: true);
            return (json as List).map((i) => TenantReportItem.fromJson(i)).toList();
          },
        );
      }
    });
  }

  Future<String?> exportReport(String format) async {
    String? path;
    await executeWithState(
      () async {
        if (currentReports.isEmpty) {
          throw Exception('No data to export.');
        }
        final exportData = _getExportData(currentReports);
        final title = exportData['title'] as String;
        final headers = exportData['headers'] as List<String>;
        final rows = exportData['rows'] as List<List<dynamic>>;

        final dir = await getApplicationDocumentsDirectory();
        final fileName = '${title.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.$format';
        path = '${dir.path}/$fileName';

        switch (format) {
          case 'pdf': await _createPdf(path!, title, headers, rows); break;
          case 'excel': await _createExcel(path!, title, headers, rows); break;
          case 'csv': await _createCsv(path!, headers, rows); break;
          default: throw Exception('Unsupported format: $format');
        }
      },
    );
    return path;
  }

  // ─── Helpers & Private Methods ────────────────────────────────────────

  String _buildCacheKey(String type, DateTime start, DateTime end) =>
      'report_${type}_${start.toIso8601String()}_${end.toIso8601String()}';

  String _buildReportEndpoint(String type, DateTime start, DateTime end) =>
      'reports/$type?from=${start.toIso8601String()}&to=${end.toIso8601String()}';

  // ... (Export and computed properties remain the same) ...
  List<dynamic> get currentReports {
    switch (_currentReportType) {
      case ReportType.financial: return _financialReports;
      case ReportType.tenant: return _tenantReports;
    }
  }

  static final DateFormat _displayDateFormat = DateFormat('dd/MM/yyyy');
  String get formattedStartDate => _displayDateFormat.format(_startDate);
  String get formattedEndDate => _displayDateFormat.format(_endDate);

  String get reportTitle {
    final typeName = _currentReportType == ReportType.financial ? 'Financial Report' : 'Tenant Report';
    return '$typeName ($formattedStartDate - $formattedEndDate)';
  }

  bool get hasData => currentReports.isNotEmpty;
  bool get isExporting => isLoading;

  Future<void> _createPdf(String path, String title, List<String> headers, List<List<dynamic>> rows) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        header: (context) => pw.Header(level: 0, child: pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
        build: (context) => [
          pw.Table.fromTextArray(
            headers: headers,
            data: rows.map((row) => row.map((cell) => cell.toString()).toList()).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.center,
            border: pw.TableBorder.all(),
          ),
        ],
      ),
    );
    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    await Printing.layoutPdf(onLayout: (format) => file.readAsBytes());
  }

  Future<void> _createExcel(String path, String title, List<String> headers, List<List<dynamic>> rows) async {
    final excel = Excel.createExcel();
    final sheet = excel[excel.getDefaultSheet()!];
    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());
    for (final row in rows) {
      sheet.appendRow(row.map((cell) => TextCellValue(cell.toString())).toList());
    }
    final fileBytes = excel.save();
    if (fileBytes != null) {
      final file = File(path);
      await file.writeAsBytes(fileBytes);
    }
  }

  Future<void> _createCsv(String path, List<String> headers, List<List<dynamic>> rows) async {
    final items = [headers, ...rows];
    final csvData = const ListToCsvConverter().convert(items);
    final file = File(path);
    await file.writeAsString(csvData);
  }

  Map<String, dynamic> _getExportData(List<dynamic> data) {
    switch (_currentReportType) {
      case ReportType.financial:
        return _getFinancialExportData(data.cast<FinancialReportItem>());
      case ReportType.tenant:
        return _getTenantExportData(data.cast<TenantReportItem>());
    }
  }

  Map<String, dynamic> _getFinancialExportData(List<FinancialReportItem> data) {
    return {
      'title': 'Financial Report ($formattedStartDate - $formattedEndDate)',
      'headers': ['Date From', 'Date To', 'Property', 'Total Rent', 'Maintenance Costs', 'Net Total'],
      'rows': data.map((item) => [item.dateFrom, item.dateTo, item.property, item.totalRent, item.maintenanceCosts, item.total]).toList(),
    };
  }

  Map<String, dynamic> _getTenantExportData(List<TenantReportItem> data) {
    return {
      'title': 'Tenant Report ($formattedStartDate - $formattedEndDate)',
      'headers': ['Tenant Name', 'Property', 'Cost of Rent', 'Total Paid Rent', 'Start Date', 'End Date'],
      'rows': data.map((item) => [item.tenantName, item.propertyName, item.costOfRent, item.totalPaidRent, item.dateFrom, item.dateTo]).toList(),
    };
  }
}
