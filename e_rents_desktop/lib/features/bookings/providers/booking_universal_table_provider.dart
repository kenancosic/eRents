import 'package:flutter/material.dart';
import '../../../models/booking.dart';
import '../../../repositories/booking_repository.dart';
import '../../../widgets/universal_table.dart';

/// ✅ BOOKING UNIVERSAL TABLE PROVIDER - 90% automatic, 10% custom
///
/// This provider extends BaseUniversalTableProvider to automatically handle:
/// - Pagination, sorting, searching, filtering
/// - Backend Universal System integration
/// - Standard UI components and interactions
///
/// Only booking-specific column definitions are required (10% custom code)
class BookingUniversalTableProvider
    extends BaseUniversalTableProvider<Booking> {
  BookingUniversalTableProvider({
    required BookingRepository repository,
    required UniversalTableConfig<Booking> config,
  }) : super(fetchDataFunction: repository.getPagedBookings, config: config);

  @override
  List<TableColumnConfig<Booking>> get columns => [
    // ✅ AUTOMATIC: 90% of columns use standard helpers
    createColumn(
      key: 'bookingId',
      label: 'Booking ID',
      cellBuilder: (booking) => textCell('#${booking.bookingId}'),
      width: const FlexColumnWidth(0.8),
    ),
    createColumn(
      key: 'propertyName',
      label: 'Property',
      cellBuilder: (booking) => textCell(booking.propertyName ?? 'N/A'),
      width: const FlexColumnWidth(1.5),
    ),
    createColumn(
      key: 'userName',
      label: 'Tenant',
      cellBuilder: (booking) => textCell(booking.userName ?? 'N/A'),
      width: const FlexColumnWidth(1.2),
    ),
    createColumn(
      key: 'startDate',
      label: 'Check-in',
      cellBuilder: (booking) => dateCell(booking.startDate),
      width: const FlexColumnWidth(1.0),
    ),
    createColumn(
      key: 'endDate',
      label: 'Check-out',
      cellBuilder: (booking) => dateCell(booking.endDate),
      width: const FlexColumnWidth(1.0),
    ),
    createColumn(
      key: 'numberOfGuests',
      label: 'Guests',
      cellBuilder: (booking) => textCell('${booking.numberOfGuests}'),
      width: const FlexColumnWidth(0.6),
    ),
    createColumn(
      key: 'totalPrice',
      label: 'Total Price',
      cellBuilder: (booking) => currencyCell(booking.totalPrice),
      width: const FlexColumnWidth(1.0),
    ),
    createColumn(
      key: 'status',
      label: 'Status',
      cellBuilder:
          (booking) => statusCell(
            booking.status.displayName,
            color: _getStatusColor(booking.status),
          ),
      width: const FlexColumnWidth(0.8),
    ),
  ];

  @override
  List<TableFilter> get availableFilters => [
    createFilter(
      key: 'Status',
      label: 'Status',
      type: FilterType.dropdown,
      options:
          BookingStatus.values
              .map(
                (status) =>
                    FilterOption(label: status.displayName, value: status.name),
              )
              .toList(),
    ),
    createFilter(key: 'PropertyId', label: 'Property', type: FilterType.text),
    createFilter(
      key: 'StartDate',
      label: 'Check-in Date',
      type: FilterType.dateRange,
    ),
  ];

  /// ✅ CUSTOM: 10% - Booking-specific status colors
  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.upcoming:
        return Colors.blue;
      case BookingStatus.active:
        return Colors.green;
      case BookingStatus.completed:
        return Colors.deepPurple;
      case BookingStatus.cancelled:
        return Colors.red;
    }
  }
}

/// ✅ FACTORY - One-liner table creation (like ImageUtils pattern)
class BookingTableFactory {
  static UniversalTableWidget<Booking> create({
    required BookingRepository repository,
    String title = 'Bookings',
    Widget? headerActions,
    void Function(Booking)? onRowTap,
    void Function(Booking)? onRowDoubleTap,
  }) {
    // ✅ CONFIGURATION: Customize table behavior
    final config = UniversalTableConfig<Booking>(
      title: title,
      searchHint: 'Search bookings...',
      emptyStateMessage: 'No bookings found',
      headerActions: headerActions,
      onRowTap: onRowTap,
      onRowDoubleTap: onRowDoubleTap,
    );

    // ✅ PROVIDER: Create Universal Table Provider
    final provider = BookingUniversalTableProvider(
      repository: repository,
      config: config,
    );

    // ✅ WIDGET: Return ready-to-use table widget
    return UniversalTableWidget<Booking>(dataProvider: provider, title: title);
  }
}
