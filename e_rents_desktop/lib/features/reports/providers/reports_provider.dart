import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/base/api_service_extensions.dart';
import 'package:intl/intl.dart';

enum ReportType { financial } // Only financial reports for desktop

class ReportsProvider extends BaseProvider {
  ReportsProvider(super.api);

  // ─── State (standardized per playbook) ─────────────────────────────────
  ReportType _currentReportType = ReportType.financial;
  ReportType get currentReportType => _currentReportType;

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime get startDate => _startDate;

  DateTime _endDate = DateTime.now();
  DateTime get endDate => _endDate;

  // Filters/sort/paging scaffold for future expansion
  Map<String, dynamic> _filters = {};
  String? _sortBy;
  final bool _ascending = true;
  final int _page = 1;
  final int _pageSize = 50;
  Map<String, dynamic> get filters => _filters;
  String? get sortBy => _sortBy;
  bool get ascending => _ascending;
  int get page => _page;
  int get pageSize => _pageSize;
  Map<String, dynamic> get lastQuery => {
    ..._filters,
    if (_sortBy != null) 'sortBy': _sortBy,
    'ascending': _ascending,
    'page': _page,
    'pageSize': _pageSize,
    'from': _startDate.toIso8601String(),
    'to': _endDate.toIso8601String(),
  };

  // Store raw map data for financial reports
  List<Map<String, dynamic>> _financialReports = [];
  List<Map<String, dynamic>> get financialReports => _financialReports;

  // ─── Public API ─────────────────────────────────────────────────────────

  Future<void> setReportType(ReportType type) async {
    if (_currentReportType == type) return;
    _currentReportType = type;
    notifyListeners();
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

    await executeWithState<List<Map<String, dynamic>>>(() async {
      if (_currentReportType == ReportType.financial) {
        final result = await api.getListAndDecode<Map<String, dynamic>>(
          endpoint,
          (data) => data,
          authenticated: true,
        );
        _financialReports = result;
      }
      return _financialReports;
    });
  }

  // ─── Helpers & Private Methods ────────────────────────────────────────

  String _buildReportEndpoint(String type, DateTime start, DateTime end) =>
      'reports/$type?from=${start.toIso8601String()}&to=${end.toIso8601String()}';

  List<dynamic> get currentReports {
    switch (_currentReportType) {
      case ReportType.financial:
        return _financialReports;
    }
  }

  // Filter helpers for future UI
  void applyFilters(Map<String, dynamic> map) {
    _filters = {..._filters, ...map};
    notifyListeners();
  }

  void clearFilters() {
    _filters = {};
    notifyListeners();
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
