import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/reports/reports.dart';
import 'package:e_rents_desktop/features/reports/providers/base_report_provider.dart';
import 'package:e_rents_desktop/features/reports/providers/financial_report_provider.dart';
import 'package:e_rents_desktop/features/reports/providers/occupancy_report_provider.dart';
import 'package:e_rents_desktop/features/reports/providers/maintenance_report_provider.dart';
import 'package:e_rents_desktop/features/reports/providers/tenant_report_provider.dart';
import 'package:flutter/foundation.dart';

/// Report type enum used for switching between report screens
enum ReportType { financial, occupancy, maintenance, tenant }

/// Main provider class that coordinates all individual report providers
class ReportsProvider extends ChangeNotifier {
  // Map to store all report providers
  final Map<ReportType, BaseReportProvider> _providers = {};

  // Current active report type
  ReportType _currentReportType = ReportType.financial;
  bool _isLoading = false;

  // Getters for specific providers
  FinancialReportProvider get financialReportProvider =>
      getProvider<FinancialReportProvider>(ReportType.financial);
  OccupancyReportProvider get occupancyReportProvider =>
      getProvider<OccupancyReportProvider>(ReportType.occupancy);
  MaintenanceReportProvider get maintenanceReportProvider =>
      getProvider<MaintenanceReportProvider>(ReportType.maintenance);
  TenantReportProvider get tenantReportProvider =>
      getProvider<TenantReportProvider>(ReportType.tenant);

  // Getter for current report type
  ReportType get currentReportType => _currentReportType;
  bool get isLoading => _isLoading;

  // Getter for current provider
  BaseReportProvider get currentProvider => _providers[_currentReportType]!;

  // Constructor with optional providers for dependency injection
  ReportsProvider({
    FinancialReportProvider? financialProvider,
    OccupancyReportProvider? occupancyProvider,
    MaintenanceReportProvider? maintenanceProvider,
    TenantReportProvider? tenantProvider,
  }) {
    debugPrint("ReportsProvider: Initializing with providers");
    _providers[ReportType.financial] =
        financialProvider ?? FinancialReportProvider();
    _providers[ReportType.occupancy] =
        occupancyProvider ?? OccupancyReportProvider();
    _providers[ReportType.maintenance] =
        maintenanceProvider ?? MaintenanceReportProvider();
    _providers[ReportType.tenant] = tenantProvider ?? TenantReportProvider();
  }

  // Method to update providers after initialization
  void updateProviders(
    FinancialReportProvider financial,
    OccupancyReportProvider occupancy,
    MaintenanceReportProvider maintenance,
    TenantReportProvider tenant,
  ) {
    _providers[ReportType.financial] = financial;
    _providers[ReportType.occupancy] = occupancy;
    _providers[ReportType.maintenance] = maintenance;
    _providers[ReportType.tenant] = tenant;
    notifyListeners();
  }

  // Set report type from string
  void setReportTypeFromString(String reportName) {
    final reportType = _getReportTypeFromString(reportName);
    if (reportType != null) {
      setReportType(reportType);
    }
  }

  // Helper method to convert string to ReportType
  ReportType? _getReportTypeFromString(String reportName) {
    switch (reportName) {
      case 'Financial Report':
        return ReportType.financial;
      case 'Occupancy Report':
        return ReportType.occupancy;
      case 'Maintenance Report':
        return ReportType.maintenance;
      case 'Tenant Report':
        return ReportType.tenant;
      default:
        return null;
    }
  }

  // Set current report type and load data if needed
  void setReportType(ReportType type) {
    if (_currentReportType != type) {
      debugPrint("ReportsProvider: Switching to report type $type");
      _currentReportType = type;
      notifyListeners();
    }
  }

  // Load data for current report type
  Future<void> loadCurrentReportData() async {
    debugPrint("ReportsProvider: Loading data for $_currentReportType");
    _isLoading = true;
    notifyListeners();

    try {
      await currentProvider.execute(() async {
        await currentProvider.fetchItems();
      });
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update all providers with new date range
  void updateDateRangeForAll(DateTime startDate, DateTime endDate) {
    debugPrint("ReportsProvider: Updating date range for all providers");
    for (final provider in _providers.values) {
      provider.setDateRange(startDate, endDate);
    }
  }

  // Get provider for a specific report type
  T getProvider<T extends BaseReportProvider>(ReportType type) {
    return _providers[type] as T;
  }

  // Access to report data based on current type
  List<FinancialReportItem> get financialReportData =>
      financialReportProvider.items;
  List<OccupancyReportItem> get occupancyReportData =>
      occupancyReportProvider.items;
  List<MaintenanceReportItem> get maintenanceReportData =>
      maintenanceReportProvider.items;
  List<TenantReportItem> get tenantReportData => tenantReportProvider.items;

  // Date getters based on current report type
  DateTime get startDate => currentProvider.startDate;
  DateTime get endDate => currentProvider.endDate;

  // Formatted date strings
  String get formattedStartDate => currentProvider.formattedStartDate;
  String get formattedEndDate => currentProvider.formattedEndDate;

  // Get report type string
  String getReportTypeString() => currentProvider.getReportName();

  // Get title with date range based on current report type
  String getReportTitleWithDateRange() =>
      currentProvider.getReportTitleWithDateRange();

  // Generic export method
  Future<void> _exportReport(String fileExtension, String description) async {
    await Future.delayed(
      const Duration(seconds: 1),
    ); // Simulate processing time

    final fileName =
        '${getReportTypeString().replaceAll(' ', '_')}_$formattedStartDate-$formattedEndDate.$fileExtension';
    debugPrint('Exporting to $description: $fileName');
  }

  // Export methods
  Future<void> exportToPDF() async => _exportReport('pdf', 'PDF');

  Future<void> exportToExcel() async => _exportReport('xlsx', 'Excel');

  Future<void> exportToCSV() async => _exportReport('csv', 'CSV');

  // Update date range for current provider
  void setDateRange(DateTime startDate, DateTime endDate) {
    currentProvider.setDateRange(startDate, endDate);
    notifyListeners();
  }
}
