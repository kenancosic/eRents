import 'package:e_rents_desktop/features/rents/providers/rents_provider.dart';
import 'package:e_rents_desktop/models/booking.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RentsScreen extends StatefulWidget {
  const RentsScreen({super.key});

  @override
  State<RentsScreen> createState() => _RentsScreenState();
}

class _RentsScreenState extends State<RentsScreen> {
  BookingStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RentsProvider>().getPagedBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<RentsProvider>().refresh(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(context),
          const Divider(height: 1),
          Expanded(child: _buildTable(context)),
          const Divider(height: 1),
          _buildPagingBar(context),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          const Text('Status:'),
          const SizedBox(width: 8),
          DropdownButton<BookingStatus?>(
            value: _selectedStatus,
            items: const [
              DropdownMenuItem<BookingStatus?>(value: null, child: Text('All')),
              DropdownMenuItem<BookingStatus?>(value: BookingStatus.upcoming, child: Text('Upcoming')),
              DropdownMenuItem<BookingStatus?>(value: BookingStatus.active, child: Text('Active')),
              DropdownMenuItem<BookingStatus?>(value: BookingStatus.completed, child: Text('Completed')),
              DropdownMenuItem<BookingStatus?>(value: BookingStatus.cancelled, child: Text('Cancelled')),
            ],
            onChanged: (val) async {
              setState(() => _selectedStatus = val);
              final p = context.read<RentsProvider>();
              p.setStatusFilter(val);
              await p.getPagedBookings(params: p.lastQuery);
            },
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () async {
              setState(() => _selectedStatus = null);
              final p = context.read<RentsProvider>();
              p.clearFilters();
              await p.getPagedBookings(params: p.lastQuery);
            },
            icon: const Icon(Icons.filter_alt_off),
            label: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context) {
    return Consumer<RentsProvider>(
      builder: (context, p, child) {
        if (p.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (p.error != null) {
          return Center(child: Text('Error: ${p.error}'));
        }
        if (p.bookings.isEmpty) {
          return const Center(child: Text('No bookings found.'));
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Booking #')),
              DataColumn(label: Text('Property')),
              DataColumn(label: Text('Tenant')),
              DataColumn(label: Text('Dates')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Total')),
            ],
            rows: p.bookings.map((b) {
              return DataRow(
                cells: [
                  DataCell(Text(b.bookingId.toString())),
                  DataCell(Text(b.propertyName ?? 'N/A')),
                  DataCell(Text(b.userName ?? b.tenantName ?? 'N/A')),
                  DataCell(Text(b.dateRange)),
                  DataCell(Text(b.status.displayName)),
                  DataCell(Text(b.formattedTotalPrice)),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildPagingBar(BuildContext context) {
    return Consumer<RentsProvider>(
      builder: (context, p, child) {
        final total = p.pagedBookings.totalCount;
        final start = ((p.page - 1) * p.pageSize) + 1;
        final end = (start + p.bookings.length - 1).clamp(0, total);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Text('Showing $start-$end of $total'),
              const SizedBox(width: 16),
              IconButton(
                tooltip: 'Prev page',
                icon: const Icon(Icons.chevron_left),
                onPressed: p.page > 1 && !p.isLoading
                    ? () async {
                        p.setPage(p.page - 1);
                        await p.getPagedBookings(params: p.lastQuery);
                      }
                    : null,
              ),
              Text('Page ${p.page}'),
              IconButton(
                tooltip: 'Next page',
                icon: const Icon(Icons.chevron_right),
                onPressed: !p.isLoading && (start + p.bookings.length - 1) < total
                    ? () async {
                        p.setPage(p.page + 1);
                        await p.getPagedBookings(params: p.lastQuery);
                      }
                    : null,
              ),
              const Spacer(),
              const Text('Page size:'),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: p.pageSize,
                items: const [10, 20, 50, 100]
                    .map((s) => DropdownMenuItem<int>(value: s, child: Text('$s')))
                    .toList(),
                onChanged: p.isLoading
                    ? null
                    : (v) async {
                        if (v == null) return;
                        p.setPageSize(v);
                        await p.getPagedBookings(params: p.lastQuery);
                      },
              ),
            ],
          ),
        );
      },
    );
  }
}
