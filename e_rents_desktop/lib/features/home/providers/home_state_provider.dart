import 'package:flutter/foundation.dart';
import 'package:e_rents_desktop/base/base.dart';
import 'package:e_rents_desktop/repositories/home_repository.dart';
import 'package:e_rents_desktop/models/statistics/dashboard_statistics.dart';

/// State provider for Home dashboard using StateProvider pattern
/// Manages dashboard statistics with comprehensive state management
class HomeStateProvider extends StateProvider<DashboardStatistics?> {
  final HomeRepository _repository;

  // Loading states
  bool _isLoading = false;
  AppError? _error;

  // Performance insights cache
  Map<String, dynamic>? _performanceInsights;
  Map<String, dynamic>? _occupancyMetrics;
  Map<String, dynamic>? _financialMetrics;

  HomeStateProvider(this._repository) : super(null);

  // Getters
  bool get isLoading => _isLoading;
  AppError? get error => _error;
  bool get hasData => state != null;

  // Business logic getters with null-safe fallbacks
  int get propertyCount => state?.totalProperties ?? 0;
  double get occupancyRate => state?.occupancyRate ?? 0.0;
  int get openIssuesCount => state?.pendingMaintenanceIssues ?? 0;
  double get monthlyRevenue => state?.monthlyRevenue ?? 0.0;
  double get yearlyRevenue => state?.yearlyRevenue ?? 0.0;

  // Financial summary getters
  double get totalRentIncome => state?.totalRentIncome ?? 0.0;
  double get totalMaintenanceCosts => state?.totalMaintenanceCosts ?? 0.0;
  double get netIncome => state?.netTotal ?? 0.0;

  // Property performance getters
  List<PopularProperty> get topProperties => state?.topProperties ?? [];
  double get averageRating => state?.averageRating ?? 0.0;
  int get occupiedProperties => state?.occupiedProperties ?? 0;
  int get availableProperties => propertyCount - occupiedProperties;

  // Performance metrics getters (computed and cached)
  Map<String, dynamic> get performanceInsights {
    if (_performanceInsights == null && state != null) {
      _performanceInsights = _repository.getPerformanceInsights(state!);
    }
    return _performanceInsights ?? {};
  }

  Map<String, dynamic> get occupancyMetrics {
    if (_occupancyMetrics == null && state != null) {
      _occupancyMetrics = _repository.calculateOccupancyMetrics(state!);
    }
    return _occupancyMetrics ?? {};
  }

  Map<String, dynamic> get financialMetrics {
    if (_financialMetrics == null && state != null) {
      _financialMetrics = _repository.calculateFinancialMetrics(state!);
    }
    return _financialMetrics ?? {};
  }

  /// Load dashboard statistics (with caching)
  Future<void> loadDashboardData() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint('HomeStateProvider: Loading dashboard statistics...');

      // Try to get cached data first for instant loading
      final cachedData = await _repository.getCachedDashboardStatistics();
      if (cachedData != null) {
        _updateData(cachedData);
      }

      // Load fresh data (which may be served from cache)
      final statistics = await _repository.loadDashboardStatistics();
      _updateData(statistics);

      debugPrint('HomeStateProvider: Dashboard statistics loaded successfully');
    } catch (e, stackTrace) {
      _error = AppError.fromException(e, stackTrace);
      debugPrint('HomeStateProvider: Error loading dashboard data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Force refresh dashboard data (bypasses cache)
  Future<void> refreshDashboard() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint('HomeStateProvider: Refreshing dashboard statistics...');

      final statistics = await _repository.refreshDashboardStatistics();
      _updateData(statistics);

      debugPrint('HomeStateProvider: Dashboard refreshed successfully');
    } catch (e, stackTrace) {
      _error = AppError.fromException(e, stackTrace);
      debugPrint('HomeStateProvider: Error refreshing dashboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear all cached data and reload
  Future<void> clearCacheAndReload() async {
    _repository.clearCache();
    _clearComputedMetrics();
    await loadDashboardData();
  }

  /// Check if cached data is available and fresh
  Future<bool> hasFreshCachedData() async => await _repository.isCacheFresh();

  /// Update data and clear computed metrics cache
  void _updateData(DashboardStatistics newData) {
    updateState(newData);
    _clearComputedMetrics(); // Force recomputation of metrics
  }

  /// Clear computed metrics cache
  void _clearComputedMetrics() {
    _performanceInsights = null;
    _occupancyMetrics = null;
    _financialMetrics = null;
  }

  @override
  void dispose() {
    _clearComputedMetrics();
    super.dispose();
  }

  @override
  String get debugName => 'HomeState';
}
