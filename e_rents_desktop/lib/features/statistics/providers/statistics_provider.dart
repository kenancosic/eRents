import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/base/api_service_extensions.dart';
import 'package:e_rents_desktop/models/reports/financial_report_item.dart';
import 'package:e_rents_desktop/models/statistics/dashboard_statistics.dart';
import 'package:e_rents_desktop/models/statistics/financial_statistics.dart';
import 'package:e_rents_desktop/models/statistics/financial_summary_dto.dart';
import 'package:intl/intl.dart';

class StatisticsProvider extends BaseProvider {
  StatisticsProvider(super.api);

  // ─── State ──────────────────────────────────────────────────────────────
  DashboardStatistics? _dashboardStats;
  DashboardStatistics? get dashboardStats => _dashboardStats;

  FinancialStatistics? _financialStats;
  FinancialStatistics? get financialStats => _financialStats;

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime get startDate => _startDate;

  DateTime _endDate = DateTime.now();
  DateTime get endDate => _endDate;

  static final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
  String get formattedStartDate => dateFormat.format(_startDate);
  String get formattedEndDate => dateFormat.format(_endDate);

  // ─── Public API ─────────────────────────────────────────────────────────

  Future<void> loadDashboardStatistics({bool forceRefresh = false}) async {
    const cacheKey = 'dashboard_stats';

    if (forceRefresh) {
      invalidateCache(cacheKey);
    }

    final result = await executeWithCache<DashboardStatistics>(
      cacheKey,
      () => api.getAndDecode(
        '/Statistics/dashboard',
        DashboardStatistics.fromJson,
        authenticated: true,
      ),
    );

    if (result != null) {
      _dashboardStats = result;
      notifyListeners();
    }
  }

  Future<void> loadFinancialStatistics({bool forceRefresh = false}) async {
    final cacheKey =
        'financial_stats_${_startDate.toIso8601String()}_${_endDate.toIso8601String()}';

    if (forceRefresh) {
      invalidateCache(cacheKey);
    }

    final result = await executeWithCache<FinancialSummaryDto>(
      cacheKey,
      () => api.postAndDecode(
        '/Statistics/financial',
        {
          'startDate': _startDate.toIso8601String(),
          'endDate': _endDate.toIso8601String(),
        },
        FinancialSummaryDto.fromJson,
        authenticated: true,
      ),
    );

    if (result != null) {
      _financialStats = _buildFinancialStatisticsUiModel(
        result,
        _startDate,
        _endDate,
      );
      notifyListeners();
    }
  }

  Future<void> setDateRangeAndFetch(DateTime start, DateTime end) async {
    _startDate = start;
    _endDate = end;
    await loadFinancialStatistics(forceRefresh: true);
  }

  Future<void> refreshAllData() async {
    final futureDashboard = loadDashboardStatistics(forceRefresh: true);
    final futureFinancial = loadFinancialStatistics(forceRefresh: true);
    await Future.wait([futureDashboard, futureFinancial]);
  }

  void clearAllCache() {
    invalidateCache('dashboard_stats');
    invalidateCache('financial_stats');
    _dashboardStats = null;
    _financialStats = null;
    notifyListeners();
  }

  // ─── Private Helpers ────────────────────────────────────────────────────

  FinancialStatistics _buildFinancialStatisticsUiModel(
    FinancialSummaryDto summaryDto,
    DateTime startDate,
    DateTime endDate,
  ) {
    return FinancialStatistics(
      totalRent: summaryDto.totalRentIncome,
      totalMaintenanceCosts: summaryDto.totalMaintenanceCosts,
      netTotal: summaryDto.netTotal,
      startDate: startDate,
      endDate: endDate,
      monthlyBreakdown:
          summaryDto.revenueHistory.map((monthly) {
            return FinancialReportItem(
              dateFrom: dateFormat.format(
                DateTime(monthly.year, monthly.month, 1),
              ),
              dateTo: dateFormat.format(
                DateTime(monthly.year, monthly.month + 1, 0),
              ),
              property: 'Monthly Total',
              totalRent: monthly.revenue,
              maintenanceCosts: monthly.maintenanceCosts,
              total: monthly.revenue - monthly.maintenanceCosts,
            );
          }).toList(),
    );
  }
}
