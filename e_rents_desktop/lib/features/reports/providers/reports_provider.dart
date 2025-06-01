import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/reports/financial_report_item.dart';
import 'package:e_rents_desktop/models/reports/tenant_report_item.dart';
import 'package:e_rents_desktop/features/reports/providers/base_report_provider.dart';
import 'package:e_rents_desktop/features/reports/providers/financial_report_provider.dart';
import 'package:e_rents_desktop/features/reports/providers/tenant_report_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:e_rents_desktop/services/export_service.dart';
import 'package:e_rents_desktop/services/report_service.dart';
import 'package:e_rents_desktop/utils/formatters.dart';
import 'package:intl/intl.dart';

/// Report type enum used for switching between report screens
enum ReportType { financial, tenant }

/// Export format enum for different file types
enum ExportFormat { pdf, excel, csv }

/// Main provider class that coordinates all individual report providers
class ReportsProvider extends BaseReportProvider<dynamic> {
  final ReportService _reportService;
  final Map<ReportType, BaseReportProvider<dynamic>?> _providers = {};
  ReportType _currentReportType = ReportType.financial;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  ReportsProvider({required ReportService reportService})
    : _reportService = reportService {
    debugPrint("ReportsProvider: Initializing with lazy loading");
    _providers[_currentReportType] = _createProvider(_currentReportType);
  }

  // Method to update providers after initialization
  void updateProviders(
    FinancialReportProvider financial,
    TenantReportProvider tenant,
  ) {
    _providers[ReportType.financial] =
        financial as BaseReportProvider<dynamic>?;
    _providers[ReportType.tenant] = tenant as BaseReportProvider<dynamic>?;
    notifyListeners();
  }

  // Lazy provider creation
  BaseReportProvider<dynamic> _createProvider(ReportType type) {
    switch (type) {
      case ReportType.financial:
        return FinancialReportProvider(_reportService)
            as BaseReportProvider<dynamic>;
      case ReportType.tenant:
        return TenantReportProvider(_reportService)
            as BaseReportProvider<dynamic>;
    }
  }

  // Getters for individual providers with lazy initialization
  FinancialReportProvider get financialProvider {
    if (_providers[ReportType.financial] == null) {
      _providers[ReportType.financial] = _createProvider(ReportType.financial);
    }
    return _providers[ReportType.financial]! as FinancialReportProvider;
  }

  TenantReportProvider get tenantProvider {
    if (_providers[ReportType.tenant] == null) {
      _providers[ReportType.tenant] = _createProvider(ReportType.tenant);
    }
    return _providers[ReportType.tenant]! as TenantReportProvider;
  }

  // Current provider getters with lazy initialization
  ReportType get currentReportType => _currentReportType;
  BaseReportProvider<dynamic> get currentProvider {
    if (_providers[_currentReportType] == null) {
      _providers[_currentReportType] = _createProvider(_currentReportType);
    }
    return _providers[_currentReportType]!;
  }

  // Report data getters
  List<FinancialReportItem> get financialReportData => financialProvider.items;
  List<TenantReportItem> get tenantReportData => tenantProvider.items;

  // Date range management
  @override
  void setDateRange(DateTime startDate, DateTime endDate) {
    debugPrint(
      "ReportsProvider.setDateRange: Setting range from ${DateFormat('dd/MM/yyyy').format(startDate)} to ${DateFormat('dd/MM/yyyy').format(endDate)}",
    );

    // Update our own date range
    _startDate = startDate;
    _endDate = endDate;

    // Update ALL providers (both initialized and uninitialized ones)
    // Force refresh on the current provider
    final currentProvider = this.currentProvider;
    debugPrint(
      "ReportsProvider.setDateRange: Updating current provider ${_currentReportType}",
    );
    currentProvider.setDateRange(startDate, endDate);

    // Also update other initialized providers so they're ready when switched to
    for (final entry in _providers.entries) {
      final provider = entry.value;
      if (provider != null && entry.key != _currentReportType) {
        debugPrint(
          "ReportsProvider.setDateRange: Updating ${entry.key} provider",
        );
        provider.setDateRange(startDate, endDate);
      }
    }

    // Notify listeners about the date range change
    notifyListeners();
  }

  // Date range getters
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;

  // Report type management
  void setReportType(ReportType type) {
    if (_currentReportType != type) {
      debugPrint(
        "ReportsProvider: Switching from $_currentReportType to $type",
      );
      _currentReportType = type;
      // Initialize the new provider if needed
      if (_providers[type] == null) {
        debugPrint("ReportsProvider: Creating new provider for $type");
        _providers[type] = _createProvider(type);
        // Set the current date range for the new provider
        _providers[type]!.setDateRange(_startDate, _endDate);
      }
      notifyListeners();
    }
  }

  void setReportTypeFromString(String reportName) {
    final reportType = _getReportTypeFromString(reportName);
    if (reportType != null) {
      setReportType(reportType);
    }
  }

  ReportType? _getReportTypeFromString(String reportName) {
    switch (reportName) {
      case 'Financial Report':
        return ReportType.financial;
      case 'Tenant Report':
        return ReportType.tenant;
      default:
        return null;
    }
  }

  // Get report type string for UI
  String getReportTypeString() {
    switch (_currentReportType) {
      case ReportType.financial:
        return 'Financial Report';
      case ReportType.tenant:
        return 'Tenant Report';
    }
  }

  // Data loading
  Future<void> loadCurrentReportData() async {
    debugPrint("ReportsProvider: Loading data for $_currentReportType");
    await currentProvider.execute(() async {
      await currentProvider.fetchItems();
    });
  }

  // Export functionality
  Future<String> exportToPDF() async {
    return exportReport(ExportFormat.pdf);
  }

  Future<String> exportToExcel() async {
    return exportReport(ExportFormat.excel);
  }

  Future<String> exportToCSV() async {
    return exportReport(ExportFormat.csv);
  }

  Future<String> exportReport(ExportFormat format) async {
    final headers = _getCurrentReportHeaders();
    final rows = _getCurrentReportRows();
    final title = getReportTitle();

    switch (format) {
      case ExportFormat.pdf:
        return ExportService.exportToPDF(
          title: title,
          headers: headers,
          rows: rows,
        );
      case ExportFormat.excel:
        return ExportService.exportToExcel(
          title: title,
          headers: headers,
          rows: rows,
        );
      case ExportFormat.csv:
        return ExportService.exportToCSV(
          title: title,
          headers: headers,
          rows: rows,
        );
    }
  }

  List<String> _getCurrentReportHeaders() {
    switch (_currentReportType) {
      case ReportType.financial:
        return [
          'Date From',
          'Date To',
          'Property',
          'Total Rent',
          'Maintenance Costs',
          'Total',
        ];
      case ReportType.tenant:
        return [
          'Tenant',
          'Property',
          'Lease Start',
          'Lease End',
          'Cost of Rent',
          'Total Paid Rent',
        ];
    }
  }

  List<List<String>> _getCurrentReportRows() {
    switch (_currentReportType) {
      case ReportType.financial:
        return financialReportData.map((item) {
          return [
            item.dateFrom,
            item.dateTo,
            item.property,
            kCurrencyFormat.format(item.totalRent),
            kCurrencyFormat.format(item.maintenanceCosts),
            kCurrencyFormat.format(item.total),
          ];
        }).toList();
      case ReportType.tenant:
        return tenantReportData.map((item) {
          return [
            item.tenantName,
            item.propertyName,
            item.dateFrom,
            item.dateTo,
            kCurrencyFormat.format(item.costOfRent),
            kCurrencyFormat.format(item.totalPaidRent),
          ];
        }).toList();
    }
  }

  // BaseReportProvider implementation
  @override
  Future<List<dynamic>> fetchReportData() async {
    await loadCurrentReportData();
    return currentProvider.items;
  }

  @override
  String getReportName() => currentProvider.getReportName();

  // BaseProvider implementation
  @override
  dynamic fromJson(Map<String, dynamic> json) {
    // This is a no-op since we delegate to individual providers
    return null;
  }

  @override
  Map<String, dynamic> toJson(dynamic item) {
    // This is a no-op since we delegate to individual providers
    return {};
  }

  @override
  String get endpoint => 'reports';

  @override
  List<dynamic> getMockItems() {
    // This is a no-op since we delegate to individual providers
    return [];
  }

  String getReportTitle() {
    switch (_currentReportType) {
      case ReportType.financial:
        return financialProvider.getReportTitle();
      case ReportType.tenant:
        return tenantProvider.getReportTitle();
    }
  }
}
