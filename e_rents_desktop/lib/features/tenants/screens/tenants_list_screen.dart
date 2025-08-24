import 'package:e_rents_desktop/features/tenants/providers/tenants_provider.dart';
import 'package:e_rents_desktop/models/tenant.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/base/crud/list_screen.dart';
import 'package:e_rents_desktop/presentation/status_pill.dart';
import 'package:e_rents_desktop/utils/date_utils.dart';
import 'package:e_rents_desktop/router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class TenantsListScreen extends StatefulWidget {
  const TenantsListScreen({super.key});

  @override
  State<TenantsListScreen> createState() => _TenantsListScreenState();
}

class _TenantsListScreenState extends State<TenantsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Initial loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TenantsProvider>();
      provider.getPagedTenants();
      provider.getPagedProspectives();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TenantsProvider>(
      builder: (context, tenants, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Tenants'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Current Tenants'),
                Tab(text: 'Prospective Tenants'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _CurrentTenantsTab(provider: tenants),
              _ProspectiveTenantsTab(provider: tenants),
            ],
          ),
        );
      },
    );
  }
}

class _CurrentTenantsTab extends StatefulWidget {
  const _CurrentTenantsTab({required this.provider});
  final TenantsProvider provider;

  @override
  State<_CurrentTenantsTab> createState() => _CurrentTenantsTabState();
}

class _CurrentTenantsTabState extends State<_CurrentTenantsTab> {
  // Local state to support client-side filtering (username/name and city)
  String _cityFilter = '';
  // Lease date filters (forwarded to backend)
  DateTime? _leaseStartFrom;
  DateTime? _leaseStartTo;
  DateTime? _leaseEndFrom;
  DateTime? _leaseEndTo;

  Future<void> _pickDate(BuildContext context, {
    required DateTime? initial,
    required void Function(DateTime?) onPicked,
  }) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 5);
    final lastDate = DateTime(now.year + 5);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    onPicked(picked);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    return ListScreen<Tenant>(
      embedded: true,
      title: 'Current Tenants',
      enablePagination: true,
      pageSize: provider.pageSize,
      inlineSearchBar: true,
      inlineSearchHint: 'Search by username or name',
      searchParamKey: 'search',
      showFilters: true,
      filterBuilder: (ctx, currentFilters, controller) {
        // Bind the dialog controls to controller so the dialog actions can retrieve/reset values
        controller.bind(
          getFilters: () {
            final map = <String, dynamic>{};
            if (_cityFilter.trim().isNotEmpty) {
              map['CityContains'] = _cityFilter.trim();
            }
            if (_leaseStartFrom != null) map['LeaseStartFrom'] = AppDateUtils.formatISO(_leaseStartFrom);
            if (_leaseStartTo != null) map['LeaseStartTo'] = AppDateUtils.formatISO(_leaseStartTo);
            if (_leaseEndFrom != null) map['LeaseEndFrom'] = AppDateUtils.formatISO(_leaseEndFrom);
            if (_leaseEndTo != null) map['LeaseEndTo'] = AppDateUtils.formatISO(_leaseEndTo);
            return map;
          },
          resetFields: () {
            setState(() {
              _cityFilter = '';
              _leaseStartFrom = null;
              _leaseStartTo = null;
              _leaseEndFrom = null;
              _leaseEndTo = null;
            });
          },
        );

        InputDecoration _dec(String label, {Widget? suffix}) => InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon: suffix,
        );

        Widget _dateField(String label, DateTime? value, void Function(DateTime?) onPicked) {
          return TextField(
            controller: TextEditingController(text: value != null ? AppDateUtils.formatISO(value) : ''),
            readOnly: true,
            decoration: _dec(label, suffix: IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () => _pickDate(context, initial: value, onPicked: onPicked),
            )),
            onTap: () => _pickDate(context, initial: value, onPicked: onPicked),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Expanded(
                  child: TextField(
                    decoration: _dec('City'),
                    controller: TextEditingController(text: _cityFilter),
                    onChanged: (v) => _cityFilter = v,
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _dateField('Lease Start From', _leaseStartFrom, (d) => _leaseStartFrom = d)),
                const SizedBox(width: 12),
                Expanded(child: _dateField('Lease Start To', _leaseStartTo, (d) => _leaseStartTo = d)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _dateField('Lease End From', _leaseEndFrom, (d) => _leaseEndFrom = d)),
                const SizedBox(width: 12),
                Expanded(child: _dateField('Lease End To', _leaseEndTo, (d) => _leaseEndTo = d)),
              ]),
            ],
          ),
        );
      },
      // All filtering is performed on the backend now
      filterFunction: (item) => true,
      itemBuilder: (ctx, item) => const SizedBox.shrink(),
      fetchItems: ({int page = 1, int pageSize = 20, Map<String, dynamic>? filters}) async {
        // Translate simple search input to API filters
        final map = <String, dynamic>{...(filters ?? {})};
        final q = (map['search'] as String?)?.trim() ?? '';
        // Forward search to backend as UsernameContains and NameContains
        if (q.isNotEmpty) {
          map['UsernameContains'] = q;
          map['NameContains'] = q;
        }
        if (map.containsKey('search')) map.remove('search');
        // City filter: forward to backend
        _cityFilter = (map['CityContains'] as String?) ?? _cityFilter;
        // Default to "current as of tomorrow": leases that include tomorrow
        // Backend expects DateOnly (yyyy-MM-dd) values
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        map.putIfAbsent('TenantStatus', () => 'Active');
        map.putIfAbsent('LeaseStartTo', () => AppDateUtils.formatISO(tomorrow));
        map.putIfAbsent('LeaseEndFrom', () => AppDateUtils.formatISO(tomorrow));
        // Forward lease date filters from dialog (override defaults if provided)
        if (_leaseStartFrom != null) map['LeaseStartFrom'] = AppDateUtils.formatISO(_leaseStartFrom);
        if (_leaseStartTo != null) map['LeaseStartTo'] = AppDateUtils.formatISO(_leaseStartTo);
        if (_leaseEndFrom != null) map['LeaseEndFrom'] = AppDateUtils.formatISO(_leaseEndFrom);
        if (_leaseEndTo != null) map['LeaseEndTo'] = AppDateUtils.formatISO(_leaseEndTo);
        final paged = await provider.getPagedTenants(params: {
          ...map,
          'page': page,
          'pageSize': pageSize,
        });
        return paged.items;
      },
      onItemTap: (_) {},
      tableColumns: const [
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('Username')),
        DataColumn(label: Text('Property')),
        DataColumn(label: Text('City')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Lease')),
        DataColumn(label: Text('Actions')),
      ],
      tableRowsBuilder: (ctx, items) {
        Color _statusBg(TenantStatus s) {
          switch (s) {
            case TenantStatus.active:
              return Colors.green;
            case TenantStatus.inactive:
              return Colors.grey;
            case TenantStatus.evicted:
              return Colors.redAccent;
            case TenantStatus.leaseEnded:
              return Colors.amber;
          }
        }

        IconData _statusIcon(TenantStatus s) {
          switch (s) {
            case TenantStatus.active:
              return Icons.check_circle_outline;
            case TenantStatus.inactive:
              return Icons.pause_circle_outline;
            case TenantStatus.evicted:
              return Icons.block;
            case TenantStatus.leaseEnded:
              return Icons.hourglass_bottom;
          }
        }

        return items.map((t) {
          final name = t.user?.fullName.isNotEmpty == true
              ? t.user!.fullName
              : '-';
          final username = t.user?.username.isNotEmpty == true
              ? t.user!.username
              : (t.user?.email ?? '-');
          final propertyName = t.property?.name ?? '-';
          final city = t.property?.address?.city ?? '-';
          final lease = AppDateUtils.formatBookingPeriod(
              t.leaseStartDate, t.leaseEndDate);

          return DataRow(cells: [
            DataCell(Text(name)),
            DataCell(Text(username)),
            DataCell(
              InkWell(
                onTap: (t.propertyId ?? 0) > 0
                    ? () => context.go('${AppRoutes.properties}/${t.propertyId}')
                    : null,
                child: Text(
                  propertyName,
                  style: TextStyle(
                    color: (t.propertyId ?? 0) > 0 ? Colors.blue : Colors.black,
                    decoration: (t.propertyId ?? 0) > 0 ? TextDecoration.underline : TextDecoration.none,
                  ),
                ),
              ),
            ),
            DataCell(Text(city)),
            DataCell(
              StatusPill(
                label: t.tenantStatus.displayName,
                backgroundColor: _statusBg(t.tenantStatus),
                iconData: _statusIcon(t.tenantStatus),
              ),
            ),
            DataCell(Text(lease)),
            DataCell(Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Message',
                  icon: const Icon(Icons.chat_bubble_outline),
                  onPressed: () {
                    final contactId = t.userId; // Chat expects user id
                    context.go('${AppRoutes.chat}?contactId=$contactId');
                  },
                ),
              ],
            )),
          ]);
        }).toList();
      },
    );
  }
}

class _ProspectiveTenantsTab extends StatefulWidget {
  const _ProspectiveTenantsTab({required this.provider});
  final TenantsProvider provider;

  @override
  State<_ProspectiveTenantsTab> createState() => _ProspectiveTenantsTabState();
}

class _ProspectiveTenantsTabState extends State<_ProspectiveTenantsTab> {
  // No local filters for prospective tenants; backend provides paginated public users

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    return ListScreen<User>(
      embedded: true,
      title: 'Prospective Tenants',
      enablePagination: true,
      pageSize: provider.pageSize,
      inlineSearchBar: true,
      inlineSearchHint: 'Search by city',
      searchParamKey: 'search',
      showFilters: false,
      itemBuilder: (ctx, item) => const SizedBox.shrink(),
      fetchItems: ({int page = 1, int pageSize = 20, Map<String, dynamic>? filters}) async {
        final map = <String, dynamic>{...(filters ?? {})};
        final q = (map['search'] as String?)?.trim() ?? '';
        if (q.isNotEmpty) {
          map['CityContains'] = q;
          map.remove('search');
        }
        final paged = await provider.getPagedProspectives(params: {
          ...map,
          'page': page,
          'pageSize': pageSize,
        });
        return paged.items;
      },
      onItemTap: (_) {},
      tableColumns: const [
        DataColumn(label: Text('Username')),
        DataColumn(label: Text('Email')),
        DataColumn(label: Text('City')),
        DataColumn(label: Text('Public')),
        DataColumn(label: Text('Actions')),
      ],
      tableRowsBuilder: (ctx, items) {
        return items.map((u) => DataRow(cells: [
              DataCell(Text(u.username.isNotEmpty ? u.username : u.email)),
              DataCell(Text(u.email)),
              DataCell(Text(u.address?.city ?? '-')),
              DataCell(Text(u.isPublic == true ? 'Yes' : 'No')),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Message',
                    icon: const Icon(Icons.chat_bubble_outline),
                    onPressed: () {
                      final contactId = u.userId; // Chat expects user id
                      context.go('${AppRoutes.chat}?contactId=$contactId');
                    },
                  ),
                ],
              )),
            ])).toList();
      },
    );
  }
}