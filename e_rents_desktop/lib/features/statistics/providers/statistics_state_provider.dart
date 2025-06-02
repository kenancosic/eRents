import 'package:flutter/foundation.dart';
import 'package:e_rents_desktop/base/base.dart';
import 'package:e_rents_desktop/models/statistics/dashboard_statistics.dart';
import 'package:e_rents_desktop/models/statistics/financial_statistics.dart';
import 'package:e_rents_desktop/models/statistics/financial_statistics_api.dart';
import 'package:e_rents_desktop/models/statistics/financial_summary_dto.dart';
import 'package:e_rents_desktop/repositories/statistics_repository.dart';
import 'package:intl/intl.dart';

/// Provider for managing statistics state
/// Handles dashboard statistics, financial statistics, and UI state
class StatisticsStateProvider extends StateProvider<FinancialStatistics?> {
  final StatisticsRepository _repository;

  // Statistics data
  DashboardStatistics? _dashboardStats;
  FinancialStatisticsApi? _apiFinancialStats;
  FinancialSummaryDto? _originalSummaryDto;

  // Date range state
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  // Loading state
  bool _isLoading = false;
  AppError? _error;

  StatisticsStateProvider(this._repository) : super(null);

  // Getters
  DashboardStatistics? get dashboardStats => _dashboardStats;
  FinancialStatisticsApi? get apiFinancialStats => _apiFinancialStats;
  FinancialStatistics? get statisticsUiModel => state;
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  bool get isLoading => _isLoading;
  AppError? get error => _error;

  static final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
  String get formattedStartDate => dateFormat.format(_startDate);
  String get formattedEndDate => dateFormat.format(_endDate);

  /// Load dashboard statistics
  Future<void> loadDashboardStatistics({bool forceRefresh = false}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint('StatisticsStateProvider: Loading dashboard statistics...');
      _dashboardStats = await _repository.getDashboardStatistics(
        forceRefresh: forceRefresh,
      );
      debugPrint(
        'StatisticsStateProvider: Dashboard statistics loaded successfully',
      );
    } catch (e, stackTrace) {
      _error = AppError.fromException(e, stackTrace);
      debugPrint(
        'StatisticsStateProvider: Error loading dashboard statistics: $e',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load financial statistics for the current date range
  Future<void> loadFinancialStatistics({
    DateTime? startDate,
    DateTime? endDate,
    bool forceRefresh = false,
  }) async {
    final effectiveStartDate = startDate ?? _startDate;
    final effectiveEndDate = endDate ?? _endDate;

    debugPrint(
      'StatisticsStateProvider: Loading financial statistics for range: ${dateFormat.format(effectiveStartDate)} to ${dateFormat.format(effectiveEndDate)}',
    );

    _startDate = effectiveStartDate;
    _endDate = effectiveEndDate;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Get both the original DTO and converted API model
      _originalSummaryDto = await _repository.getFinancialSummaryDto(
        startDate: effectiveStartDate,
        endDate: effectiveEndDate,
        forceRefresh: forceRefresh,
      );

      _apiFinancialStats = FinancialStatisticsApi.fromSummaryDto(
        _originalSummaryDto!,
      );

      final statisticsUiModel = _repository.convertToUiModel(
        _apiFinancialStats,
        _originalSummaryDto,
        effectiveStartDate,
        effectiveEndDate,
      );

      // Update the state
      updateState(statisticsUiModel);

      debugPrint(
        'StatisticsStateProvider: Financial statistics loaded successfully',
      );
    } catch (e, stackTrace) {
      _error = AppError.fromException(e, stackTrace);
      debugPrint(
        'StatisticsStateProvider: Error loading financial statistics: $e',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set date range and immediately fetch fresh data
  Future<void> setDateRangeAndFetch(DateTime start, DateTime end) async {
    debugPrint(
      'StatisticsStateProvider: Date range changed from ${dateFormat.format(_startDate)}-${dateFormat.format(_endDate)} to ${dateFormat.format(start)}-${dateFormat.format(end)}',
    );

    // Always update dates and fetch fresh data
    _startDate = start;
    _endDate = end;

    // Force fresh data fetch
    await loadFinancialStatistics(
      startDate: start,
      endDate: end,
      forceRefresh: true,
    );

    debugPrint(
      'StatisticsStateProvider: Notified listeners after date range change and data fetch',
    );
  }

  /// Refresh all statistics data
  Future<void> refreshAllData() async {
    await Future.wait([
      loadDashboardStatistics(forceRefresh: true),
      loadFinancialStatistics(forceRefresh: true),
    ]);
  }

  /// Clear cached statistics data
  Future<void> clearCache() async {
    await _repository.clearCache();
    debugPrint('StatisticsStateProvider: Cache cleared');
  }

  @override
  String get debugName => 'StatisticsState';
}
