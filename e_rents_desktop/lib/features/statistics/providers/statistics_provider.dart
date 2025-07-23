import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/models/statistics/dashboard_statistics.dart';
import 'package:e_rents_desktop/models/statistics/financial_statistics.dart';
import 'package:e_rents_desktop/models/statistics/financial_statistics_api.dart';
import 'package:e_rents_desktop/models/statistics/financial_summary_dto.dart';
import 'package:e_rents_desktop/models/reports/financial_report_item.dart';
import 'package:intl/intl.dart';

/// Provider for managing statistics state and operations
/// Handles dashboard statistics, financial statistics, and UI state
class StatisticsProvider extends ChangeNotifier {
  final ApiService _api;

  StatisticsProvider(this._api);

  // ─── State ──────────────────────────────────────────────────────────────
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Statistics data
  DashboardStatistics? _dashboardStats;
  DashboardStatistics? get dashboardStats => _dashboardStats;

  FinancialStatisticsApi? _apiFinancialStats;
  FinancialStatisticsApi? get apiFinancialStats => _apiFinancialStats;

  FinancialStatistics? _financialStats;
  FinancialStatistics? get financialStats => _financialStats;

  FinancialSummaryDto? _originalSummaryDto;
  FinancialSummaryDto? get originalSummaryDto => _originalSummaryDto;

  // Date range state
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;

  // Cache state with TTL
  DateTime? _dashboardCacheTime;
  DateTime? _financialCacheTime;
  String? _financialCacheKey;

  // Cache TTL configurations
  static const Duration _dashboardCacheTtl = Duration(minutes: 15);
  static const Duration _financialDataCacheTtl = Duration(minutes: 5);

  static final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
  String get formattedStartDate => dateFormat.format(_startDate);
  String get formattedEndDate => dateFormat.format(_endDate);

  // ─── Public API ─────────────────────────────────────────────────────────

  /// Load dashboard statistics with caching
  Future<void> loadDashboardStatistics({bool forceRefresh = false}) async {
    // Check cache first if not forcing refresh
    if (!forceRefresh && _dashboardStats != null && _dashboardCacheTime != null) {
      final cacheAge = DateTime.now().difference(_dashboardCacheTime!);
      if (cacheAge < _dashboardCacheTtl) {
        debugPrint('StatisticsProvider: Returning cached dashboard statistics');
        return;
      }
    }

    try {
      _setLoading(true);
      _clearError();

      debugPrint('StatisticsProvider: Loading dashboard statistics...');
      
      final response = await _api.get('/Statistics/dashboard', authenticated: true);
      final stats = DashboardStatistics.fromJson(jsonDecode(response.body));
      
      _dashboardStats = stats;
      _dashboardCacheTime = DateTime.now();
      
      debugPrint('StatisticsProvider: Dashboard statistics loaded successfully');
    } catch (e) {
      _setError('Failed to load dashboard statistics: $e');
      debugPrint('StatisticsProvider: Error loading dashboard statistics: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load financial statistics for the current date range with caching
  Future<void> loadFinancialStatistics({
    DateTime? startDate,
    DateTime? endDate,
    bool forceRefresh = false,
  }) async {
    final effectiveStartDate = startDate ?? _startDate;
    final effectiveEndDate = endDate ?? _endDate;
    
    _startDate = effectiveStartDate;
    _endDate = effectiveEndDate;

    final cacheKey = '${effectiveStartDate.toIso8601String()}_${effectiveEndDate.toIso8601String()}';
    
    // Check cache first if not forcing refresh
    if (!forceRefresh && 
        _apiFinancialStats != null && 
        _financialCacheTime != null && 
        _financialCacheKey == cacheKey) {
      final cacheAge = DateTime.now().difference(_financialCacheTime!);
      if (cacheAge < _financialDataCacheTtl) {
        debugPrint('StatisticsProvider: Returning cached financial statistics');
        return;
      }
    }

    debugPrint(
      'StatisticsProvider: Loading financial statistics for range: ${dateFormat.format(effectiveStartDate)} to ${dateFormat.format(effectiveEndDate)}',
    );

    try {
      _setLoading(true);
      _clearError();

      // Get financial summary DTO from API
      _originalSummaryDto = await _getFinancialSummaryDto(
        startDate: effectiveStartDate,
        endDate: effectiveEndDate,
      );

      // Convert to API model
      _apiFinancialStats = FinancialStatisticsApi.fromSummaryDto(_originalSummaryDto!);

      // Convert to UI model
      _financialStats = _convertToUiModel(
        _apiFinancialStats,
        _originalSummaryDto,
        effectiveStartDate,
        effectiveEndDate,
      );

      // Update cache
      _financialCacheTime = DateTime.now();
      _financialCacheKey = cacheKey;

      debugPrint('StatisticsProvider: Financial statistics loaded successfully');
    } catch (e) {
      _setError('Failed to load financial statistics: $e');
      debugPrint('StatisticsProvider: Error loading financial statistics: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Set date range and immediately fetch fresh data
  Future<void> setDateRangeAndFetch(DateTime start, DateTime end) async {
    debugPrint(
      'StatisticsProvider: Date range changed from ${dateFormat.format(_startDate)}-${dateFormat.format(_endDate)} to ${dateFormat.format(start)}-${dateFormat.format(end)}',
    );

    await loadFinancialStatistics(
      startDate: start,
      endDate: end,
      forceRefresh: true,
    );

    debugPrint('StatisticsProvider: Date range updated and data refreshed');
  }

  /// Refresh all statistics data
  Future<void> refreshAllData() async {
    await Future.wait([
      loadDashboardStatistics(forceRefresh: true),
      loadFinancialStatistics(forceRefresh: true),
    ]);
  }

  /// Clear cached statistics data
  void clearCache() {
    _dashboardStats = null;
    _dashboardCacheTime = null;
    _apiFinancialStats = null;
    _financialStats = null;
    _originalSummaryDto = null;
    _financialCacheTime = null;
    _financialCacheKey = null;
    debugPrint('StatisticsProvider: Cache cleared');
    notifyListeners();
  }

  // ─── Private Helper Methods ─────────────────────────────────────────────

  /// Get financial summary DTO from API
  Future<FinancialSummaryDto> _getFinancialSummaryDto({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    debugPrint(
      'StatisticsProvider: Fetching financial summary DTO for range: ${startDate?.toIso8601String()} to ${endDate?.toIso8601String()}',
    );

    // Prepare request body
    final requestBody = <String, dynamic>{'period': null};

    if (startDate != null) {
      requestBody['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      requestBody['endDate'] = endDate.toIso8601String();
    }

    final response = await _api.post(
      '/Statistics/financial',
      requestBody,
      authenticated: true,
    );

    final summaryDto = FinancialSummaryDto.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );

    debugPrint(
      'StatisticsProvider: Successfully fetched financial summary DTO with ${summaryDto.revenueHistory.length} monthly records',
    );

    return summaryDto;
  }

  /// Convert API statistics and DTO to UI model
  FinancialStatistics _convertToUiModel(
    FinancialStatisticsApi? apiStats,
    FinancialSummaryDto? originalDto,
    DateTime startDate,
    DateTime endDate,
  ) {
    if (apiStats == null || originalDto == null) {
      return FinancialStatistics(
        totalRent: 0,
        totalMaintenanceCosts: 0,
        netTotal: 0,
        startDate: startDate,
        endDate: endDate,
        monthlyBreakdown: [],
      );
    }

    return _buildFinancialStatisticsUiModel(
      apiStats,
      originalDto,
      startDate,
      endDate,
    );
  }

  /// Build financial statistics UI model with business logic
  FinancialStatistics _buildFinancialStatisticsUiModel(
    FinancialStatisticsApi apiStats,
    FinancialSummaryDto originalDto,
    DateTime startDate,
    DateTime endDate,
  ) {
    // Get maintenance costs from the original DTO
    final totalMaintenanceCosts = originalDto.totalMaintenanceCosts;

    // Build monthly breakdown for charts
    final monthlyBreakdown = <FinancialReportItem>[];
    if (apiStats.revenueHistory.isNotEmpty) {
      // Create a map for quick lookup of maintenance costs by month
      final monthlyMaintenanceMap = <String, double>{};
      for (final monthlyDto in originalDto.revenueHistory) {
        final key = '${monthlyDto.year}-${monthlyDto.month}';
        monthlyMaintenanceMap[key] = monthlyDto.maintenanceCosts;
      }

      for (final monthlyRevenue in apiStats.revenueHistory) {
        final monthDate = DateTime(
          monthlyRevenue.year,
          monthlyRevenue.month,
          1,
        );
        final firstDayOfMonth = _formatDate(monthDate);
        final lastDayOfMonth = _formatDate(
          DateTime(monthlyRevenue.year, monthlyRevenue.month + 1, 0),
        );

        // Get maintenance costs for this month
        final monthKey = '${monthlyRevenue.year}-${monthlyRevenue.month}';
        final monthlyMaintenance = monthlyMaintenanceMap[monthKey] ?? 0.0;

        monthlyBreakdown.add(
          FinancialReportItem(
            dateFrom: firstDayOfMonth,
            dateTo: lastDayOfMonth,
            property: 'Monthly Total',
            totalRent: monthlyRevenue.revenue,
            maintenanceCosts: monthlyMaintenance,
            total: monthlyRevenue.revenue - monthlyMaintenance,
          ),
        );
      }
    }

    return FinancialStatistics(
      totalRent: originalDto.totalRentIncome,
      totalMaintenanceCosts: totalMaintenanceCosts,
      netTotal: originalDto.netTotal,
      startDate: startDate,
      endDate: endDate,
      monthlyBreakdown: monthlyBreakdown,
    );
  }

  /// Format date for UI display
  String _formatDate(DateTime date) {
    return dateFormat.format(date);
  }

  /// Set loading state and notify listeners
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Set error state and notify listeners
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// Clear error state
  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }
}
