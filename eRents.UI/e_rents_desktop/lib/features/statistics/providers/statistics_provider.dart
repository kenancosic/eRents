import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/models/statistics/financial_statistics.dart';
import 'package:e_rents_desktop/models/statistics/maintenance_statistics.dart';
import 'package:e_rents_desktop/models/statistics/occupancy_statistics.dart';
import 'package:e_rents_desktop/models/statistics/tenant_statistics.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/services/mock_data_service.dart';

class StatisticsProvider extends BaseProvider<Map<String, dynamic>> {
  final ApiService _apiService;
  List<Map<String, dynamic>> _statistics = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<Map<String, dynamic>> get statistics => _statistics;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  StatisticsProvider(this._apiService) : super(_apiService) {
    enableMockData();
  }

  @override
  String get endpoint => '';

  @override
  Map<String, dynamic> fromJson(Map<String, dynamic> json) => json;

  @override
  Map<String, dynamic> toJson(Map<String, dynamic> item) => item;

  @override
  List<Map<String, dynamic>> getMockItems() => [];

  List<FinancialStatistics> getMockFinancialStatistics() =>
      MockDataService.getMockFinancialStatistics();

  List<OccupancyStatistics> getMockOccupancyStatistics() =>
      MockDataService.getMockOccupancyStatistics();

  List<MaintenanceStatistics> getMockMaintenanceStatistics() =>
      MockDataService.getMockMaintenanceStatistics();

  List<TenantStatistics> getMockTenantStatistics() =>
      MockDataService.getMockTenantStatistics();
}
