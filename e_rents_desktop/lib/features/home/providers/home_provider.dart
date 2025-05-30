import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/services/statistics_service.dart';
import 'package:e_rents_desktop/models/statistics/dashboard_statistics.dart';

/// Simplified Home Provider focused on landlord dashboard
/// Uses single consolidated dashboard endpoint for optimal performance
class HomeProvider extends BaseProvider<DashboardStatistics> {
  final StatisticsService _statisticsService;

  // Single source of truth from backend dashboard endpoint
  DashboardStatistics? _dashboardStatistics;

  HomeProvider(this._statisticsService);

  // Main dashboard data getter
  DashboardStatistics? get dashboardStatistics => _dashboardStatistics;

  // Convenience getters for UI components (with null-safe fallbacks)
  int get propertyCount => _dashboardStatistics?.totalProperties ?? 0;
  double get occupancyRate => _dashboardStatistics?.occupancyRate ?? 0.0;
  int get openIssuesCount =>
      _dashboardStatistics?.pendingMaintenanceIssues ?? 0;
  double get monthlyRevenue => _dashboardStatistics?.monthlyRevenue ?? 0.0;
  double get yearlyRevenue => _dashboardStatistics?.yearlyRevenue ?? 0.0;

  // Financial summary for dashboard cards
  double get totalRentIncome => _dashboardStatistics?.totalRentIncome ?? 0.0;
  double get totalMaintenanceCosts =>
      _dashboardStatistics?.totalMaintenanceCosts ?? 0.0;
  double get netIncome => _dashboardStatistics?.netTotal ?? 0.0;

  // Top performing properties
  List<PopularProperty> get topProperties =>
      _dashboardStatistics?.topProperties ?? [];

  // Property performance metrics
  double get averageRating => _dashboardStatistics?.averageRating ?? 0.0;
  int get occupiedProperties => _dashboardStatistics?.occupiedProperties ?? 0;
  int get availableProperties => propertyCount - occupiedProperties;

  /// Load all dashboard data from single backend endpoint
  /// This is the main method called by UI to refresh dashboard
  Future<void> loadDashboardData() async {
    await execute(() async {
      _dashboardStatistics = await _statisticsService.getDashboardStatistics();
    });
  }

  /// Force refresh dashboard data
  Future<void> refreshDashboard() async {
    await loadDashboardData();
  }

  // BaseProvider implementation for consistency
  @override
  DashboardStatistics fromJson(Map<String, dynamic> json) {
    return DashboardStatistics.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(DashboardStatistics item) {
    return item.toJson();
  }

  @override
  String get endpoint => '/statistics/dashboard';

  @override
  List<DashboardStatistics> getMockItems() {
    // Return empty list - we use real backend data only
    return [];
  }
}
