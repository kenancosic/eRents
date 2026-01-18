import 'package:e_rents_desktop/base/crud/list_screen.dart';
import 'package:e_rents_desktop/widgets/sort_options_widget.dart';
import 'package:e_rents_desktop/features/rents/widgets/monthly_tenant_actions.dart';
import 'package:e_rents_desktop/features/rents/providers/rents_provider.dart';
import 'package:e_rents_desktop/presentation/booking_status_ui.dart';
import 'package:e_rents_desktop/presentation/status_pill.dart';
import 'package:e_rents_desktop/models/booking.dart';
import 'package:e_rents_desktop/models/lease_extension_request.dart';
import 'package:e_rents_desktop/models/tenant.dart';
import 'package:e_rents_desktop/models/enums/booking_status.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/utils/date_utils.dart';

class RentsScreen extends StatefulWidget {
  const RentsScreen({super.key});

  @override
  State<RentsScreen> createState() => _RentsScreenState();
}

class _RentsScreenState extends State<RentsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final ListController _dailyListController = ListController();
  final ListController _monthlyListController = ListController();
  final Set<int> _recentlyApprovedTenants = <int>{};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
            Tab(text: 'Extension Requests'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDailyRentalsTab(context),
          _buildMonthlyRentalsTab(context),
          _buildExtensionRequestsTab(context),
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
              if (_recentlyApprovedTenants.contains(t.tenantId))
                const Chip(
                  label: Text('Approval sent', style: TextStyle(color: Colors.white)),
                  backgroundColor: Colors.green,
                ),
              if (_recentlyApprovedTenants.contains(t.tenantId)) const SizedBox(width: 12),
              MonthlyTenantActions(
                tenant: t,
                onRefresh: () {
                  _monthlyListController.refresh();
                  if (mounted) {
                    setState(() {
                      _recentlyApprovedTenants.add(t.tenantId);
                    });
                  }
                },
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_recentlyApprovedTenants.contains(t.tenantId))
                      const Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: Chip(
                          label: Text('Approval sent', style: TextStyle(color: Colors.white)),
                          backgroundColor: Colors.green,
                        ),
                      ),
                    MonthlyTenantActions(
                      tenant: t,
                      onRefresh: () {
                        _monthlyListController.refresh();
                        if (mounted) {
                          setState(() {
                            _recentlyApprovedTenants.add(t.tenantId);
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList();
      },
    );
  }

  Widget _buildExtensionRequestsTab(BuildContext context) {
    return FutureBuilder<List<LeaseExtensionRequest>>(
      future: context.read<RentsProvider>().getExtensionRequests(status: 'Pending'),
      builder: (ctx, snap) {
        final items = snap.data ?? const <LeaseExtensionRequest>[];
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (items.isEmpty) {
          return const Center(child: Text('No pending extension requests'));
        }
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Adjust column widths based on available screen width
              final isWideScreen = constraints.maxWidth > 1200;
              final isMediumScreen = constraints.maxWidth > 800;
              
              return SizedBox(
                width: constraints.maxWidth,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                  columnSpacing: isWideScreen ? 24 : 16,
                  horizontalMargin: isWideScreen ? 16 : 8,
                  headingRowHeight: 56,
                  dataRowMinHeight: 52,
                  dataRowMaxHeight: 72,
                  columns: [
                    DataColumn(
                      label: const Text('Property'),
                      tooltip: 'Property name',
                    ),
                    DataColumn(
                      label: const Text('Requested By'),
                      tooltip: 'Tenant who requested the extension',
                    ),
                    DataColumn(
                      label: const Text('Current End'),
                      tooltip: 'Current lease end date',
                    ),
                    DataColumn(
                      label: const Text('Extension'),
                      tooltip: 'New end date or extension period',
                    ),
                    if (isWideScreen) 
                      DataColumn(
                        label: const Text('New Monthly'),
                        tooltip: 'Updated monthly rent amount',
                      ),
                    DataColumn(
                      label: const Text('Requested'),
                      tooltip: 'Date when extension was requested',
                    ),
                    DataColumn(
                      label: const Text('Actions'),
                      tooltip: 'Approve or reject the extension',
                    ),
                  ],
                  rows: items.map((r) {
                    final newEndOrMonths = r.newEndDate != null
                        ? AppDateUtils.formatShort(r.newEndDate)
                        : (r.extendByMonths != null ? '+${r.extendByMonths} months' : '—');
                    return DataRow(
                      cells: [
                        DataCell(
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isWideScreen ? 200 : 150,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  r.propertyName,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                if (!isMediumScreen && r.newMonthlyAmount != null)
                                  Text(
                                    '\$${r.newMonthlyAmount!.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(
                          Tooltip(
                            message: 'User ID: ${r.requestedByUserId}',
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: isMediumScreen ? 180 : 120,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    r.requesterDisplayName,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  if (!isWideScreen)
                                    Text(
                                      AppDateUtils.formatShort(r.createdAt),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            AppDateUtils.formatShort(r.oldEndDate),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              newEndOrMonths,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ),
                        if (isWideScreen)
                          DataCell(
                            Text(
                              r.newMonthlyAmount != null 
                                  ? '\$${r.newMonthlyAmount!.toStringAsFixed(2)}' 
                                  : '—',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        if (!isWideScreen)
                          DataCell(
                            Tooltip(
                              message: AppDateUtils.formatShortWithTime(r.createdAt),
                              child: Text(
                                AppDateUtils.formatShort(r.createdAt),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          )
                        else
                          DataCell(
                            Tooltip(
                              message: AppDateUtils.formatShortWithTime(r.createdAt),
                              child: Text(
                                AppDateUtils.formatShort(r.createdAt),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        DataCell(
                          _buildExtensionActions(ctx, r, isMediumScreen),
                        ),
                      ],
                    );
                  }).toList(),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Build action buttons for extension requests with responsive layout
  Widget _buildExtensionActions(
    BuildContext context,
    LeaseExtensionRequest request,
    bool isMediumScreen,
  ) {
    final newEndOrMonths = request.newEndDate != null
        ? AppDateUtils.formatShort(request.newEndDate)
        : (request.extendByMonths != null ? '+${request.extendByMonths} months' : '—');

    if (isMediumScreen) {
      // Full layout for medium and larger screens
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Approve'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dctx) => AlertDialog(
                  title: const Text('Approve Extension'),
                  content: Text('Approve lease extension for ${request.requesterDisplayName}?\n\n'
                      'Property: ${request.propertyName}\n'
                      'New end date: $newEndOrMonths'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(dctx, false), child: const Text('Cancel')),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(dctx, true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('Approve'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                final provider = context.read<RentsProvider>();
                final ok = await provider.approveExtension(request.requestId);
                if (mounted) {
                  if (ok) {
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Extension approved successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    // Show the actual error message from the provider
                    final errorMsg = provider.error ?? 'Failed to approve extension';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(errorMsg),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                }
              }
            },
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Reject'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: () async {
              final ctrl = TextEditingController();
              final reason = await showDialog<String?>(
                context: context,
                builder: (dctx) {
                  return AlertDialog(
                    title: const Text('Reject Extension'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Reject lease extension for ${request.requesterDisplayName}?'),
                        const SizedBox(height: 16),
                        TextField(
                          controller: ctrl,
                          decoration: const InputDecoration(
                            labelText: 'Reason (optional)',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(dctx, null), child: const Text('Cancel')),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(dctx, ctrl.text.trim()),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                        child: const Text('Reject'),
                      ),
                    ],
                  );
                },
              );
              if (reason != null) {
                final ok = await context.read<RentsProvider>().rejectExtension(request.requestId, reason: reason.isEmpty ? null : reason);
                if (ok && mounted) setState(() {});
              }
            },
          ),
        ],
      );
    } else {
      // Compact layout for small screens
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green, size: 20),
            tooltip: 'Approve',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dctx) => AlertDialog(
                  title: const Text('Approve Extension'),
                  content: Text('Approve lease extension for ${request.requesterDisplayName}?\n\n'
                      'Property: ${request.propertyName}\n'
                      'New end date: $newEndOrMonths'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(dctx, false), child: const Text('Cancel')),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(dctx, true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('Approve'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                final provider = context.read<RentsProvider>();
                final ok = await provider.approveExtension(request.requestId);
                if (mounted) {
                  if (ok) {
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Extension approved successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    final errorMsg = provider.error ?? 'Failed to approve extension';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(errorMsg),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red, size: 20),
            tooltip: 'Reject',
            onPressed: () async {
              final ctrl = TextEditingController();
              final reason = await showDialog<String?>(
                context: context,
                builder: (dctx) {
                  return AlertDialog(
                    title: const Text('Reject Extension'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Reject lease extension for ${request.requesterDisplayName}?'),
                        const SizedBox(height: 16),
                        TextField(
                          controller: ctrl,
                          decoration: const InputDecoration(
                            labelText: 'Reason (optional)',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(dctx, null), child: const Text('Cancel')),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(dctx, ctrl.text.trim()),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                        child: const Text('Reject'),
                      ),
                    ],
                  );
                },
              );
              if (reason != null) {
                final ok = await context.read<RentsProvider>().rejectExtension(request.requestId, reason: reason.isEmpty ? null : reason);
                if (ok && mounted) setState(() {});
              }
            },
          ),
        ],
      );
    }
  }

  // Date formatting is provided by AppDateUtils directly in the table rendering.

  Widget _buildBookingFilterPanel(
    BuildContext context,
    Map<String, dynamic> currentFilters,
    FilterController controller,
  ) {
    String? selectedStatus = currentFilters['status'] as String?;
    String? sortBy = currentFilters['sortBy'] as String?;
    bool ascending = (currentFilters['sortDirection'] as String?)?.toLowerCase() != 'desc';

    // Bind the state to the controller
    controller.bind(
      getFilters: () => {
        'status': selectedStatus,
        'sortBy': sortBy,
        'sortDirection': ascending ? 'asc' : 'desc',
      },
      resetFields: () {
        selectedStatus = null;
        sortBy = null;
        ascending = true;
      },
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
            items: [
              const DropdownMenuItem<String>(value: null, child: Text('All Statuses')),
              ...BookingStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status.name,
                  child: Text(status.displayName),
                );
              }),
            ],
            decoration: const InputDecoration(labelText: 'Status'),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          SortOptionsWidget(
            selectedSortBy: sortBy,
            ascending: ascending,
            options: bookingSortOptions,
            onSortByChanged: (value) => setState(() => sortBy = value),
            onAscendingChanged: (value) => setState(() => ascending = value),
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
    String? sortBy = currentFilters['sortBy'] as String?;
    bool ascending = (currentFilters['sortDirection'] as String?)?.toLowerCase() != 'desc';

    // Bind the state to the controller
    controller.bind(
      getFilters: () => {
        'status': selectedStatus,
        'sortBy': sortBy,
        'sortDirection': ascending ? 'asc' : 'desc',
      },
      resetFields: () {
        selectedStatus = null;
        sortBy = null;
        ascending = true;
      },
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
            items: [
              const DropdownMenuItem<String>(value: null, child: Text('All Statuses')),
              ...TenantStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status.name,
                  child: Text(status.displayName),
                );
              }),
            ],
            decoration: const InputDecoration(labelText: 'Status'),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          SortOptionsWidget(
            selectedSortBy: sortBy,
            ascending: ascending,
            options: tenantSortOptions,
            onSortByChanged: (value) => setState(() => sortBy = value),
            onAscendingChanged: (value) => setState(() => ascending = value),
          ),
        ],
      );
    });
  }


  /// Build action buttons for daily rental bookings.
  /// Daily rentals can only be cancelled/rejected - approval is not applicable
  /// since daily bookings are instant (pay-and-book model).
  Widget _buildBookingActions(
    BuildContext context,
    Booking booking,
    RentsProvider provider,
    ListController listController,
  ) {
    // Daily rentals: only show cancel option for upcoming bookings
    // No approval needed - daily bookings are instant transactions
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (booking.status == BookingStatus.upcoming)
          IconButton(
            icon: const Icon(Icons.cancel, color: Colors.red),
            tooltip: 'Cancel Booking',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Cancel Booking'),
                  content: const Text('Are you sure you want to cancel this daily rental booking?'),
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
