import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/reports/reports.dart';
import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/features/reports/providers/base_report_provider.dart';
import 'package:e_rents_desktop/features/reports/providers/financial_report_provider.dart';
import 'package:e_rents_desktop/features/reports/providers/occupancy_report_provider.dart';
import 'package:e_rents_desktop/features/reports/providers/maintenance_report_provider.dart';
import 'package:e_rents_desktop/features/reports/providers/tenant_report_provider.dart';

/// Report type enum used for switching between report screens
enum ReportType { financial, occupancy, maintenance, tenant }

/// Main provider class that coordinates all individual report providers
class ReportsProvider extends ChangeNotifier {
  // Individual report providers - not final to support updates
  FinancialReportProvider financialReportProvider;
  OccupancyReportProvider occupancyReportProvider;
  MaintenanceReportProvider maintenanceReportProvider;
  TenantReportProvider tenantReportProvider;

  // Current active report type
  ReportType _currentReportType = ReportType.financial;
  ReportType get currentReportType => _currentReportType;

  // Constructor - initialize all providers
  ReportsProvider({
    FinancialReportProvider? financialProvider,
    OccupancyReportProvider? occupancyProvider,
    MaintenanceReportProvider? maintenanceProvider,
    TenantReportProvider? tenantProvider,
  }) : financialReportProvider = financialProvider ?? FinancialReportProvider(),
       occupancyReportProvider = occupancyProvider ?? OccupancyReportProvider(),
       maintenanceReportProvider =
           maintenanceProvider ?? MaintenanceReportProvider(),
       tenantReportProvider = tenantProvider ?? TenantReportProvider();

  // Update providers reference without creating new instances
  void updateProviders(
    FinancialReportProvider financialProvider,
    OccupancyReportProvider occupancyProvider,
    MaintenanceReportProvider maintenanceProvider,
    TenantReportProvider tenantProvider,
  ) {
    // Only replace references if they're different to avoid unnecessary rebuilds
    if (financialReportProvider != financialProvider ||
        occupancyReportProvider != occupancyProvider ||
        maintenanceReportProvider != maintenanceProvider ||
        tenantReportProvider != tenantProvider) {
      // Store the current report type to restore it
      final currentType = _currentReportType;

      // Update provider references
      financialReportProvider = financialProvider;
      occupancyReportProvider = occupancyProvider;
      maintenanceReportProvider = maintenanceProvider;
      tenantReportProvider = tenantProvider;

      // Set the report type back to what it was to maintain state
      _currentReportType = currentType;

      // Notify listeners only if something changed
      notifyListeners();
    }
  }

  // Get current report provider
  BaseReportProvider get currentProvider {
    switch (_currentReportType) {
      case ReportType.financial:
        return financialReportProvider;
      case ReportType.occupancy:
        return occupancyReportProvider;
      case ReportType.maintenance:
        return maintenanceReportProvider;
      case ReportType.tenant:
        return tenantReportProvider;
    }
  }

  // Getter for current provider's loading state
  bool get isLoading => currentProvider.state == ViewState.Busy;

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

  // Set the current report type
  void setReportType(ReportType reportType) {
    _currentReportType = reportType;
    notifyListeners();
  }

  // Set the report type from string
  void setReportTypeFromString(String reportTypeString) {
    switch (reportTypeString) {
      case 'Financial Report':
        setReportType(ReportType.financial);
        break;
      case 'Occupancy Report':
        setReportType(ReportType.occupancy);
        break;
      case 'Maintenance Report':
        setReportType(ReportType.maintenance);
        break;
      case 'Tenant Report':
        setReportType(ReportType.tenant);
        break;
    }
  }

  // Get report type string
  String getReportTypeString() => currentProvider.getReportName();

  // Set date range and update all providers
  void setDateRange(DateTime startDate, DateTime endDate) {
    financialReportProvider.setDateRange(startDate, endDate);
    occupancyReportProvider.setDateRange(startDate, endDate);
    maintenanceReportProvider.setDateRange(startDate, endDate);
    tenantReportProvider.setDateRange(startDate, endDate);

    notifyListeners();
  }

  // Get title with date range based on current report type
  String getReportTitleWithDateRange() =>
      currentProvider.getReportTitleWithDateRange();

  // Load all report data
  void loadReportData() {
    financialReportProvider.fetchItems();
    occupancyReportProvider.fetchItems();
    maintenanceReportProvider.fetchItems();
    tenantReportProvider.fetchItems();
  }

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
}
