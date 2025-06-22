import 'package:e_rents_desktop/models/paged_result.dart';
import 'package:e_rents_desktop/repositories/booking_repository.dart';
import 'package:e_rents_desktop/repositories/rental_request_repository.dart';
import 'package:e_rents_desktop/widgets/table/config/table_config.dart';
import 'package:e_rents_desktop/widgets/table/core/table_columns.dart';
import 'package:e_rents_desktop/widgets/table/custom_table_widget.dart';
import 'package:e_rents_desktop/widgets/table/providers/table_provider.dart';
import 'package:e_rents_desktop/widgets/table/core/table_filters.dart';
import 'package:e_rents_desktop/models/rental_display_item.dart';
import 'package:flutter/material.dart';

class RentsTableFactory {
  static CustomTableWidget<RentalDisplayItem> createStaysTable(
    BookingRepository bookingRepository, {
    Function(RentalDisplayItem)? onItemTap,
  }) {
    final provider = StaysTableProvider(
      bookingRepository: bookingRepository,
      onItemTap: onItemTap,
    );
    return CustomTableWidget<RentalDisplayItem>(
      dataProvider: provider,
      title: 'Stays',
      searchHint: 'Search by guest or property...',
    );
  }

  static CustomTableWidget<RentalDisplayItem> createLeasesTable(
    RentalRequestRepository rentalRequestRepository, {
    Function(RentalDisplayItem)? onItemTap,
  }) {
    final provider = LeasesTableProvider(
      rentalRequestRepository: rentalRequestRepository,
      onItemTap: onItemTap,
    );
    return CustomTableWidget<RentalDisplayItem>(
      dataProvider: provider,
      title: 'Leases',
      searchHint: 'Search by tenant or property...',
    );
  }
}

class StaysTableProvider extends TableProvider<RentalDisplayItem> {
  final BookingRepository bookingRepository;
  final Function(RentalDisplayItem)? onItemTap;

  StaysTableProvider({required this.bookingRepository, this.onItemTap})
    : super(
        fetchDataFunction: (params) async {
          final result = await bookingRepository.getPaged(params);
          return PagedResult(
            items:
                result.items
                    .map((e) => RentalDisplayItem.fromBooking(e))
                    .toList(),
            page: result.page > 0 ? result.page - 1 : 0,
            pageSize: result.pageSize,
            totalCount: result.totalCount,
          );
        },
        config: const UniversalTableConfig(
          emptyStateMessage: 'No stays found.',
        ),
      );

  @override
  List<TableColumnConfig<RentalDisplayItem>> get columns => [
    createColumn(
      key: 'guest',
      label: 'Guest',
      cellBuilder: (item) => textCell(item.userName ?? 'N/A'),
    ),
    createColumn(
      key: 'property',
      label: 'Property',
      cellBuilder: (item) => textCell(item.propertyName ?? 'N/A'),
    ),
    createColumn(
      key: 'checkIn',
      label: 'Check-in',
      cellBuilder: (item) => dateCell(item.startDate),
    ),
    createColumn(
      key: 'checkOut',
      label: 'Check-out',
      cellBuilder: (item) => dateCell(item.endDate),
    ),
    createColumn(
      key: 'nights',
      label: 'Nights',
      cellBuilder: (item) {
        if (item.endDate == null) return textCell('N/A');
        final nights = item.endDate!.difference(item.startDate).inDays;
        return textCell(nights.toString());
      },
    ),
    createColumn(
      key: 'amount',
      label: 'Amount',
      cellBuilder: (item) => currencyCell(item.amount),
    ),
    createColumn(
      key: 'status',
      label: 'Status',
      cellBuilder:
          (item) => statusCell(
            item.status.toString().split('.').last,
            color: Colors.green,
          ),
    ),
    createColumn(
      key: 'actions',
      label: 'Actions',
      sortable: false,
      cellBuilder:
          (item) => actionCell([
            iconActionCell(
              icon: Icons.more_horiz,
              onPressed: () => onItemTap?.call(item),
              tooltip: 'Details',
            ),
          ]),
    ),
  ];

  @override
  List<TableFilter> get availableFilters => [];
}

class LeasesTableProvider extends TableProvider<RentalDisplayItem> {
  final RentalRequestRepository rentalRequestRepository;
  final Function(RentalDisplayItem)? onItemTap;

  LeasesTableProvider({required this.rentalRequestRepository, this.onItemTap})
    : super(
        fetchDataFunction: (params) async {
          final result = await rentalRequestRepository.getPaged(params);
          return PagedResult(
            items:
                result.items
                    .map((e) => RentalDisplayItem.fromRentalRequest(e))
                    .toList(),
            page: result.page > 0 ? result.page - 1 : 0,
            pageSize: result.pageSize,
            totalCount: result.totalCount,
          );
        },
        config: const UniversalTableConfig(
          emptyStateMessage: 'No leases found.',
        ),
      );

  @override
  List<TableColumnConfig<RentalDisplayItem>> get columns => [
    createColumn(
      key: 'tenant',
      label: 'Tenant',
      cellBuilder: (item) => textCell(item.userName ?? 'N/A'),
    ),
    createColumn(
      key: 'property',
      label: 'Property',
      cellBuilder: (item) => textCell(item.propertyName ?? 'N/A'),
    ),
    createColumn(
      key: 'startDate',
      label: 'Start Date',
      cellBuilder: (item) => dateCell(item.startDate),
    ),
    createColumn(
      key: 'duration',
      label: 'Duration (Months)',
      cellBuilder:
          (item) => textCell(item.leaseDurationMonths?.toString() ?? 'N/A'),
    ),
    createColumn(
      key: 'monthlyRent',
      label: 'Monthly Rent',
      cellBuilder: (item) => currencyCell(item.amount),
    ),
    createColumn(
      key: 'status',
      label: 'Status',
      cellBuilder:
          (item) => statusCell(
            item.status.toString().split('.').last,
            color: Colors.blue,
          ),
    ),
    createColumn(
      key: 'actions',
      label: 'Actions',
      sortable: false,
      cellBuilder:
          (item) => actionCell([
            iconActionCell(
              icon: Icons.more_horiz,
              onPressed: () => onItemTap?.call(item),
              tooltip: 'Details',
            ),
          ]),
    ),
  ];

  @override
  List<TableFilter> get availableFilters => [];
}
