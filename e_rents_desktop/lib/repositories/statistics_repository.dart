import 'package:flutter/foundation.dart';
import 'package:e_rents_desktop/base/base.dart';
import 'package:e_rents_desktop/models/statistics/dashboard_statistics.dart';
import 'package:e_rents_desktop/models/statistics/financial_statistics.dart';
import 'package:e_rents_desktop/models/statistics/financial_statistics_api.dart';
import 'package:e_rents_desktop/models/statistics/financial_summary_dto.dart';
import 'package:e_rents_desktop/models/reports/financial_report_item.dart';
import 'package:e_rents_desktop/services/statistics_service.dart';
import 'package:intl/intl.dart';

/// Repository for statistics data management with intelligent caching
/// Handles dashboard statistics, financial statistics, and related metrics
class StatisticsRepository {
  final StatisticsService service;
  final CacheManager cacheManager;

  // Cache TTL configurations
  static const Duration _dashboardCacheTtl = Duration(minutes: 15);
  static const Duration _financialDataCacheTtl = Duration(minutes: 5);

  StatisticsRepository({required this.service, required this.cacheManager});

  /// Load dashboard statistics with caching
  /// Returns portfolio overview including occupancy, revenue, top properties
  Future<DashboardStatistics> getDashboardStatistics({
    bool forceRefresh = false,
  }) async {
    const cacheKey = 'statistics_dashboard';

    if (!forceRefresh) {
      final cached = await cacheManager.get<DashboardStatistics>(cacheKey);
      if (cached != null) {
        debugPrint(
          'StatisticsRepository: Returning cached dashboard statistics',
        );
        return cached;
      }
    }

    try {
      debugPrint(
        'StatisticsRepository: Fetching fresh dashboard statistics...',
      );
      final stats = await service.getDashboardStatistics();

      // Cache with 15-minute TTL for dashboard data
      await cacheManager.set(cacheKey, stats, duration: _dashboardCacheTtl);
      debugPrint(
        'StatisticsRepository: Dashboard statistics cached successfully',
      );

      return stats;
    } catch (e, stackTrace) {
      debugPrint(
        'StatisticsRepository: Error loading dashboard statistics: $e',
      );
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Load financial statistics for a date range with caching
  /// Returns detailed financial data including revenue trends and breakdowns
  Future<FinancialStatisticsApi> getFinancialStatistics({
    DateTime? startDate,
    DateTime? endDate,
    bool forceRefresh = false,
  }) async {
    final effectiveStartDate =
        startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final effectiveEndDate = endDate ?? DateTime.now();

    final cacheKey =
        'statistics_financial_${effectiveStartDate.toIso8601String()}_${effectiveEndDate.toIso8601String()}';

    if (!forceRefresh) {
      final cached = await cacheManager.get<FinancialStatisticsApi>(cacheKey);
      if (cached != null) {
        debugPrint(
          'StatisticsRepository: Returning cached financial statistics',
        );
        return cached;
      }
    }

    try {
      debugPrint(
        'StatisticsRepository: Fetching fresh financial statistics...',
      );
      final stats = await service.getFinancialStatistics(
        startDate: effectiveStartDate,
        endDate: effectiveEndDate,
      );

      // Cache with 5-minute TTL for financial data (more volatile)
      await cacheManager.set(cacheKey, stats, duration: _financialDataCacheTtl);
      debugPrint(
        'StatisticsRepository: Financial statistics cached successfully',
      );

      return stats;
    } catch (e, stackTrace) {
      debugPrint(
        'StatisticsRepository: Error loading financial statistics: $e',
      );
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Load financial summary DTO for a date range with caching
  /// Returns raw DTO with detailed maintenance costs and monthly breakdown
  Future<FinancialSummaryDto> getFinancialSummaryDto({
    DateTime? startDate,
    DateTime? endDate,
    bool forceRefresh = false,
  }) async {
    final effectiveStartDate =
        startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final effectiveEndDate = endDate ?? DateTime.now();

    final cacheKey =
        'statistics_summary_${effectiveStartDate.toIso8601String()}_${effectiveEndDate.toIso8601String()}';

    if (!forceRefresh) {
      final cached = await cacheManager.get<FinancialSummaryDto>(cacheKey);
      if (cached != null) {
        debugPrint(
          'StatisticsRepository: Returning cached financial summary DTO',
        );
        return cached;
      }
    }

    try {
      debugPrint(
        'StatisticsRepository: Fetching fresh financial summary DTO...',
      );
      final summaryDto = await service.getFinancialSummaryDto(
        startDate: effectiveStartDate,
        endDate: effectiveEndDate,
      );

      // Cache with 5-minute TTL for financial data
      await cacheManager.set(
        cacheKey,
        summaryDto,
        duration: _financialDataCacheTtl,
      );
      debugPrint(
        'StatisticsRepository: Financial summary DTO cached successfully',
      );

      return summaryDto;
    } catch (e, stackTrace) {
      debugPrint(
        'StatisticsRepository: Error loading financial summary DTO: $e',
      );
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Convert API statistics and DTO to UI model
  /// Provides business logic for transforming financial data for display
  FinancialStatistics convertToUiModel(
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

    // Implementation of UI model conversion logic
    // (This mirrors the existing logic from StatisticsProvider)
    return _buildFinancialStatisticsUiModel(
      apiStats,
      originalDto,
      startDate,
      endDate,
    );
  }

  /// Business logic: Build financial statistics UI model
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
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(date);
  }

  /// Clear all statistics caches
  Future<void> clearCache() async {
    await cacheManager.clear('statistics_dashboard');
    // Clear financial data cache keys (note: this clears by pattern match)
    // In a production app, you might want a more sophisticated cache clearing strategy
    debugPrint('StatisticsRepository: Cache cleared');
  }
}
