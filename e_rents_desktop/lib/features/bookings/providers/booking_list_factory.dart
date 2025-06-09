import 'package:flutter/material.dart';
import '../../../models/booking.dart';
import '../../../repositories/booking_repository.dart';
import '../../../widgets/table/custom_table.dart';

/// ✅ RICH BOOKING TABLE FACTORY - Production table with enhanced UI
///
/// This provides a rich user experience with:
/// - Styled cells with icons and visual elements
/// - Interactive modals for quick actions
/// - Enhanced status badges and formatting
/// - Professional landlord-focused interface
///
/// Features:
/// - Icon-enhanced cells (🏠 Property, 👤 Tenant, etc.)
/// - Styled ID badges and status indicators
/// - Interactive row modals with quick actions
/// - Professional color scheme and typography

class BookingListFactory {
  /// Create a booking table with enhanced modular design
  static CustomTableWidget<Booking> create({
    required BookingRepository repository,
    String title = 'Bookings',
    Widget? headerActions,
    void Function(Booking)? onRowTap,
    void Function(Booking)? onRowDoubleTap,
  }) {
    return CustomTable.create<Booking>(
      fetchData: repository.getPagedBookings,
      columns: _buildColumns(),
      title: title,
      searchHint: 'Search bookings by property, tenant, or ID...',
      emptyStateMessage: 'No bookings found. Create your first booking!',
      filters: _buildFilters(),
      headerActions: headerActions,
      onRowTap: onRowTap,
      onRowDoubleTap: onRowDoubleTap,
      defaultPageSize: 25,
    );
  }

  /// ✅ MODULAR: Separated column definitions for better organization
  static List<TableColumnConfig<Booking>> _buildColumns() {
    return [
      // ID Column with custom formatting
      TableColumnConfig<Booking>(
        key: 'bookingId',
        label: 'Booking ID',
        cellBuilder: (booking) => _buildIdCell(booking),
        width: const FlexColumnWidth(0.8),
      ),

      // Property column with link styling
      TableColumnConfig<Booking>(
        key: 'propertyName',
        label: 'Property',
        cellBuilder: (booking) => _buildPropertyCell(booking),
        width: const FlexColumnWidth(1.5),
      ),

      // Tenant column
      TableColumnConfig<Booking>(
        key: 'userName',
        label: 'Tenant',
        cellBuilder: (booking) => _buildTenantCell(booking),
        width: const FlexColumnWidth(1.2),
      ),

      // Date columns
      TableColumnConfig<Booking>(
        key: 'startDate',
        label: 'Check-in',
        cellBuilder: (booking) => _buildDateCell(booking.startDate),
        width: const FlexColumnWidth(1.0),
      ),

      TableColumnConfig<Booking>(
        key: 'endDate',
        label: 'Check-out',
        cellBuilder: (booking) => _buildDateCell(booking.endDate),
        width: const FlexColumnWidth(1.0),
      ),

      // Guests column
      TableColumnConfig<Booking>(
        key: 'numberOfGuests',
        label: 'Guests',
        cellBuilder: (booking) => _buildGuestsCell(booking),
        width: const FlexColumnWidth(0.6),
      ),

      // Price column with currency formatting
      TableColumnConfig<Booking>(
        key: 'totalPrice',
        label: 'Total Price',
        cellBuilder: (booking) => _buildPriceCell(booking),
        width: const FlexColumnWidth(1.0),
      ),

      // Status column with color coding
      TableColumnConfig<Booking>(
        key: 'status',
        label: 'Status',
        cellBuilder: (booking) => _buildStatusCell(booking),
        width: const FlexColumnWidth(0.8),
      ),
    ];
  }

  /// ✅ MODULAR: Separated filter definitions
  static List<TableFilter> _buildFilters() {
    return [
      TableFilter(
        key: 'Status',
        label: 'Status',
        type: FilterType.dropdown,
        options:
            BookingStatus.values
                .map(
                  (status) => FilterOption(
                    label: status.displayName,
                    value: status.name,
                  ),
                )
                .toList(),
      ),
      TableFilter(key: 'PropertyId', label: 'Property', type: FilterType.text),
      TableFilter(
        key: 'StartDate',
        label: 'Check-in Date',
        type: FilterType.dateRange,
      ),
    ];
  }

  // ✅ MODULAR CELL BUILDERS: Reusable and consistent

  static Widget _buildIdCell(Booking booking) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '#${booking.bookingId}',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontFamily: 'monospace',
          fontSize: 13,
        ),
      ),
    );
  }

  static Widget _buildPropertyCell(Booking booking) {
    return Row(
      children: [
        Icon(Icons.home, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            booking.propertyName ?? 'N/A',
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  static Widget _buildTenantCell(Booking booking) {
    return Row(
      children: [
        Icon(Icons.person, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            booking.userName ?? 'N/A',
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  static Widget _buildDateCell(DateTime? date) {
    if (date == null) {
      return const Text('N/A', style: TextStyle(color: Colors.grey));
    }

    return Text(
      date.toLocal().toString().split(' ')[0],
      style: const TextStyle(fontSize: 14),
    );
  }

  static Widget _buildGuestsCell(Booking booking) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.people, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          '${booking.numberOfGuests}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  static Widget _buildPriceCell(Booking booking) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        '${booking.totalPrice.toStringAsFixed(2)} BAM',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Colors.green,
        ),
      ),
    );
  }

  static Widget _buildStatusCell(Booking booking) {
    final color = _getStatusColor(booking.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        booking.status.displayName,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  /// Helper: Get status color
  static Color _getStatusColor(BookingStatus status) {
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
