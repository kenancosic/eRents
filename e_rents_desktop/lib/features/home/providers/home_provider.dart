import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/services/statistics_service.dart'
    show DashboardStatistics, FinancialStatistics, MonthlyRevenue;
import 'package:e_rents_desktop/services/maintenance_service.dart';
import 'package:e_rents_desktop/services/property_service.dart';
import 'package:e_rents_desktop/services/statistics_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Added for IconData
import 'package:e_rents_desktop/services/mock_data_service.dart';
import 'package:e_rents_desktop/models/statistics/financial_statistics.dart'
    as ui_model;
import 'package:e_rents_desktop/models/reports/financial_report_item.dart';
import 'package:e_rents_desktop/models/recent_activity.dart'; // Added

class HomeProvider extends BaseProvider<dynamic> {
  final PropertyService _propertyService;
  final MaintenanceService _maintenanceService;
  final StatisticsService _statisticsService;

  List<Property> _properties = [];
  List<MaintenanceIssue> _issues = [];
  DashboardStatistics? _dashboardStatistics;
  FinancialStatistics? _apiFinancialStatistics; // From StatisticsService
  ui_model.FinancialStatistics? _uiFinancialStatistics; // For UI consumption
  List<RecentActivity> _recentActivities = []; // Added

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
  List<RecentActivity> get recentActivities => _recentActivities; // Added

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

  Future<void> _fetchRecentActivity() async {
    if (isMockDataEnabled) {
      _recentActivities = MockDataService.getMockRecentActivities();
    } else {
      // Fetch top 5 high priority or pending issues
      final urgentIssues =
          _issues
              .where(
                (issue) =>
                    issue.priority == IssuePriority.high ||
                    issue.status == IssueStatus.pending,
              )
              .toList();
      urgentIssues.sort(
        (a, b) => b.createdAt.compareTo(a.createdAt),
      ); // Sort by newest first

      _recentActivities =
          urgentIssues.take(5).map((issue) {
            IconData icon;
            String subtitle;
            switch (issue.status) {
              case IssueStatus.pending:
                icon = Icons.pending_actions_outlined;
                subtitle =
                    'Status: Pending. Reported on ${issue.createdAt.toLocal().toString().split(' ').first}';
                break;
              case IssueStatus.inProgress:
                icon = Icons.construction_outlined;
                subtitle =
                    'Status: In Progress. Started on ${issue.createdAt.toLocal().toString().split(' ').first}';
                break;
              default:
                icon = Icons.error_outline;
                subtitle =
                    'Status: ${issue.status.name}. Priority: ${issue.priority.name}';
            }
            if (issue.priority == IssuePriority.high &&
                issue.status != IssueStatus.completed &&
                issue.status != IssueStatus.cancelled) {
              icon = Icons.warning_amber_rounded;
              subtitle = 'HIGH PRIORITY: ${subtitle}';
            }

            return RecentActivity(
              id: issue.id,
              type: ActivityType.maintenance,
              title: issue.title,
              subtitle: subtitle,
              date: issue.createdAt,
              icon: icon,
              onTapRoute: '/maintenance/${issue.id}',
            );
          }).toList();
    }
    // Add a system notification for testing
    // _recentActivities.add(RecentActivity(
    //   id: 'system-1',
    //   type: ActivityType.system,
    //   title: 'System Update Available',
    //   subtitle: 'A new version of the app is ready to be installed.',
    //   date: DateTime.now().subtract(Duration(hours: 2)),
    //   icon: Icons.system_update_alt,
    // ));

    // Sort all activities by date, newest first
    _recentActivities.sort((a, b) => b.date.compareTo(a.date));
  }

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
        _apiFinancialStatistics = MockDataService.getMockApiFinancialStatistics(
          effectiveStartDate,
          effectiveEndDate,
        );
        if (_apiFinancialStatistics != null) {
          _uiFinancialStatistics = _convertToUiModel(
            _apiFinancialStatistics!,
            _issues, // Pass issues for cost calculation
            effectiveStartDate,
            effectiveEndDate,
          );
        } else {
          _uiFinancialStatistics = null;
        }
        await _fetchRecentActivity(); // Fetch recent activity
      } else {
        final propertyFuture = _propertyService.getProperties();
        // Fetch issues, potentially filtered by date range if API supports it
        // For now, fetching all issues and will filter locally if needed for recent activity.
        final issuesFuture = _maintenanceService.getIssues();
        final dashboardStatsFuture =
            _statisticsService.getDashboardStatistics();
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
            _issues, // Pass all fetched issues
            effectiveStartDate,
            effectiveEndDate,
          );
        } else {
          _uiFinancialStatistics = null;
        }
        await _fetchRecentActivity(); // Fetch recent activity
      }
    });
  }

  ui_model.FinancialStatistics _convertToUiModel(
    FinancialStatistics apiStats,
    List<MaintenanceIssue> allIssues, // Changed to accept all issues
    DateTime periodStartDate,
    DateTime periodEndDate,
  ) {
    // Use monthlyRevenue from DashboardStatistics as total income for the period
    // This assumes dashboardStatistics is already populated and relevant for the period.
    double periodTotalRent = _dashboardStatistics?.monthlyRevenue ?? 0.0;

    // Calculate total maintenance costs for the period from the provided issues
    double periodMaintenanceCosts = allIssues
        .where(
          (issue) =>
              issue.cost != null &&
              issue.resolvedAt !=
                  null && // Consider only resolved issues with costs
              !issue.resolvedAt!.isBefore(periodStartDate) &&
              !issue.resolvedAt!.isAfter(periodEndDate),
        )
        .fold(0.0, (sum, issue) => sum + (issue.cost ?? 0.0));

    // If no resolved issues in period, but we have currentMonthRevenue,
    // it's hard to give a meaningful "expense" for the FinancialSummaryCard for that period.
    // The _apiFinancialStatistics.currentMonthRevenue seems to be the total revenue for the current month.
    // And _apiFinancialStatistics.previousMonthRevenue for the previous.
    // For FinancialSummaryCard, we need income & expense for the *selected period*.
    // Let's use currentMonthRevenue from apiStats as income if available,
    // and filter issues for costs within that month.

    // For FinancialSummaryCard, Income should be current month's gross revenue.
    // Expenses should be maintenance costs for current month.
    // Net profit = Income - Expenses.

    // Use currentMonthRevenue from apiStats (which is FinancialStatistics from service)
    // This is typically for THE current calendar month.
    final double currentMonthGrossRevenue = apiStats.currentMonthRevenue;

    // Calculate maintenance costs specifically for the current month
    final DateTime now = DateTime.now();
    final DateTime startOfCurrentMonth = DateTime(now.year, now.month, 1);
    final DateTime endOfCurrentMonth = DateTime(
      now.year,
      now.month + 1,
      0,
    ); // Last day of current month

    double currentMonthMaintenanceCosts = allIssues
        .where(
          (issue) =>
              issue.cost != null &&
              issue.resolvedAt != null &&
              !issue.resolvedAt!.isBefore(startOfCurrentMonth) &&
              !issue.resolvedAt!.isAfter(endOfCurrentMonth),
        )
        .fold(0.0, (sum, issue) => sum + (issue.cost ?? 0.0));

    // Monthly breakdown should still use the revenueHistory from apiStats
    List<FinancialReportItem> monthlyBreakdown =
        apiStats.revenueHistory.map((monthly) {
          // For monthly breakdown, we'd ideally have expenses per month from API.
          // For now, we'll show revenue only, or a mock expense.
          double mockMonthlyExpenses =
              monthly.revenue * 0.15; // Mock expense, as before
          return FinancialReportItem(
            dateFrom:
                '${monthly.year}-${monthly.month.toString().padLeft(2, '0')}',
            dateTo:
                '${monthly.year}-${monthly.month.toString().padLeft(2, '0')}',
            totalRent: monthly.revenue,
            maintenanceCosts:
                mockMonthlyExpenses, // This is still a placeholder.
            total: monthly.revenue - mockMonthlyExpenses,
            property: 'Overall',
          );
        }).toList();

    // The ui_model.FinancialStatistics for the FinancialSummaryCard should reflect current month's snapshot
    return ui_model.FinancialStatistics(
      totalRent: currentMonthGrossRevenue,
      totalMaintenanceCosts: currentMonthMaintenanceCosts,
      netTotal: currentMonthGrossRevenue - currentMonthMaintenanceCosts,
      startDate: startOfCurrentMonth, // Reflects this is for the current month
      endDate: endOfCurrentMonth, // Reflects this is for the current month
      monthlyBreakdown:
          monthlyBreakdown, // This covers the history for other charts/views if needed
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
