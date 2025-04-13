import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/reports/reports.dart';
import 'package:e_rents_desktop/services/mock_data_service.dart';

enum ReportType { financial, occupancy, maintenance, tenant }

class ReportsProvider extends ChangeNotifier {
  // Report type
  ReportType _currentReportType = ReportType.financial;
  ReportType get currentReportType => _currentReportType;

  // Date range
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;

  // Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Reports data
  List<FinancialReportItem> _financialReportData = [];
  List<OccupancyReportItem> _occupancyReportData = [];
  List<MaintenanceReportItem> _maintenanceReportData = [];
  List<TenantReportItem> _tenantReportData = [];

  // Getters for the reports
  List<FinancialReportItem> get financialReportData => _financialReportData;
  List<OccupancyReportItem> get occupancyReportData => _occupancyReportData;
  List<MaintenanceReportItem> get maintenanceReportData =>
      _maintenanceReportData;
  List<TenantReportItem> get tenantReportData => _tenantReportData;

  // Initialize the provider
  ReportsProvider() {
    loadReportData();
  }

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
  String getReportTypeString() {
    switch (_currentReportType) {
      case ReportType.financial:
        return 'Financial Report';
      case ReportType.occupancy:
        return 'Occupancy Report';
      case ReportType.maintenance:
        return 'Maintenance Report';
      case ReportType.tenant:
        return 'Tenant Report';
    }
  }

  // Set date range
  void setDateRange(DateTime startDate, DateTime endDate) {
    _startDate = startDate;
    _endDate = endDate;
    loadReportData();
  }

  // Load report data based on current settings
  Future<void> loadReportData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // In a real app, these would be async calls to an API
      // Here we're using the MockDataService

      // Load all report types to ensure data is available
      _financialReportData = MockDataService.getMockFinancialReportData(
        _startDate,
        _endDate,
      );
      _occupancyReportData = MockDataService.getMockOccupancyReportData();
      _maintenanceReportData = MockDataService.getMockMaintenanceReportData(
        _startDate,
        _endDate,
      );
      _tenantReportData = MockDataService.getMockTenantReportData();
    } catch (e) {
      // Handle any errors
      debugPrint('Error loading report data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Export methods
  Future<void> exportToPDF() async {
    // TODO: Implement PDF export logic
    await Future.delayed(
      const Duration(seconds: 1),
    ); // Simulate processing time
    debugPrint('Exporting ${getReportTypeString()} to PDF');
  }

  Future<void> exportToExcel() async {
    // TODO: Implement Excel export logic
    await Future.delayed(
      const Duration(seconds: 1),
    ); // Simulate processing time
    debugPrint('Exporting ${getReportTypeString()} to Excel');
  }

  Future<void> exportToCSV() async {
    // TODO: Implement CSV export logic
    await Future.delayed(
      const Duration(seconds: 1),
    ); // Simulate processing time
    debugPrint('Exporting ${getReportTypeString()} to CSV');
  }
}
