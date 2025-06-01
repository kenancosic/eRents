import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

/// Base class for all report providers that handles common date functionality
abstract class BaseReportProvider<T> extends BaseProvider<T> {
  // Date range for filtering/contextual information
  DateTime _startDate = DateTime.now().subtract(Duration(days: 30));
  DateTime _endDate = DateTime.now();

  // Cache for report data - keeping for future optimization but not blocking fresh data
  final Map<String, List<T>> _cache = {};

  // Flag to force refresh when date range changes
  bool _forceRefresh = false;

  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;

  // Common date format
  final DateFormat dateFormat = DateFormat('dd/MM/yyyy');

  // Constructor
  BaseReportProvider() : super() {
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

  // Set date range and ALWAYS fetch fresh data
  void setDateRange(DateTime startDate, DateTime endDate) {
    debugPrint(
      "BaseReportProvider.setDateRange: from ${dateFormat.format(startDate)} to ${dateFormat.format(endDate)}",
    );

    final oldCacheKey = _cacheKey;
    _startDate = startDate;
    _endDate = endDate;
    final newCacheKey = _cacheKey;

    // If date range actually changed, force refresh
    if (oldCacheKey != newCacheKey) {
      _forceRefresh = true;
      debugPrint("BaseReportProvider: Date range changed, forcing refresh");
    }

    onDateRangeChanged();
  }

  // Method to handle date range changes - now always fetches fresh data when date changes
  void onDateRangeChanged() {
    debugPrint(
      "BaseReportProvider.onDateRangeChanged: Checking cache for data",
    );
    final cacheKey = _cacheKey;

    // If we're forcing refresh OR no cached data exists, fetch fresh data
    if (_forceRefresh || !_cache.containsKey(cacheKey)) {
      debugPrint("BaseReportProvider: Fetching fresh data");
      _forceRefresh = false; // Reset flag
      fetchItems();
    } else {
      debugPrint(
        "BaseReportProvider: Using cached data with ${_cache[cacheKey]!.length} items",
      );
      items_ = _cache[cacheKey]!;
      notifyListeners();
      debugPrint(
        "BaseReportProvider: Notified listeners of cached data update",
      );
    }
  }

  // Override fetchItems to implement caching
  @override
  Future<void> fetchItems() async {
    await execute(() async {
      debugPrint(
        "BaseReportProvider.fetchItems: Calling fetchReportData for date range ${startDateFormatted} to ${endDateFormatted}",
      );
      final data = await fetchReportData();
      items_ = data;
      _cache[_cacheKey] = data;
      debugPrint(
        "BaseReportProvider.fetchItems: Successfully fetched ${data.length} items",
      );

      // Explicitly notify listeners after updating items
      notifyListeners();
      debugPrint(
        "BaseReportProvider.fetchItems: Notified listeners of data update",
      );
    });
  }

  // Abstract method to fetch report data - to be implemented by subclasses
  Future<List<T>> fetchReportData();

  // Formatted date getters
  String get startDateFormatted => dateFormat.format(_startDate);
  String get endDateFormatted => dateFormat.format(_endDate);

  // Get title with date range
  String getReportTitle() {
    return '${getReportName()} ($startDateFormatted - $endDateFormatted)';
  }

  // Abstract method to get report name - to be implemented by subclasses
  String getReportName();

  // Clear cache when needed
  void clearCache() {
    _cache.clear();
    debugPrint("BaseReportProvider: Cache cleared");
  }

  // Force refresh next fetch
  void forceRefresh() {
    _forceRefresh = true;
    debugPrint("BaseReportProvider: Next fetch will be forced");
  }

  // Helper to explicitly call BaseProvider's getItems
  // Future<List<T>> fetchItemsFromBaseProvider({
  //   Map<String, String>? queryParams,
  // }) {
  //   // This super call is from BaseReportProvider to BaseProvider
  //   return super.getItems(queryParams: queryParams);
  // }
}
