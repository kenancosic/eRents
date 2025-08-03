import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/base/api_service_extensions.dart';
import 'package:intl/intl.dart';

enum ReportType { financial } // Only financial reports for desktop

class ReportsProvider extends BaseProvider {
  ReportsProvider(super.api);

  // ─── State ──────────────────────────────────────────────────────────────
  ReportType _currentReportType = ReportType.financial;
  ReportType get currentReportType => _currentReportType;

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime get startDate => _startDate;

  DateTime _endDate = DateTime.now();
  DateTime get endDate => _endDate;

  List<Map<String, dynamic>> _financialReports = []; // Store raw map data
  List<Map<String, dynamic>> get financialReports => _financialReports;

  // ─── Public API ─────────────────────────────────────────────────────────

  Future<void> setReportType(ReportType type) async {
    if (_currentReportType == type) return;
    _currentReportType = type;
    notifyListeners();
    // No need to fetch if it's already the financial type
    // If future types are added, this might need more logic
    if (currentReports.isEmpty) {
      await fetchCurrentReports();
    }
  }

  Future<void> setDateRange(DateTime startDate, DateTime endDate) async {
    if (_startDate == startDate && _endDate == endDate) return;
    _startDate = startDate;
    _endDate = endDate;
    await fetchCurrentReports(forceRefresh: true);
  }

  Future<void> fetchCurrentReports({bool forceRefresh = false}) async {
    final endpoint = _buildReportEndpoint(_currentReportType.name, _startDate, _endDate);

    await executeWithState(() async {
      if (_currentReportType == ReportType.financial) {
        final result = await api.getListAndDecode<Map<String, dynamic>>(
          endpoint, 
          (data) => data,
          authenticated: true,
        );
        _financialReports = result;
      }
    });
  }

  // ─── Helpers & Private Methods ────────────────────────────────────────

  String _buildReportEndpoint(String type, DateTime start, DateTime end) =>
      'reports/$type?from=${start.toIso8601String()}&to=${end.toIso8601String()}';

  List<dynamic> get currentReports {
    switch (_currentReportType) {
      case ReportType.financial: return _financialReports;
    }
  }

  static final DateFormat _displayDateFormat = DateFormat('dd/MM/yyyy');
  String get formattedStartDate => _displayDateFormat.format(_startDate);
  String get formattedEndDate => _displayDateFormat.format(_endDate);

  String get reportTitle {
    return 'Financial Report ($formattedStartDate - $formattedEndDate)';
  }

  bool get hasData => currentReports.isNotEmpty;
  bool get isExporting => isLoading;
}
