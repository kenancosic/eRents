import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/services/statistics_service.dart';
import 'package:e_rents_desktop/services/maintenance_service.dart';
import 'package:e_rents_desktop/services/property_service.dart';
import 'package:e_rents_desktop/models/statistics/dashboard_statistics.dart';

class HomeProvider extends BaseProvider<dynamic> {
  // Keep services for potential future use, but mark as unused for now
  // ignore: unused_field
  final PropertyService _propertyService;
  // ignore: unused_field
  final MaintenanceService _maintenanceService;
  final StatisticsService _statisticsService;

  // Single comprehensive dashboard data from backend
  DashboardStatistics? _dashboardStatistics;

  // Optionally keep full lists for details elsewhere
  final List<Property> _properties = [];
  final List<MaintenanceIssue> _issues = [];

  HomeProvider(
    this._propertyService,
    this._maintenanceService,
    this._statisticsService,
  ) {
    // Default to using real data; can be overridden by calling enableMockData()
    // disableMockData();
  }

  // Main getter for dashboard data
  DashboardStatistics? get dashboardStatistics => _dashboardStatistics;

  // Convenience getters for UI (null-safe with fallback)
  int get propertyCount => _dashboardStatistics?.totalProperties ?? 0;
  double get occupancyRate => _dashboardStatistics?.occupancyRate ?? 0.0;
  int get openIssuesCount =>
      _dashboardStatistics?.pendingMaintenanceIssues ?? 0;
  double get netIncome => _dashboardStatistics?.netTotal ?? 0.0;

  // Financial summary properties for FinancialSummaryCard widget
  double get totalRent => _dashboardStatistics?.totalRentIncome ?? 0.0;
  double get totalMaintenanceCosts =>
      _dashboardStatistics?.totalMaintenanceCosts ?? 0.0;
  double get netTotal => _dashboardStatistics?.netTotal ?? 0.0;

  // Optionally expose full lists for details
  List<Property> get properties => _properties;
  List<MaintenanceIssue> get issues => _issues;

  Future<void> loadDashboardData() async {
    await execute(() async {
      // Single comprehensive call to get all dashboard data
      _dashboardStatistics = await _statisticsService.getDashboardStatistics();
    });
  }

  @override
  dynamic fromJson(Map<String, dynamic> json) {
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic> toJson(dynamic item) {
    throw UnimplementedError();
  }

  @override
  String get endpoint => '/home_dashboard';

  @override
  List<dynamic> getMockItems() {
    return [];
  }
}
