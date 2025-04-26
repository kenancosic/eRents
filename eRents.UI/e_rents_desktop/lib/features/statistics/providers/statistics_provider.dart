import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/models/statistics/financial_statistics.dart';
import 'package:e_rents_desktop/services/mock_data_service.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class StatisticsProvider extends BaseProvider<FinancialStatistics> {
  FinancialStatistics? _statistics;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  FinancialStatistics? get statistics => _statistics;
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;

  // Common date format
  static final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
  String get formattedStartDate => dateFormat.format(_startDate);
  String get formattedEndDate => dateFormat.format(_endDate);

  StatisticsProvider() {
    enableMockData();
    fetchItems();
  }

  @override
  String get endpoint => 'api/statistics/financial';

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
    return [MockDataService.getMockFinancialStatistics(_startDate, _endDate)];
  }

  @override
  Future<void> fetchItems() async {
    await execute(() async {
      _statistics = MockDataService.getMockFinancialStatistics(
        _startDate,
        _endDate,
      );
      items_ = _statistics != null ? [_statistics!] : [];
    });
  }

  void setDateRange(DateTime start, DateTime end) {
    debugPrint(
      "StatisticsProvider.setDateRange: from ${dateFormat.format(start)} to ${dateFormat.format(end)}",
    );
    _startDate = start;
    _endDate = end;
    fetchItems();
  }
}
