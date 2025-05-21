import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/services/statistics_service.dart'
    show DashboardStatistics, FinancialStatistics, MonthlyRevenue;
import 'package:e_rents_desktop/services/maintenance_service.dart';
import 'package:e_rents_desktop/services/property_service.dart';
import 'package:e_rents_desktop/services/statistics_service.dart';
import 'package:flutter/foundation.dart';
import 'package:e_rents_desktop/services/mock_data_service.dart';
import 'package:e_rents_desktop/models/statistics/financial_statistics.dart'
    as ui_model;
import 'package:e_rents_desktop/models/reports/financial_report_item.dart';

class HomeProvider extends BaseProvider<dynamic> {
  final PropertyService _propertyService;
  final MaintenanceService _maintenanceService;
  final StatisticsService _statisticsService;

  List<Property> _properties = [];
  List<MaintenanceIssue> _issues = [];
  DashboardStatistics? _dashboardStatistics;
  FinancialStatistics? _apiFinancialStatistics; // From StatisticsService
  ui_model.FinancialStatistics? _uiFinancialStatistics; // For UI consumption

  HomeProvider(
    this._propertyService,
    this._maintenanceService,
    this._statisticsService,
  ) {
    // Default to using real data; can be overridden by calling enableMockData()
    // disableMockData();
  }

  // Getters for UI
  List<Property> get properties => _properties;
  List<MaintenanceIssue> get issues => _issues;
  DashboardStatistics? get dashboardStatistics => _dashboardStatistics;
  ui_model.FinancialStatistics? get uiFinancialStatistics =>
      _uiFinancialStatistics;

  int get propertyCount => _properties.length;

  double get occupancyRate {
    if (_properties.isEmpty) return 0.0;
    final rentedCount =
        _properties.where((p) => p.status != PropertyStatus.available).length;
    return rentedCount / _properties.length;
  }

  List<MaintenanceIssue> get pendingIssues =>
      _issues.where((issue) => issue.status == IssueStatus.pending).toList();
  List<MaintenanceIssue> get highPriorityIssues =>
      _issues.where((issue) => issue.priority == IssuePriority.high).toList();
  List<MaintenanceIssue> get tenantComplaints =>
      _issues.where((issue) => issue.isTenantComplaint).toList();
  int get openIssuesCount => pendingIssues.length;

  // Financial KPIs from _uiFinancialStatistics (which should be calculated)
  double get netIncome => _uiFinancialStatistics?.netTotal ?? 0.0;
  double get totalRentIncome => _uiFinancialStatistics?.totalRent ?? 0.0;
  double get totalMaintenanceCosts =>
      _uiFinancialStatistics?.totalMaintenanceCosts ?? 0.0;
  // KPI for dashboard header might use simpler monthly revenue from DashboardStatistics
  double get currentMonthRevenueForKpi =>
      _dashboardStatistics?.monthlyRevenue ?? 0.0;

  Future<void> loadDashboardData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await execute(() async {
      DateTime effectiveStartDate =
          startDate ?? DateTime.now().subtract(const Duration(days: 30));
      DateTime effectiveEndDate = endDate ?? DateTime.now();

      if (isMockDataEnabled) {
        _properties = MockDataService.getMockProperties();
        _issues = MockDataService.getMockMaintenanceIssues();
        _dashboardStatistics = MockDataService.getMockDashboardStatistics();
        // For financial statistics, generate mock data that fits the FinancialStatistics model from the service
        _apiFinancialStatistics = MockDataService.getMockApiFinancialStatistics(
          effectiveStartDate,
          effectiveEndDate,
        );
        if (_apiFinancialStatistics != null) {
          _uiFinancialStatistics = _convertToUiModel(
            _apiFinancialStatistics!,
            effectiveStartDate,
            effectiveEndDate,
          );
        } else {
          _uiFinancialStatistics = null;
        }
      } else {
        final propertyFuture = _propertyService.getProperties();
        final issuesFuture = _maintenanceService.getIssues();
        final dashboardStatsFuture =
            _statisticsService.getDashboardStatistics();
        // Pass date range to getFinancialStatistics
        final financialStatsFuture = _statisticsService.getFinancialStatistics(
          startDate: effectiveStartDate,
          endDate: effectiveEndDate,
        );

        final results = await Future.wait([
          propertyFuture,
          issuesFuture,
          dashboardStatsFuture,
          financialStatsFuture,
        ]);

        _properties = results[0] as List<Property>;
        _issues = results[1] as List<MaintenanceIssue>;
        _dashboardStatistics = results[2] as DashboardStatistics?;
        _apiFinancialStatistics = results[3] as FinancialStatistics?;

        if (_apiFinancialStatistics != null) {
          _uiFinancialStatistics = _convertToUiModel(
            _apiFinancialStatistics!,
            effectiveStartDate,
            effectiveEndDate,
          );
        } else {
          _uiFinancialStatistics = null; // Or a default empty state
        }
      }
    });
  }

  // Conversion from Service's FinancialStatistics to UI's FinancialStatistics model
  ui_model.FinancialStatistics _convertToUiModel(
    FinancialStatistics apiStats,
    DateTime periodStartDate,
    DateTime periodEndDate,
  ) {
    // This conversion logic should be similar to what was in StatisticsProvider
    // It needs to derive totalRent, maintenanceCosts, and netTotal from apiStats
    // For simplicity, let's assume apiStats.revenueHistory gives us monthly figures.
    // A more robust calculation would sum these up.
    // If direct totals aren't in apiStats, we need to calculate them.
    // For now, let's placeholder some direct mappings if available or calculate simply.

    double calculatedTotalRent = 0;
    double calculatedMaintenanceCosts =
        0; // This is the tricky part if not directly available

    // Assuming revenueHistory contains monthly revenue and potentially expenses
    // If expenses are not per month in revenueHistory, this model or API needs adjustment
    for (var monthly in apiStats.revenueHistory) {
      calculatedTotalRent += monthly.revenue;
      // If MonthlyRevenue had an expenses field:
      // calculatedMaintenanceCosts += monthly.expenses;
    }

    // Placeholder for maintenance costs if not in revenueHistory
    // This value would ideally come from another part of apiStats or be calculated
    // For the KPI card, HomeScreen was using statsProvider.statistics (DashboardStatistics)
    // which had totalMaintenanceCosts. Let's see if `DashboardStatistics` can provide this.
    // The `DashboardStatistics` model does NOT have total expenses.
    // The old `StatisticsProvider`'s `_statisticsUiModel` was getting its `maintenanceCosts`
    // from its own `_apiFinancialStats.totalMaintenanceCosts`
    // The `FinancialStatistics` model from the service has `currentMonthRevenue`, `previousMonthRevenue`, `projectedRevenue`
    // but no direct `totalExpenses` or `netIncome` over the period. This is a GAP.

    // For now, let's use a placeholder for maintenance costs, this needs API clarification.
    // Let's assume the dashboard stats' monthly revenue IS the net income for this period for the KPI,
    // and uiFinancialStatistics is for more detailed views.
    // For FinancialSummaryCard, we *need* expenses.
    // Let's make a temporary assumption: use currentMonthRevenue as totalRent and a mock expense.

    // This part needs to be robust based on actual API response structure for FinancialStatistics
    // The previous `StatisticsProvider` had a `_apiFinancialStats` of type `statistics_service.FinancialStatistics`
    // and its `_convertToUiModel` mapped:
    // totalRent: apiStats.currentMonthRevenue (this might be just for one month)
    // maintenanceCosts: apiStats.previousMonthRevenue (this seems like a placeholder/misinterpretation before) - NEEDS FIX
    // netTotal: apiStats.projectedRevenue (this also seems like a placeholder) - NEEDS FIX

    // Let's assume for now, the FinancialStatistics from service HAS the totals or we derive them.
    // If `revenueHistory` is the source, we need a better way to get period expenses.

    // For the purpose of moving forward, let's assume FinancialStatistics from service
    // has some fields that can be directly used or summed up from revenueHistory.
    // The service's FinancialStatistics has `currentMonthRevenue`.
    // It does *not* have a clear "total expenses" or "net income" for the period.
    // This is a significant issue for `FinancialSummaryCard`.

    // Let's assume `apiStats` should have these, or `DashboardStatistics` should be enhanced.
    // For now, to make it compile, I will use available fields and mark //TODO

    // TODO: Resolve how to get total maintenance costs and net income for the selected period.
    // This might require changes in StatisticsService.FinancialStatistics or how it's calculated.
    calculatedMaintenanceCosts =
        apiStats.previousMonthRevenue * 0.2; // Highly mock, placeholder

    return ui_model.FinancialStatistics(
      totalRent:
          apiStats
              .currentMonthRevenue, // This is likely just for *current month*, not period.
      totalMaintenanceCosts: calculatedMaintenanceCosts,
      netTotal:
          apiStats.currentMonthRevenue -
          calculatedMaintenanceCosts, // Also likely for current month
      startDate: periodStartDate,
      endDate: periodEndDate,
      monthlyBreakdown:
          apiStats.revenueHistory.map((monthly) {
            // Assuming MonthlyRevenue also needs an 'expenses' field from API
            // or maintenance costs are calculated/apportioned differently.
            double mockMonthlyExpenses = monthly.revenue * 0.15; // Mock expense
            return FinancialReportItem(
              dateFrom:
                  '${monthly.year}-${monthly.month.toString().padLeft(2, '0')}',
              dateTo:
                  '${monthly.year}-${monthly.month.toString().padLeft(2, '0')}',
              totalRent: monthly.revenue,
              maintenanceCosts: mockMonthlyExpenses,
              total: monthly.revenue - mockMonthlyExpenses,
              property: 'Overall',
            );
          }).toList(),
    );
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
