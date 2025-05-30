import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/models/reports/financial_report_item.dart';
import 'package:e_rents_desktop/models/statistics/financial_statistics.dart'
    as ui_model;
import 'package:e_rents_desktop/models/statistics/dashboard_statistics.dart';
// import 'package:e_rents_desktop/services/mock_data_service.dart'; // To be removed
import 'package:e_rents_desktop/services/statistics_service.dart';
import 'package:intl/intl.dart';

class StatisticsProvider extends BaseProvider<ui_model.FinancialStatistics> {
  final StatisticsService _statisticsService;

  DashboardStatistics? _dashboardStats;
  FinancialStatistics? _apiFinancialStats;

  ui_model.FinancialStatistics? _statisticsUiModel;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  StatisticsProvider(this._statisticsService) : super();

  DashboardStatistics? get dashboardStats => _dashboardStats;
  FinancialStatistics? get apiFinancialStats => _apiFinancialStats;

  ui_model.FinancialStatistics? get statisticsUiModel => _statisticsUiModel;

  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;

  static final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
  String get formattedStartDate => dateFormat.format(_startDate);
  String get formattedEndDate => dateFormat.format(_endDate);

  Future<void> loadDashboardStatistics() async {
    await execute(() async {
      _dashboardStats = await _statisticsService.getDashboardStatistics();
    });
  }

  Future<void> loadFinancialStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final effectiveStartDate = startDate ?? _startDate;
    final effectiveEndDate = endDate ?? _endDate;

    _startDate = effectiveStartDate;
    _endDate = effectiveEndDate;

    await execute(() async {
      _apiFinancialStats = await _statisticsService.getFinancialStatistics(
        startDate: effectiveStartDate,
        endDate: effectiveEndDate,
      );

      _statisticsUiModel = _convertToUiModel(_apiFinancialStats);
      if (_statisticsUiModel != null) {
        items_ = [_statisticsUiModel!];
      } else {
        items_ = [];
      }
    });
  }

  ui_model.FinancialStatistics? _convertToUiModel(
    FinancialStatistics? apiStats,
  ) {
    if (apiStats == null) {
      return ui_model.FinancialStatistics(
        totalRent: 0,
        totalMaintenanceCosts: 0,
        netTotal: 0,
        startDate: _startDate,
        endDate: _endDate,
        monthlyBreakdown: [],
      );
    }

    List<FinancialReportItem> monthlyBreakdownUi = [];
    if (apiStats.revenueHistory.isNotEmpty) {
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

            return FinancialReportItem(
              dateFrom: firstDayOfMonth,
              dateTo: lastDayOfMonth,
              property: 'Monthly Total',
              totalRent: monthlyRevenue.revenue,
              maintenanceCosts: 0,
              total: monthlyRevenue.revenue,
            );
          }).toList();
    }

    double calculatedTotalRent = apiStats.currentMonthRevenue;
    if (apiStats.revenueHistory.isNotEmpty) {
      calculatedTotalRent = apiStats.revenueHistory.fold(
        0.0,
        (sum, item) => sum + item.revenue,
      );
    }

    return ui_model.FinancialStatistics(
      totalRent: calculatedTotalRent,
      totalMaintenanceCosts: 0,
      netTotal: calculatedTotalRent,
      startDate: _startDate,
      endDate: _endDate,
      monthlyBreakdown: monthlyBreakdownUi,
    );
  }

  Future<void> setDateRangeAndFetch(DateTime start, DateTime end) async {
    _startDate = start;
    _endDate = end;
    await loadFinancialStatistics(startDate: start, endDate: end);
  }

  @override
  String get endpoint => 'Statistics/financial_legacy_ui';

  @override
  ui_model.FinancialStatistics fromJson(Map<String, dynamic> json) {
    return ui_model.FinancialStatistics.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(ui_model.FinancialStatistics item) {
    return item.toJson();
  }

  @override
  List<ui_model.FinancialStatistics> getMockItems() {
    print(
      'StatisticsProvider: getMockItems() called. Backend integration is primary. Returning empty list as placeholder.',
    );
    return [];
  }
}
