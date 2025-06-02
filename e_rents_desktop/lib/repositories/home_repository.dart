import 'package:e_rents_desktop/base/repository.dart';
import 'package:e_rents_desktop/services/statistics_service.dart';
import 'package:e_rents_desktop/models/statistics/dashboard_statistics.dart';
import 'package:e_rents_desktop/base/app_error.dart';
import 'package:e_rents_desktop/base/cache_manager.dart';

/// Repository for managing home dashboard data with intelligent caching
/// Provides landlord dashboard statistics and performance metrics
class HomeRepository
    extends BaseRepository<DashboardStatistics, StatisticsService> {
  static const String _cacheKey = 'dashboard_statistics';

  HomeRepository({required super.service, required super.cacheManager});

  @override
  String get resourceName => 'dashboard';

  @override
  Duration get defaultCacheTtl => const Duration(minutes: 5);

  // Required BaseRepository method implementations
  @override
  Future<List<DashboardStatistics>> fetchAllFromService([
    Map<String, dynamic>? params,
  ]) async {
    final stats = await service.getDashboardStatistics();
    return [stats]; // Dashboard stats is a single item, wrapped in a list
  }

  @override
  Future<DashboardStatistics> fetchByIdFromService(String id) async {
    return await service.getDashboardStatistics();
  }

  @override
  Future<DashboardStatistics> createInService(DashboardStatistics item) async {
    throw AppError(
      type: ErrorType.permission,
      message: 'Dashboard statistics cannot be created directly',
    );
  }

  @override
  Future<DashboardStatistics> updateInService(
    String id,
    DashboardStatistics item,
  ) async {
    throw AppError(
      type: ErrorType.permission,
      message: 'Dashboard statistics cannot be updated directly',
    );
  }

  @override
  Future<void> deleteInService(String id) async {
    throw AppError(
      type: ErrorType.permission,
      message: 'Dashboard statistics cannot be deleted',
    );
  }

  @override
  Future<bool> existsInService(String id) async {
    try {
      await service.getDashboardStatistics();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<int> countInService([Map<String, dynamic>? params]) async {
    return 1; // Dashboard is always a single item
  }

  @override
  String? extractIdFromItem(DashboardStatistics item) {
    return 'dashboard'; // Dashboard has a fixed ID
  }

  /// Load complete dashboard statistics with caching
  /// Returns cached data if available and fresh, otherwise fetches from API
  Future<DashboardStatistics> loadDashboardStatistics() async {
    return await getById('dashboard');
  }

  /// Force refresh dashboard data (bypass cache)
  /// Use this when user explicitly requests refresh
  Future<DashboardStatistics> refreshDashboardStatistics() async {
    return await refreshItem('dashboard');
  }

  /// Get cached dashboard data if available (for instant loading)
  /// Returns null if no cached data or cache is expired
  Future<DashboardStatistics?> getCachedDashboardStatistics() async {
    try {
      final cacheKey = 'dashboard_item_{"id":"dashboard"}';
      return await cacheManager.get<DashboardStatistics>(cacheKey);
    } catch (e) {
      return null;
    }
  }

  /// Business logic: Calculate occupancy metrics
  Map<String, dynamic> calculateOccupancyMetrics(
    DashboardStatistics statistics,
  ) {
    final totalProperties = statistics.totalProperties;
    final occupiedProperties = statistics.occupiedProperties;
    final availableProperties = totalProperties - occupiedProperties;

    return {
      'totalProperties': totalProperties,
      'occupiedProperties': occupiedProperties,
      'availableProperties': availableProperties,
      'occupancyRate': statistics.occupancyRate,
      'occupancyPercentage': (statistics.occupancyRate * 100).toStringAsFixed(
        1,
      ),
    };
  }

  /// Business logic: Calculate financial metrics
  Map<String, dynamic> calculateFinancialMetrics(
    DashboardStatistics statistics,
  ) {
    final totalRentIncome = statistics.totalRentIncome;
    final totalMaintenanceCosts = statistics.totalMaintenanceCosts;
    final netTotal = statistics.netTotal;
    final monthlyRevenue = statistics.monthlyRevenue;
    final yearlyRevenue = statistics.yearlyRevenue;

    // Calculate profit margin
    final profitMargin =
        totalRentIncome > 0 ? ((netTotal / totalRentIncome) * 100) : 0.0;

    // Calculate maintenance cost ratio
    final maintenanceRatio =
        totalRentIncome > 0
            ? ((totalMaintenanceCosts / totalRentIncome) * 100)
            : 0.0;

    return {
      'totalRentIncome': totalRentIncome,
      'totalMaintenanceCosts': totalMaintenanceCosts,
      'netTotal': netTotal,
      'monthlyRevenue': monthlyRevenue,
      'yearlyRevenue': yearlyRevenue,
      'profitMargin': profitMargin,
      'maintenanceRatio': maintenanceRatio,
    };
  }

  /// Business logic: Get performance insights
  Map<String, dynamic> getPerformanceInsights(DashboardStatistics statistics) {
    final insights = <String, dynamic>{};

    // Occupancy performance
    if (statistics.occupancyRate >= 0.9) {
      insights['occupancyStatus'] = 'excellent';
      insights['occupancyMessage'] = 'Excellent occupancy rate!';
    } else if (statistics.occupancyRate >= 0.75) {
      insights['occupancyStatus'] = 'good';
      insights['occupancyMessage'] = 'Good occupancy rate';
    } else {
      insights['occupancyStatus'] = 'needs_improvement';
      insights['occupancyMessage'] = 'Occupancy could be improved';
    }

    // Maintenance performance
    if (statistics.pendingMaintenanceIssues == 0) {
      insights['maintenanceStatus'] = 'excellent';
      insights['maintenanceMessage'] = 'No pending maintenance issues!';
    } else if (statistics.pendingMaintenanceIssues <= 3) {
      insights['maintenanceStatus'] = 'good';
      insights['maintenanceMessage'] = 'Few pending maintenance issues';
    } else {
      insights['maintenanceStatus'] = 'needs_attention';
      insights['maintenanceMessage'] =
          'Multiple maintenance issues need attention';
    }

    // Financial performance
    final profitMargin =
        statistics.totalRentIncome > 0
            ? ((statistics.netTotal / statistics.totalRentIncome) * 100)
            : 0.0;

    if (profitMargin >= 70) {
      insights['financialStatus'] = 'excellent';
      insights['financialMessage'] = 'Excellent profit margin!';
    } else if (profitMargin >= 50) {
      insights['financialStatus'] = 'good';
      insights['financialMessage'] = 'Good financial performance';
    } else {
      insights['financialStatus'] = 'needs_improvement';
      insights['financialMessage'] = 'Financial performance could be improved';
    }

    return insights;
  }

  /// Check if cache is fresh
  Future<bool> isCacheFresh() async {
    try {
      final cacheKey = 'dashboard_item_{"id":"dashboard"}';
      final cached = await cacheManager.get<DashboardStatistics>(cacheKey);
      return cached != null;
    } catch (e) {
      return false;
    }
  }
}
