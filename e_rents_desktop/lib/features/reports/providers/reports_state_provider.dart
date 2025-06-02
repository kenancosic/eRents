import 'package:flutter/foundation.dart';
import 'package:e_rents_desktop/base/base.dart';
import 'package:e_rents_desktop/models/reports/financial_report_item.dart';
import 'package:e_rents_desktop/models/reports/tenant_report_item.dart';
import 'package:e_rents_desktop/services/export_service.dart';
import 'package:intl/intl.dart';

/// Report type enum used for switching between report screens
enum ReportType { financial, tenant }

/// Provider for managing reports state
/// Handles financial reports, tenant reports, and export functionality
class ReportsStateProvider extends StateProvider<List<dynamic>?> {
  final ReportsRepository _repository;

  // Report type state
  ReportType _currentReportType = ReportType.financial;

  // Reports data
  List<FinancialReportItem>? _financialReportData;
  List<TenantReportItem>? _tenantReportData;

  // Date range state
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  // Loading state
  bool _isLoading = false;
  AppError? _error;

  ReportsStateProvider(this._repository) : super(null);

  // Getters
  ReportType get currentReportType => _currentReportType;
  List<FinancialReportItem>? get financialReportData => _financialReportData;
  List<TenantReportItem>? get tenantReportData => _tenantReportData;
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  bool get isLoading => _isLoading;
  AppError? get error => _error;

  // Date formatting
  static final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
  String get formattedStartDate => dateFormat.format(_startDate);
  String get formattedEndDate => dateFormat.format(_endDate);

  // Current report data based on selected type
  List<dynamic>? get currentReportData {
    switch (_currentReportType) {
      case ReportType.financial:
        return _financialReportData;
      case ReportType.tenant:
        return _tenantReportData;
    }
  }

  // Report title with date range
  String get reportTitle {
    final typeName =
        _currentReportType == ReportType.financial
            ? 'Financial Report'
            : 'Tenant Report';
    return '$typeName ($formattedStartDate - $formattedEndDate)';
  }

  /// Set report type and load data if needed
  Future<void> setReportType(ReportType type) async {
    if (_currentReportType != type) {
      debugPrint(
        'ReportsStateProvider: Switching from $_currentReportType to $type',
      );
      _currentReportType = type;
      notifyListeners();

      // Update state to current report data
      updateState(currentReportData);

      // Load data if not already loaded
      if (currentReportData == null) {
        await loadCurrentReportData();
      }
    }
  }

  /// Set date range and refresh data
  Future<void> setDateRange(DateTime startDate, DateTime endDate) async {
    debugPrint(
      'ReportsStateProvider: Date range changed from $formattedStartDate-$formattedEndDate to ${dateFormat.format(startDate)}-${dateFormat.format(endDate)}',
    );

    _startDate = startDate;
    _endDate = endDate;

    // Force refresh data for the new date range
    await loadCurrentReportData(forceRefresh: true);
  }

  /// Load data for the current report type
  Future<void> loadCurrentReportData({bool forceRefresh = false}) async {
    switch (_currentReportType) {
      case ReportType.financial:
        await loadFinancialReport(forceRefresh: forceRefresh);
        break;
      case ReportType.tenant:
        await loadTenantReport(forceRefresh: forceRefresh);
        break;
    }
  }

  /// Load financial report data
  Future<void> loadFinancialReport({bool forceRefresh = false}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint(
        'ReportsStateProvider: Loading financial report for range: $formattedStartDate to $formattedEndDate',
      );

      _financialReportData = await _repository.getFinancialReport(
        startDate: _startDate,
        endDate: _endDate,
        forceRefresh: forceRefresh,
      );

      // Update state if this is the current report type
      if (_currentReportType == ReportType.financial) {
        updateState(_financialReportData);
      }

      debugPrint(
        'ReportsStateProvider: Financial report loaded successfully with ${_financialReportData?.length ?? 0} items',
      );
    } catch (e, stackTrace) {
      _error = AppError.fromException(e, stackTrace);
      debugPrint('ReportsStateProvider: Error loading financial report: $e');

      // Clear state on error
      if (_currentReportType == ReportType.financial) {
        updateState(null);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load tenant report data
  Future<void> loadTenantReport({bool forceRefresh = false}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint(
        'ReportsStateProvider: Loading tenant report for range: $formattedStartDate to $formattedEndDate',
      );

      _tenantReportData = await _repository.getTenantReport(
        startDate: _startDate,
        endDate: _endDate,
        forceRefresh: forceRefresh,
      );

      // Update state if this is the current report type
      if (_currentReportType == ReportType.tenant) {
        updateState(_tenantReportData);
      }

      debugPrint(
        'ReportsStateProvider: Tenant report loaded successfully with ${_tenantReportData?.length ?? 0} items',
      );
    } catch (e, stackTrace) {
      _error = AppError.fromException(e, stackTrace);
      debugPrint('ReportsStateProvider: Error loading tenant report: $e');

      // Clear state on error
      if (_currentReportType == ReportType.tenant) {
        updateState(null);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Export current report to PDF
  Future<String?> exportToPDF() async {
    return await _exportReport('pdf');
  }

  /// Export current report to Excel
  Future<String?> exportToExcel() async {
    return await _exportReport('excel');
  }

  /// Export current report to CSV
  Future<String?> exportToCSV() async {
    return await _exportReport('csv');
  }

  /// Export current report data to specified format
  Future<String?> _exportReport(String format) async {
    try {
      final data = currentReportData;
      if (data == null || data.isEmpty) {
        throw Exception('No data available to export');
      }

      Map<String, dynamic> exportData;

      switch (_currentReportType) {
        case ReportType.financial:
          exportData = _repository.getFinancialReportExportData(
            data.cast<FinancialReportItem>(),
            _startDate,
            _endDate,
          );
          break;
        case ReportType.tenant:
          exportData = _repository.getTenantReportExportData(
            data.cast<TenantReportItem>(),
            _startDate,
            _endDate,
          );
          break;
      }

      final title = exportData['title'] as String;
      final headers = exportData['headers'] as List<String>;
      final rows = exportData['rows'] as List<List<String>>;

      String filePath;
      switch (format.toLowerCase()) {
        case 'pdf':
          filePath = await ExportService.exportToPDF(
            title: title,
            headers: headers,
            rows: rows,
          );
          break;
        case 'excel':
          filePath = await ExportService.exportToExcel(
            title: title,
            headers: headers,
            rows: rows,
          );
          break;
        case 'csv':
          filePath = await ExportService.exportToCSV(
            title: title,
            headers: headers,
            rows: rows,
          );
          break;
        default:
          throw Exception('Unsupported export format: $format');
      }

      debugPrint(
        'ReportsStateProvider: Report exported successfully to $filePath',
      );
      return filePath;
    } catch (e, stackTrace) {
      debugPrint('ReportsStateProvider: Error exporting report: $e');
      _error = AppError.fromException(e, stackTrace);
      notifyListeners();
      return null;
    }
  }

  /// Refresh all data
  Future<void> refreshAllData() async {
    await Future.wait([
      loadFinancialReport(forceRefresh: true),
      loadTenantReport(forceRefresh: true),
    ]);
  }

  /// Clear cached data
  Future<void> clearCache() async {
    await _repository.clearCache();
    debugPrint('ReportsStateProvider: Cache cleared');
  }

  @override
  String get debugName => 'ReportsState';
}
