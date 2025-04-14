import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

/// Base class for all report providers that handles common date functionality
abstract class BaseReportProvider<T> extends BaseProvider<T> {
  // Date range for filtering/contextual information
  DateTime _startDate = DateTime(2023, 6, 1); // Using fixed date in 2023
  DateTime _endDate = DateTime(2023, 7, 31); // Using fixed date in 2023

  // Cache for report data
  final Map<String, List<T>> _cache = {};

  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;

  // Common date format
  static final DateFormat dateFormat = DateFormat('dd/MM/yyyy');

  // Constructor
  BaseReportProvider() {
    enableMockData(); // Use mock data by default
    debugPrint(
      "BaseReportProvider initialized with date range: ${dateFormat.format(_startDate)} to ${dateFormat.format(_endDate)}",
    );
  }

  // Get cache key for current date range
  String get _cacheKey =>
      '${dateFormat.format(_startDate)}-${dateFormat.format(_endDate)}';

  // Override the execute method to ensure proper state management
  @override
  Future<void> execute(Function action) async {
    try {
      setState(ViewState.Busy);
      clearError();
      await action();
      setState(ViewState.Idle);
    } catch (e) {
      debugPrint("BaseReportProvider execute error: $e");
      setError(e.toString());
    }
  }

  // Set date range
  void setDateRange(DateTime startDate, DateTime endDate) {
    debugPrint(
      "BaseReportProvider.setDateRange: from ${dateFormat.format(startDate)} to ${dateFormat.format(endDate)}",
    );
    _startDate = startDate;
    _endDate = endDate;
    onDateRangeChanged();
  }

  // Method to be overridden by subclasses if they need special behavior when date range changes
  void onDateRangeChanged() {
    debugPrint(
      "BaseReportProvider.onDateRangeChanged: Checking cache for data",
    );
    final cacheKey = _cacheKey;

    // Check if we have cached data for this date range
    if (_cache.containsKey(cacheKey)) {
      debugPrint("BaseReportProvider: Using cached data");
      items_ = _cache[cacheKey]!;
      notifyListeners();
    } else {
      debugPrint("BaseReportProvider: Fetching new data");
      fetchItems();
    }
  }

  // Override fetchItems to implement caching
  @override
  Future<void> fetchItems() async {
    await execute(() async {
      final data = await fetchReportData();
      items_ = data;
      _cache[_cacheKey] = data;
    });
  }

  // Abstract method to fetch report data - to be implemented by subclasses
  Future<List<T>> fetchReportData();

  // Get formatted dates
  String get formattedStartDate => dateFormat.format(_startDate);
  String get formattedEndDate => dateFormat.format(_endDate);

  // Get title with date range
  String getReportTitleWithDateRange() {
    return '${getReportName()} ($formattedStartDate - $formattedEndDate)';
  }

  // Abstract method to get report name - to be implemented by subclasses
  String getReportName();
}
