import 'package:e_rents_desktop/base/crud/list_screen.dart';
import 'package:e_rents_desktop/features/rents/providers/rents_provider.dart';
import 'package:e_rents_desktop/presentation/booking_status_ui.dart';
import 'package:e_rents_desktop/presentation/status_pill.dart';
import 'package:e_rents_desktop/models/booking.dart';
import 'package:e_rents_desktop/models/tenant.dart';
import 'package:e_rents_desktop/models/enums/booking_status.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RentsScreen extends StatefulWidget {
  const RentsScreen({super.key});

  @override
  State<RentsScreen> createState() => _RentsScreenState();
}

class _RentsScreenState extends State<RentsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final ListController _dailyListController = ListController();
  final ListController _monthlyListController = ListController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<Booking>> _fetchBookings(
    BuildContext context, {
    int page = 1,
    int pageSize = 20,
    Map<String, dynamic>? filters,
    String? rentingType,
  }) async {
    final p = context.read<RentsProvider>();
    final map = {
      'page': page,
      'pageSize': pageSize,
      if (rentingType != null) 'rentingType': rentingType,
      ...?filters,
    };
    await p.getPagedBookings(params: map);
    return p.pagedBookings.items;
  }

  Future<List<Tenant>> _fetchTenants(
    BuildContext context, {
    int page = 1,
    int pageSize = 20,
    Map<String, dynamic>? filters,
  }) async {
    final p = context.read<RentsProvider>();
    final map = {
      'page': page,
      'pageSize': pageSize,
      ...?filters,
    };
    await p.getPagedTenants(params: map);
    return p.pagedTenants.items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rents'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Daily Rentals'),
            Tab(text: 'Monthly Rentals'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDailyRentalsTab(context),
          _buildMonthlyRentalsTab(context),
        ],
      ),
    );
  }

  Widget _buildDailyRentalsTab(BuildContext context) {
    return ListScreen<Booking>(
      title: '',
      enablePagination: true,
      pageSize: 20,
      inlineSearchBar: true,
      showFilters: true,
      searchParamKey: 'search',
      filterBuilder: (context, currentFilters, controller) {
        return _buildBookingFilterPanel(context, currentFilters, controller);
      },
      sortFunction: (a, b) {
        // Sort by property name first, then by start date
        final propertyComparison = (a.propertyName ?? '').compareTo(b.propertyName ?? '');
        if (propertyComparison != 0) return propertyComparison;
        return a.startDate.compareTo(b.startDate);
      },
      fetchItems: ({int page = 1, int pageSize = 20, Map<String, dynamic>? filters}) =>
          _fetchBookings(context, page: page, pageSize: pageSize, filters: filters, rentingType: 'Daily'),
      controller: _dailyListController,
      itemBuilder: (context, b) {
        final contract = context.read<RentsProvider>().rentingTypeFor(b.propertyId)?.toString() ?? '—';
        return ListTile(
          title: Text(b.propertyName ?? 'N/A'),
          subtitle: Text('${b.userName ?? b.tenantName ?? 'N/A'} • ${b.dateRange} • $contract'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatusPill(
                label: b.status.displayName,
                backgroundColor: b.status.color,
                iconData: b.status.icon,
              ),
              const SizedBox(width: 12),
              Text(b.formattedTotalPrice),
            ],
          ),
        );
      },
      onItemTap: (Booking b) {},
      tableColumns: const [
        DataColumn(label: Text('Property')),
        DataColumn(label: Text('Tenant')),
        DataColumn(label: Text('Contract Type')),
        DataColumn(label: Text('Date Range')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Total Price')),
        DataColumn(label: Text('Actions')),
      ],
      tableRowsBuilder: (ctx, items) {
        final provider = ctx.read<RentsProvider>();
        return items.map((b) {
          final contract = provider.rentingTypeFor(b.propertyId)?.toString() ?? '—';
          return DataRow(
            cells: [
              DataCell(Text(b.propertyName ?? 'N/A')),
              DataCell(Text(b.userName ?? 'N/A')),
              DataCell(Text(contract)),
              DataCell(Text(b.dateRange)),
              DataCell(
                StatusPill(
                  label: b.status.displayName,
                  backgroundColor: b.status.color,
                  iconData: b.status.icon,
                ),
              ),
              DataCell(Text(b.formattedTotalPrice)),
              DataCell(_buildBookingActions(ctx, b, provider, _dailyListController)),
            ],
          );
        }).toList();
      },
    );
  }

  Widget _buildMonthlyRentalsTab(BuildContext context) {
    return ListScreen<Tenant>(
      title: '',
      enablePagination: true,
      pageSize: 20,
      inlineSearchBar: true,
      showFilters: true,
      searchParamKey: 'search',
      filterBuilder: (context, currentFilters, controller) {
        return _buildTenantFilterPanel(context, currentFilters, controller);
      },
      sortFunction: (a, b) {
        // Sort by property name first, then by lease start date
        final propertyComparison = a.propertyName.compareTo(b.propertyName);
        if (propertyComparison != 0) return propertyComparison;
        return (a.leaseStartDate ?? DateTime.now()).compareTo(b.leaseStartDate ?? DateTime.now());
      },
      fetchItems: ({int page = 1, int pageSize = 20, Map<String, dynamic>? filters}) =>
          _fetchTenants(context, page: page, pageSize: pageSize, filters: filters),
      controller: _monthlyListController,
      itemBuilder: (context, t) {
        return ListTile(
          title: Text('${t.fullName} (${t.email})'),
          subtitle: Text('${t.propertyName} • ${t.leasePeriod}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatusPill(
                label: context.read<RentsProvider>().getTenantBookingStatus(t),
                backgroundColor: _getBookingStatusColor(context.read<RentsProvider>().getTenantBookingStatus(t)),
                iconData: _getBookingStatusIcon(context.read<RentsProvider>().getTenantBookingStatus(t)),
              ),
              const SizedBox(width: 12),
              if (t.tenantStatus == TenantStatus.inactive)
                ElevatedButton(
                  onPressed: () async {
                    if (t.propertyId != null) {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Accept Tenant'),
                          content: const Text('Are you sure you want to accept this tenant request?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('No'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Yes'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        final provider = context.read<RentsProvider>();
                        await provider.acceptTenantRequest(t.tenantId, t.propertyId!);
                        _monthlyListController.refresh();
                      }
                    }
                  },
                  child: const Text('Accept'),
                ),
            ],
          ),
        );
      },
      onItemTap: (Tenant t) {},
      tableColumns: const [
        DataColumn(label: Text('Tenant')),
        DataColumn(label: Text('Property')),
        DataColumn(label: Text('Lease Period')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Actions')),
      ],
      tableRowsBuilder: (ctx, items) {
        return items.map((t) {
          return DataRow(
            cells: [
              DataCell(Text('${t.fullName} (${t.email})')),
              DataCell(Text(t.propertyName)),
              DataCell(Text(t.leasePeriod)),
              DataCell(
                StatusPill(
                  label: context.read<RentsProvider>().getTenantBookingStatus(t),
                  backgroundColor: _getBookingStatusColor(context.read<RentsProvider>().getTenantBookingStatus(t)),
                  iconData: _getBookingStatusIcon(context.read<RentsProvider>().getTenantBookingStatus(t)),
                ),
              ),
              DataCell(
                t.tenantStatus == TenantStatus.inactive
                    ? ElevatedButton(
                        onPressed: () async {
                          if (t.propertyId != null) {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Accept Tenant'),
                                content: const Text('Are you sure you want to accept this tenant request?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(false),
                                    child: const Text('No'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(true),
                                    child: const Text('Yes'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              await ctx.read<RentsProvider>().acceptTenantRequest(t.tenantId, t.propertyId!);
                              _monthlyListController?.refresh();
                            }
                          }
                        },
                        child: const Text('Accept'),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          );
        }).toList();
      },
    );
  }

  Widget _buildBookingFilterPanel(
    BuildContext context,
    Map<String, dynamic> currentFilters,
    FilterController controller,
  ) {
    String? selectedStatus = currentFilters['status'] as String?;

    // Bind the state to the controller
    controller.bind(
      getFilters: () => {'status': selectedStatus},
      resetFields: () => selectedStatus = null,
    );

    return StatefulBuilder(builder: (context, setState) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: selectedStatus,
            hint: const Text('Booking Status'),
            onChanged: (value) {
              setState(() {
                selectedStatus = value;
              });
            },
            items: BookingStatus.values.map((status) {
              return DropdownMenuItem(
                value: status.name,
                child: Text(status.displayName),
              );
            }).toList(),
            decoration: const InputDecoration(labelText: 'Status'),
          ),
        ],
      );
    });
  }

  Widget _buildTenantFilterPanel(
    BuildContext context,
    Map<String, dynamic> currentFilters,
    FilterController controller,
  ) {
    String? selectedStatus = currentFilters['status'] as String?;

    // Bind the state to the controller
    controller.bind(
      getFilters: () => {'status': selectedStatus},
      resetFields: () => selectedStatus = null,
    );

    return StatefulBuilder(builder: (context, setState) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: selectedStatus,
            hint: const Text('Tenant Status'),
            onChanged: (value) {
              setState(() {
                selectedStatus = value;
              });
            },
            items: TenantStatus.values.map((status) {
              return DropdownMenuItem(
                value: status.name,
                child: Text(status.displayName),
              );
            }).toList(),
            decoration: const InputDecoration(labelText: 'Status'),
          ),
        ],
      );
    });
  }


  Widget _buildBookingActions(
    BuildContext context,
    Booking booking,
    RentsProvider provider,
    ListController listController,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (booking.status == BookingStatus.upcoming)
          IconButton(
            icon: const Icon(Icons.cancel, color: Colors.red),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Cancel Booking'),
                  content: const Text('Are you sure you want to cancel this booking?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('No'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Yes'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await provider.cancelBooking(booking.bookingId);
                listController.refresh();
              }
            },
          ),
      ],
    );
  }

  Color _getBookingStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'requested':
        return Colors.orange;
      case 'canceled':
        return Colors.red;
      case 'upcoming':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getBookingStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Icons.check_circle;
      case 'completed':
        return Icons.check_circle_outline;
      case 'requested':
        return Icons.pending;
      case 'canceled':
        return Icons.cancel;
      case 'upcoming':
        return Icons.schedule;
      default:
        return Icons.help_outline;
    }
  }

}
