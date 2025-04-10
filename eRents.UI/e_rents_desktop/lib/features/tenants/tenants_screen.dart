import 'package:flutter/material.dart';
import 'package:e_rents_desktop/base/app_base_screen.dart';
import 'package:e_rents_desktop/models/tenant_preference.dart';
import 'package:e_rents_desktop/models/tenant_feedback.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/widgets/table_widget.dart';
import 'package:e_rents_desktop/features/tenants/providers/tenant_provider.dart';
import 'package:provider/provider.dart';

class TenantsScreen extends StatefulWidget {
  const TenantsScreen({super.key});

  @override
  State<TenantsScreen> createState() => _TenantsScreenState();
}

class _TenantsScreenState extends State<TenantsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<TenantProvider>(context, listen: false);
      provider
          .loadAllData()
          .then((_) {
            print('Data loaded successfully');
            if (mounted) {
              setState(() {});
            }
          })
          .catchError((error) {
            print('Error loading data: $error');
          });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBaseScreen(
      title: 'Tenants',
      currentPath: '/tenants',
      child: Consumer<TenantProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.currentTenants.isEmpty &&
              provider.searchingTenants.isEmpty) {
            return const Center(
              child: Text('No tenants found', style: TextStyle(fontSize: 18)),
            );
          }

          return Column(
            children: [
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Current Tenants'),
                  Tab(text: 'Searching Tenants'),
                ],
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Theme.of(context).colorScheme.primary,
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCurrentTenantsTable(provider),
                    _buildSearchingTenantsTable(provider),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCurrentTenantsTable(TenantProvider provider) {
    final tenants = provider.currentTenants;

    if (tenants.isEmpty) {
      return const Center(
        child: Text('No current tenants found', style: TextStyle(fontSize: 18)),
      );
    }

    // Define flex-based column widths for proportional distribution
    final columnWidths = <int, TableColumnWidth>{
      0: const FlexColumnWidth(0.8), // Profile - smaller
      1: const FlexColumnWidth(1.2), // Full Name
      2: const FlexColumnWidth(2.0), // Email - wider for email addresses
      3: const FlexColumnWidth(1.2), // Phone
      4: const FlexColumnWidth(1.0), // City
      5: const FlexColumnWidth(0.8), // Actions - smaller
    };

    return TableWidget<User>(
      title: 'Current Tenants',
      data: tenants,
      dataRowHeight: 70, // Increased row height
      columnWidths: columnWidths,
      columns: [
        const DataColumn(label: Text('Profile', softWrap: true, maxLines: 2)),
        const DataColumn(label: Text('Full Name', softWrap: true, maxLines: 2)),
        const DataColumn(label: Text('Email', softWrap: true, maxLines: 2)),
        const DataColumn(label: Text('Phone', softWrap: true, maxLines: 2)),
        const DataColumn(label: Text('City', softWrap: true, maxLines: 2)),
        const DataColumn(label: Text('Actions', softWrap: true, maxLines: 2)),
      ],
      cellsBuilder:
          (tenant) => [
            // Profile column
            DataCell(
              CircleAvatar(
                radius: 20,
                backgroundImage:
                    tenant.profileImage != null
                        ? NetworkImage(tenant.profileImage!)
                        : null,
                child:
                    tenant.profileImage == null
                        ? Text('${tenant.firstName[0]}${tenant.lastName[0]}')
                        : null,
              ),
            ),
            // Full Name column
            DataCell(Text(tenant.fullName, overflow: TextOverflow.ellipsis)),
            // Email column
            DataCell(Text(tenant.email, overflow: TextOverflow.ellipsis)),
            // Phone column
            DataCell(
              Text(tenant.phone ?? 'N/A', overflow: TextOverflow.ellipsis),
            ),
            // City column
            DataCell(
              Text(tenant.city ?? 'N/A', overflow: TextOverflow.ellipsis),
            ),
            // Actions column
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.message,
                      color: Colors.blue,
                      size: 20,
                    ),
                    onPressed: () => _sendMessage(tenant),
                    tooltip: 'Send Message',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.person,
                      color: Colors.green,
                      size: 20,
                    ),
                    onPressed: () => _showTenantProfile(tenant, null),
                    tooltip: 'View Profile',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],
      searchStringBuilder:
          (tenant) =>
              '${tenant.fullName} ${tenant.email} ${tenant.phone ?? ''} ${tenant.city ?? ''}',
      filterOptions: {
        'City':
            provider.currentTenants
                .map((t) => t.city)
                .where((city) => city != null)
                .toSet()
                .map((city) => Filter(label: city!, value: city))
                .toList(),
      },
    );
  }

  Widget _buildSearchingTenantsTable(TenantProvider provider) {
    final searchingTenants = provider.searchingTenants;

    if (searchingTenants.isEmpty) {
      return const Center(
        child: Text(
          'No searching tenants found',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    // Define column width ratios for better distribution across full width
    final columnWidths = <int, TableColumnWidth>{
      0: const FlexColumnWidth(0.8), // City
      1: const FlexColumnWidth(1.0), // Price Range
      2: const FlexColumnWidth(1.5), // Amenities
      3: const FlexColumnWidth(2.5), // Description - wider for more text
      4: const FlexColumnWidth(1.2), // Search Period
      5: const FlexColumnWidth(0.5), // Actions - smallest
    };

    return TableWidget<TenantPreference>(
      title: 'Searching Tenants',
      data: searchingTenants,
      dataRowHeight: 80, // Increased height for amenities
      columnWidths: columnWidths,
      columns: [
        const DataColumn(label: Text('City', softWrap: true, maxLines: 2)),
        const DataColumn(
          label: Text('Price Range', softWrap: true, maxLines: 2),
        ),
        const DataColumn(label: Text('Amenities', softWrap: true, maxLines: 2)),
        const DataColumn(
          label: Text('Description', softWrap: true, maxLines: 2),
        ),
        const DataColumn(
          label: Text('Search Period', softWrap: true, maxLines: 2),
        ),
        const DataColumn(label: Text('Actions', softWrap: true, maxLines: 2)),
      ],
      cellsBuilder:
          (preference) => [
            // City Column
            DataCell(Text(preference.city, overflow: TextOverflow.ellipsis)),
            // Price Range Column
            DataCell(
              Text(
                '${preference.minPrice != null ? '\$${preference.minPrice}' : 'Any'} - '
                '${preference.maxPrice != null ? '\$${preference.maxPrice}' : 'Any'}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Amenities Column
            DataCell(
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  ...preference.amenities
                      .take(3)
                      .map(
                        (a) => Chip(
                          label: Text(a, style: const TextStyle(fontSize: 10)),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                  if (preference.amenities.length > 3)
                    Chip(
                      label: Text(
                        '+${preference.amenities.length - 3}',
                        style: const TextStyle(fontSize: 10),
                      ),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
              placeholder: false,
            ),
            // Description Column
            DataCell(
              Text(
                preference.description.length > 50
                    ? '${preference.description.substring(0, 50)}...'
                    : preference.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Search Period Column
            DataCell(
              Text(
                '${preference.searchStartDate.year}-${preference.searchStartDate.month} to '
                '${preference.searchEndDate?.year ?? 'Open'}-${preference.searchEndDate?.month ?? ''}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Actions Column
            DataCell(
              IconButton(
                icon: const Icon(Icons.send, color: Colors.blue, size: 20),
                onPressed: () => _sendMessageToSearchingTenant(preference),
                tooltip: 'Send Property Offer',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ],
      searchStringBuilder:
          (preference) => '${preference.city} ${preference.description}',
      filterOptions: {
        'City':
            provider.searchingTenants
                .map((p) => p.city)
                .toSet()
                .map((city) => Filter(label: city, value: city))
                .toList(),
      },
    );
  }

  void _showTenantProfile(User tenant, List<Property>? properties) {
    final provider = Provider.of<TenantProvider>(context, listen: false);
    provider.loadTenantFeedbacks(tenant.id);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage:
                      tenant.profileImage != null
                          ? NetworkImage(tenant.profileImage!)
                          : null,
                  child:
                      tenant.profileImage == null
                          ? Text('${tenant.firstName[0]}${tenant.lastName[0]}')
                          : null,
                ),
                const SizedBox(width: 12),
                Text(tenant.fullName),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildProfileSection(tenant),
                  if (properties != null && properties.isNotEmpty)
                    _buildPropertiesSection(properties),
                  _buildFeedbackSection(tenant),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () => _sendMessage(tenant),
                child: const Text('Send Message'),
              ),
            ],
          ),
    );
  }

  Widget _buildProfileSection(User tenant) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Profile Information',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text('Email: ${tenant.email}'),
        if (tenant.phone != null) Text('Phone: ${tenant.phone}'),
        if (tenant.city != null) Text('City: ${tenant.city}'),
        const Divider(),
      ],
    );
  }

  Widget _buildPropertiesSection(List<Property> properties) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Current Properties',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...properties.map(
          (property) => ListTile(
            title: Text(property.title),
            subtitle: Text(property.address),
            trailing: Text('\$${property.price}/month'),
          ),
        ),
        const Divider(),
      ],
    );
  }

  Widget _buildFeedbackSection(User tenant) {
    return Consumer<TenantProvider>(
      builder: (context, provider, child) {
        final feedbacks = provider.getTenantFeedbacks(tenant.id);
        if (feedbacks.isEmpty) {
          return const Text('No feedback available');
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Previous Landlord Feedback',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...feedbacks.map(
              (feedback) => ListTile(
                title: Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      Icons.star,
                      size: 18,
                      color:
                          index < feedback.rating
                              ? Colors.amber
                              : Colors.grey[300],
                    ),
                  ),
                ),
                subtitle: Text(feedback.comment),
                trailing: Text(
                  '${feedback.stayStartDate.year}-${feedback.stayEndDate.year}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _sendMessage(User tenant) {
    context.read<TenantProvider>().sendMessageToTenant(
      tenant.id,
      'Hello, how are you?',
    );
  }

  void _sendMessageToSearchingTenant(TenantPreference preference) {
    context.read<TenantProvider>().sendMessageToTenant(
      preference.userId,
      'Hello, I have a property that might interest you!',
    );
  }
}
