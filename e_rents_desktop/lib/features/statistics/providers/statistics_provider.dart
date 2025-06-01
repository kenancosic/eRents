import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/models/reports/financial_report_item.dart';
import 'package:e_rents_desktop/models/statistics/financial_statistics.dart';
import 'package:e_rents_desktop/models/statistics/financial_statistics_api.dart';
import 'package:e_rents_desktop/models/statistics/financial_summary_dto.dart';
import 'package:e_rents_desktop/models/statistics/dashboard_statistics.dart';
// import 'package:e_rents_desktop/services/mock_data_service.dart'; // To be removed
import 'package:e_rents_desktop/services/statistics_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class StatisticsProvider extends BaseProvider<FinancialStatistics> {
  final StatisticsService _statisticsService;

  DashboardStatistics? _dashboardStats;
  FinancialStatisticsApi? _apiFinancialStats;
  FinancialSummaryDto?
  _originalSummaryDto; // Store original data for total calculations

  FinancialStatistics? _statisticsUiModel;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  StatisticsProvider(this._statisticsService) : super();

  DashboardStatistics? get dashboardStats => _dashboardStats;
  FinancialStatisticsApi? get apiFinancialStats => _apiFinancialStats;

  FinancialStatistics? get statisticsUiModel => _statisticsUiModel;

  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;

  static final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
  String get formattedStartDate => dateFormat.format(_startDate);
  String get formattedEndDate => dateFormat.format(_endDate);

  Future<void> loadDashboardStatistics() async {
    await execute(() async {
      debugPrint('StatisticsProvider: Loading dashboard statistics...');
      _dashboardStats = await _statisticsService.getDashboardStatistics();
      debugPrint(
        'StatisticsProvider: Dashboard statistics loaded successfully',
      );
    });
  }

  Future<void> loadFinancialStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final effectiveStartDate = startDate ?? _startDate;
    final effectiveEndDate = endDate ?? _endDate;

    debugPrint(
      'StatisticsProvider: Loading financial statistics for range: ${dateFormat.format(effectiveStartDate)} to ${dateFormat.format(effectiveEndDate)}',
    );

    _startDate = effectiveStartDate;
    _endDate = effectiveEndDate;

    await execute(() async {
      // Get both the original DTO and converted API model
      _originalSummaryDto = await _statisticsService.getFinancialSummaryDto(
        startDate: effectiveStartDate,
        endDate: effectiveEndDate,
      );

      _apiFinancialStats = FinancialStatisticsApi.fromSummaryDto(
        _originalSummaryDto!,
      );

      _statisticsUiModel = _convertToUiModel(_apiFinancialStats);
      if (_statisticsUiModel != null) {
        items_ = [_statisticsUiModel!];
      } else {
        items_ = [];
      }

      // Explicitly notify listeners after data update
      notifyListeners();
      debugPrint(
        'StatisticsProvider: Financial statistics loaded successfully, notified listeners',
      );
    });
  }

  FinancialStatistics? _convertToUiModel(FinancialStatisticsApi? apiStats) {
    if (apiStats == null || _originalSummaryDto == null) {
      return FinancialStatistics(
        totalRent: 0,
        totalMaintenanceCosts: 0,
        netTotal: 0,
        startDate: _startDate,
        endDate: _endDate,
        monthlyBreakdown: [],
      );
    }

    // Get maintenance costs from the original DTO
    double totalMaintenanceCosts = _originalSummaryDto!.totalMaintenanceCosts;

    List<FinancialReportItem> monthlyBreakdownUi = [];
    if (apiStats.revenueHistory.isNotEmpty) {
      // Create a map for quick lookup of maintenance costs by month
      Map<String, double> monthlyMaintenanceMap = {};
      for (var monthlyDto in _originalSummaryDto!.revenueHistory) {
        String key = '${monthlyDto.year}-${monthlyDto.month}';
        monthlyMaintenanceMap[key] = monthlyDto.maintenanceCosts;
      }

      monthlyBreakdownUi =
          apiStats.revenueHistory.map((monthlyRevenue) {
            final monthDate = DateTime(
              monthlyRevenue.year,
              monthlyRevenue.month,
              1,
            );
            final firstDayOfMonth = DateFormat('dd/MM/yyyy').format(monthDate);
            final lastDayOfMonth = DateFormat('dd/MM/yyyy').format(
              DateTime(monthlyRevenue.year, monthlyRevenue.month + 1, 0),
            );

            // Get maintenance costs for this month
            String monthKey = '${monthlyRevenue.year}-${monthlyRevenue.month}';
            double monthlyMaintenance = monthlyMaintenanceMap[monthKey] ?? 0.0;

            return FinancialReportItem(
              dateFrom: firstDayOfMonth,
              dateTo: lastDayOfMonth,
              property: 'Monthly Total',
              totalRent: monthlyRevenue.revenue,
              maintenanceCosts: monthlyMaintenance,
              total: monthlyRevenue.revenue - monthlyMaintenance,
            );
          }).toList();
    }

    // Use total rent from the original DTO for accuracy
    double calculatedTotalRent = _originalSummaryDto!.totalRentIncome;

    return FinancialStatistics(
      totalRent: calculatedTotalRent,
      totalMaintenanceCosts: totalMaintenanceCosts,
      netTotal: _originalSummaryDto!.netTotal,
      startDate: _startDate,
      endDate: _endDate,
      monthlyBreakdown: monthlyBreakdownUi,
    );
  }

  /// Set date range and immediately fetch fresh data
  Future<void> setDateRangeAndFetch(DateTime start, DateTime end) async {
    debugPrint(
      'StatisticsProvider: Date range changed from ${dateFormat.format(_startDate)}-${dateFormat.format(_endDate)} to ${dateFormat.format(start)}-${dateFormat.format(end)}',
    );

    // Always update dates and fetch fresh data
    _startDate = start;
    _endDate = end;

    // Force fresh data fetch
    await loadFinancialStatistics(startDate: start, endDate: end);

    // Explicitly notify listeners after date range change and data update
    notifyListeners();
    debugPrint(
      'StatisticsProvider: Notified listeners after date range change and data fetch',
    );
  }

  @override
  String get endpoint => 'Statistics/financial_legacy_ui';

  @override
  FinancialStatistics fromJson(Map<String, dynamic> json) {
    return FinancialStatistics.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(FinancialStatistics item) {
    return item.toJson();
  }

  @override
  List<FinancialStatistics> getMockItems() {
    debugPrint(
      'StatisticsProvider: getMockItems() called. Backend integration is primary. Returning empty list as placeholder.',
    );
    return [];
  }
}
