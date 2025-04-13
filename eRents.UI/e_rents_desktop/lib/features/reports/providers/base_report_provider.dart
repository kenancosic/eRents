import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

/// Base class for all report providers that handles common date functionality
abstract class BaseReportProvider<T> extends BaseProvider<T> {
  // Date range for filtering/contextual information
  DateTime _startDate = DateTime(2023, 6, 1); // Using fixed date in 2023
  DateTime _endDate = DateTime(2023, 7, 31); // Using fixed date in 2023

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

    // Fetch data immediately to ensure we have initial data
    Future.microtask(() {
      if (!items_.any((element) => true)) {
        // Check if list is empty
        debugPrint(
          "BaseReportProvider: No data found, triggering initial fetch",
        );
        fetchItems();
      }
    });
  }

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
    debugPrint("BaseReportProvider.onDateRangeChanged: Fetching updated data");
    fetchItems(); // Default implementation is to refresh data
  }

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
