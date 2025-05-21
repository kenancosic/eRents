import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/models/statistics/financial_statistics.dart'
    as ui_model;
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/services/mock_data_service.dart';
import 'package:e_rents_desktop/services/statistics_service.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class StatisticsProvider extends BaseProvider<ui_model.FinancialStatistics> {
  final StatisticsService _statisticsService;

  // For the new API data
  DashboardStatistics? _dashboardStats;
  FinancialStatistics? _apiFinancialStats;

  // For compatibility with existing UI
  ui_model.FinancialStatistics? _statistics;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  StatisticsProvider(ApiService apiService, this._statisticsService)
    : super(apiService);

  // Required abstract method implementations
  @override
  String get endpoint => 'Statistics/financial';

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
    return [MockDataService.getMockFinancialStatistics(_startDate, _endDate)];
  }

  // Getters for API models
  DashboardStatistics? get dashboardStats => _dashboardStats;
  FinancialStatistics? get apiFinancialStats => _apiFinancialStats;

  // Getters for UI models (for backward compatibility)
  ui_model.FinancialStatistics? get statistics => _statistics;
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;

  // Common date format
  static final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
  String get formattedStartDate => dateFormat.format(_startDate);
  String get formattedEndDate => dateFormat.format(_endDate);

  // Load dashboard statistics from API
  Future<void> loadDashboardStatistics() async {
    await execute(() async {
      _dashboardStats = await _statisticsService.getDashboardStatistics();
    });
  }

  // Load financial statistics from API
  Future<void> loadFinancialStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final effectiveStartDate = startDate ?? _startDate;
    final effectiveEndDate = endDate ?? _endDate;

    // Update the date range
    _startDate = effectiveStartDate;
    _endDate = effectiveEndDate;

    await execute(() async {
      _apiFinancialStats = await _statisticsService.getFinancialStatistics(
        startDate: effectiveStartDate,
        endDate: effectiveEndDate,
      );

      // Convert API model to UI model for backward compatibility
      _statistics = _convertToExistingModel(_apiFinancialStats);
    });
  }

  // For backward compatibility - convert API model to existing UI model
  ui_model.FinancialStatistics _convertToExistingModel(
    FinancialStatistics? apiStats,
  ) {
    if (apiStats == null) {
      return ui_model.FinancialStatistics(
        totalRent: 0,
        totalMaintenanceCosts: 0,
        netTotal: 0,
        startDate: _startDate,
        endDate: _endDate,
      );
    }

    // Simple conversion - in a real app you'd map more fields
    return ui_model.FinancialStatistics(
      totalRent: apiStats.currentMonthRevenue,
      totalMaintenanceCosts: 0, // Not available in API model
      netTotal: apiStats.currentMonthRevenue,
      startDate: _startDate,
      endDate: _endDate,
      // Map monthly breakdown if needed
    );
  }

  // For backward compatibility with existing code
  Future<void> setDateRange(DateTime start, DateTime end) async {
    _startDate = start;
    _endDate = end;
    notifyListeners();

    // Load new data with the updated date range
    await loadFinancialStatistics(startDate: start, endDate: end);
  }

  // For backward compatibility with existing mock data
  ui_model.FinancialStatistics getMockData() {
    return MockDataService.getMockFinancialStatistics(_startDate, _endDate);
  }
}
