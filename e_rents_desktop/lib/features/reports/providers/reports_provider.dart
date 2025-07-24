import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:e_rents_desktop/models/reports/financial_report_item.dart';
import 'package:e_rents_desktop/models/reports/tenant_report_item.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Report type enum used for switching between report screens
enum ReportType { financial, tenant }

/// Provider for managing reports state following the new provider-only architecture
/// Handles financial reports, tenant reports, and export functionality
class ReportsProvider extends ChangeNotifier {
  final ApiService _api;

  ReportsProvider(this._api);

  // ─── State ──────────────────────────────────────────────────────────────
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

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

  final Map<String, _CacheEntry> _cache = {};
  static const Duration _cacheTtl = Duration(minutes: 10);

  // ─── Computed Properties ────────────────────────────────────────────────

  List<dynamic> get currentReports {
    switch (_currentReportType) {
      case ReportType.financial:
        return _financialReports;
      case ReportType.tenant:
        return _tenantReports;
    }
  }

  static final DateFormat _displayDateFormat = DateFormat('dd/MM/yyyy');
  String get formattedStartDate => _displayDateFormat.format(_startDate);
  String get formattedEndDate => _displayDateFormat.format(_endDate);

  String get reportTitle {
    final typeName = _currentReportType == ReportType.financial
        ? 'Financial Report'
        : 'Tenant Report';
    return '$typeName ($formattedStartDate - $formattedEndDate)';
  }

  bool get hasData => currentReports.isNotEmpty;

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
    switch (_currentReportType) {
      case ReportType.financial:
        await fetchFinancialReports(forceRefresh: forceRefresh);
        break;
      case ReportType.tenant:
        await fetchTenantReports(forceRefresh: forceRefresh);
        break;
    }
  }

  Future<void> fetchFinancialReports({bool forceRefresh = false}) async {
    final cacheKey = _buildCacheKey('financial', _startDate, _endDate);
    if (!forceRefresh && _isCacheValid(cacheKey)) {
      _financialReports = _cache[cacheKey]!.data as List<FinancialReportItem>;
      notifyListeners();
      return;
    }
    await _fetchReports<FinancialReportItem>(
      endpoint: _buildReportEndpoint('financial', _startDate, _endDate),
      parser: (item) => FinancialReportItem.fromJson(item),
      onSuccess: (data) => _financialReports = data,
      cacheKey: cacheKey,
    );
  }

  Future<void> fetchTenantReports({bool forceRefresh = false}) async {
    final cacheKey = _buildCacheKey('tenant', _startDate, _endDate);
    if (!forceRefresh && _isCacheValid(cacheKey)) {
      _tenantReports = _cache[cacheKey]!.data as List<TenantReportItem>;
      notifyListeners();
      return;
    }
    await _fetchReports<TenantReportItem>(
      endpoint: _buildReportEndpoint('tenant', _startDate, _endDate),
      parser: (item) => TenantReportItem.fromJson(item),
      onSuccess: (data) => _tenantReports = data,
      cacheKey: cacheKey,
    );
  }

  Future<void> refreshAllData() async {
    _cache.clear();
    await fetchCurrentReports(forceRefresh: true);
  }

  Future<String?> exportToPDF() => _exportReport('pdf');
  Future<String?> exportToExcel() => _exportReport('excel');
  Future<String?> exportToCSV() => _exportReport('csv');

  void clearCache() {
    _cache.clear();
    notifyListeners();
  }

  // ─── Private Helpers ────────────────────────────────────────────────────

  Future<void> _fetchReports<T>({
    required String endpoint,
    required T Function(Map<String, dynamic>) parser,
    required void Function(List<T>) onSuccess,
    required String cacheKey,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      final response = await _api.get(endpoint);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        final parsedData = data.map((item) => parser(item)).toList();
        onSuccess(parsedData);
        _cacheData(cacheKey, parsedData);
      } else {
        _setError('Failed to load reports.', 'API Error: ${response.statusCode}', StackTrace.current);
      }
    } catch (e, stackTrace) {
      _setError('An unexpected error occurred.', e, stackTrace);
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String userMessage, dynamic error, StackTrace stackTrace) {
    _error = userMessage;
    debugPrint('ReportsProvider Error: $userMessage\n$error\n$stackTrace');
    notifyListeners();
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  String _buildCacheKey(String type, DateTime start, DateTime end) =>
      '$type-${DateFormat('yyyy-MM-dd').format(start)}-${DateFormat('yyyy-MM-dd').format(end)}';

  String _buildReportEndpoint(String type, DateTime start, DateTime end) {
    final formatter = DateFormat('yyyy-MM-dd');
    return '/reports/$type?startDate=${formatter.format(start)}&endDate=${formatter.format(end)}';
  }

  bool _isCacheValid(String key) {
    final entry = _cache[key];
    return entry != null && DateTime.now().difference(entry.timestamp) < _cacheTtl;
  }

  void _cacheData(String key, dynamic data) {
    _cache[key] = _CacheEntry(data: data, timestamp: DateTime.now());
  }

  Future<String?> _exportReport(String format) async {
    if (currentReports.isEmpty) {
      _setError('No data to export.', 'Empty data set', StackTrace.current);
      return null;
    }

    try {
      final exportData = _getExportData(currentReports);
      final title = exportData['title'] as String;
      final headers = exportData['headers'] as List<String>;
      final rows = exportData['rows'] as List<List<dynamic>>;

      final dir = await getApplicationDocumentsDirectory();
      final fileName = '${title.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.$format';
      final path = '${dir.path}/$fileName';

      switch (format) {
        case 'pdf':
          await _createPdf(path, title, headers, rows);
          break;
        case 'excel':
          await _createExcel(path, title, headers, rows);
          break;
        case 'csv':
          await _createCsv(path, headers, rows);
          break;
        default:
          throw Exception('Unsupported format: $format');
      }
      return path;
    } catch (e, stackTrace) {
      _setError('Export failed.', e, stackTrace);
      return null;
    }
  }

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

class _CacheEntry {
  final dynamic data;
  final DateTime timestamp;
  _CacheEntry({required this.data, required this.timestamp});
}
