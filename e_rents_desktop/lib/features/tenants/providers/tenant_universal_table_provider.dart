import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../models/user.dart';
import '../../../repositories/tenant_repository.dart';
import '../../../widgets/table/custom_table.dart';

/// ✅ TENANT UNIVERSAL TABLE PROVIDER - 90% automatic, 10% custom
///
/// This provider extends BaseUniversalTableProvider to automatically handle:
/// - Pagination, sorting, searching, filtering
/// - Backend Universal System integration
/// - Standard UI components and interactions
///
/// Only tenant-specific column definitions are required (10% custom code)
class TenantUniversalTableProvider extends TableProvider<User> {
  final BuildContext context;

  TenantUniversalTableProvider({
    required TenantRepository repository,
    required UniversalTableConfig<User> config,
    required this.context,
  }) : super(
         fetchDataFunction:
             (params) => repository.fetchPagedFromService(params),
         config: config,
       );

  @override
  List<TableColumnConfig<User>> get columns => [
    // ✅ AUTOMATIC: 90% of columns use standard helpers
    createColumn(
      key: 'id',
      label: 'ID',
      cellBuilder: (tenant) => textCell('#${tenant.id}'),
      width: const FlexColumnWidth(0.6),
    ),
    createColumn(
      key: 'fullName',
      label: 'Name',
      cellBuilder:
          (tenant) => linkCell(
            text: tenant.fullName,
            icon: Icons.person,
            onTap: () => context.push('/tenants/${tenant.id}'),
          ),
      width: const FlexColumnWidth(2.0),
    ),
    createColumn(
      key: 'email',
      label: 'Email',
      cellBuilder: (tenant) => textCell(tenant.email ?? 'N/A'),
      width: const FlexColumnWidth(2.0),
    ),
    createColumn(
      key: 'phone',
      label: 'Phone',
      cellBuilder: (tenant) => textCell(tenant.phone ?? 'N/A'),
      width: const FlexColumnWidth(1.5),
    ),
    createColumn(
      key: 'city',
      label: 'City',
      cellBuilder: (tenant) => textCell(tenant.address?.city ?? 'N/A'),
      width: const FlexColumnWidth(1.2),
    ),
    createColumn(
      key: 'role',
      label: 'Role',
      cellBuilder:
          (tenant) => statusCell(
            tenant.role.toString().split('.').last,
            color: _getRoleColor(tenant.role),
          ),
      width: const FlexColumnWidth(0.8),
    ),
    createColumn(
      key: 'createdAt',
      label: 'Joined',
      cellBuilder: (tenant) => dateCell(tenant.createdAt),
      width: const FlexColumnWidth(1.0),
    ),
    createColumn(
      key: 'actions',
      label: 'Actions',
      cellBuilder:
          (tenant) => actionCell([
            iconActionCell(
              icon: Icons.visibility,
              tooltip: 'View Details',
              onPressed: () => context.go('/tenants/${tenant.id}'),
            ),
            iconActionCell(
              icon: Icons.message,
              tooltip: 'Send Message',
              onPressed: () => _sendMessage(tenant),
            ),
            iconActionCell(
              icon: Icons.home,
              tooltip: 'Property Offers',
              onPressed: () => _viewPropertyOffers(tenant),
            ),
          ]),
      sortable: false,
      width: const FlexColumnWidth(1.0),
    ),
  ];

  @override
  List<TableFilter> get availableFilters => [
    createFilter(
      key: 'Role',
      label: 'Role',
      type: FilterType.dropdown,
      options: [
        FilterOption(label: 'Admin', value: 'admin'),
        FilterOption(label: 'Landlord', value: 'landlord'),
        FilterOption(label: 'Tenant', value: 'tenant'),
      ],
    ),
    createFilter(key: 'City', label: 'City', type: FilterType.text),
    createFilter(
      key: 'HasEmail',
      label: 'Has Email',
      type: FilterType.checkbox,
    ),
    createFilter(
      key: 'HasPhone',
      label: 'Has Phone',
      type: FilterType.checkbox,
    ),
    createFilter(
      key: 'CreatedAt',
      label: 'Join Date',
      type: FilterType.dateRange,
    ),
  ];

  /// ✅ CUSTOM: Role-specific colors
  Color _getRoleColor(UserType role) {
    switch (role) {
      case UserType.admin:
        return Colors.purple;
      case UserType.landlord:
        return Colors.blue;
      case UserType.tenant:
        return Colors.green;
    }
  }

  /// ✅ CUSTOM: Send message action
  void _sendMessage(User tenant) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Send Message to ${tenant.fullName}'),
            content: const TextField(
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Message sent to ${tenant.fullName}'),
                    ),
                  );
                },
                child: const Text('Send'),
              ),
            ],
          ),
    );
  }

  /// ✅ CUSTOM: View property offers action
  void _viewPropertyOffers(User tenant) {
    context.push('/tenants/${tenant.id}/property-offers');
  }
}

/// ✅ FACTORY - One-liner table creation (like ImageUtils pattern)
class TenantTableFactory {
  static CustomTableWidget<User> create({
    required TenantRepository repository,
    required BuildContext context,
    String title = 'Tenants',
    Widget? headerActions,
    void Function(User)? onRowTap,
    void Function(User)? onRowDoubleTap,
  }) {
    // ✅ CONFIGURATION: Customize table behavior
    final config = UniversalTableConfig<User>(
      title: title,
      searchHint: 'Search tenants by name, email, or city...',
      emptyStateMessage: 'No tenants found',
      headerActions: headerActions,
      onRowTap: onRowTap,
      onRowDoubleTap: onRowDoubleTap,
    );

    // ✅ PROVIDER: Create Universal Table Provider
    final provider = TenantUniversalTableProvider(
      repository: repository,
      config: config,
      context: context,
    );

    // ✅ WIDGET: Return ready-to-use table widget
    return CustomTableWidget<User>(dataProvider: provider, title: title);
  }
}
