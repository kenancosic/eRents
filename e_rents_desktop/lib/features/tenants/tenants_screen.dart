import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/tenant_preference.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/widgets/custom_search_bar.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_desktop/features/tenants/widgets/index.dart';
import 'package:e_rents_desktop/features/tenants/widgets/send_property_offer_dialog.dart';
import 'package:e_rents_desktop/features/chat/providers/chat_collection_provider.dart';
import 'package:e_rents_desktop/features/tenants/providers/tenant_collection_provider.dart';

class TenantsScreen extends StatefulWidget {
  const TenantsScreen({super.key});

  @override
  State<TenantsScreen> createState() => _TenantsScreenState();
}

class _TenantsScreenState extends State<TenantsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchTerm = '';
  String _currentFilterField = 'Full Name'; // Default placeholder
  final TextEditingController _searchController = TextEditingController();
  String _searchLabelText = 'Search current tenants: ';

  // Placeholder filter fields
  final List<String> _currentTenantFilterFields = [
    'Full Name',
    'Email',
    'Phone',
    'City',
  ];
  final List<String> _searchingTenantFilterFields = [
    'City',
    'Price Range',
    'Amenities',
    'Description',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _searchController.addListener(() {
      if (_searchTerm != _searchController.text) {
        setState(() {
          _searchTerm = _searchController.text;
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<TenantCollectionProvider>(
        context,
        listen: false,
      );
      // loadAllData already handles setting state management
      provider.loadAllData();
    });
  }

  void _handleTabChange() {
    if (_tabController.index == 0) {
      setState(() {
        _currentFilterField =
            _currentTenantFilterFields.first; // Use placeholder
        _searchController.clear();
        _searchTerm = '';
        _searchLabelText = 'Search current tenants: ';
      });
    } else {
      setState(() {
        _currentFilterField =
            _searchingTenantFilterFields.first; // Use placeholder
        _searchController.clear();
        _searchTerm = '';
        _searchLabelText = 'Search tenants advertisements: ';
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _sendMessage(BuildContext context, User tenant) {
    // TODO: Implement direct message to tenant or open chat screen
    // Consider using ChatProvider or navigating to a chat screen with tenant.id
    print("Attempting to send message to tenant: ${tenant.fullName}");
    // Example: context.go('/chat/${tenant.id}');
    // Or show a dialog to compose a message, then use ChatProvider.
    final chatProvider = Provider.of<ChatCollectionProvider>(
      context,
      listen: false,
    );
    chatProvider.selectContact(tenant.id);
    context.go('/chat');
  }

  void _sendMessageToSearchingTenant(
    BuildContext context,
    TenantPreference preference,
  ) {
    // TODO: Implement how to contact a searching tenant.
    // This might involve finding the user associated with the preference first,
    // then initiating a chat or offer.
    print(
      "Attempting to contact searching tenant for preference in: ${preference.city}",
    );
    // Example: showSendPropertyOfferDialog(context, preference.userId, availablePropertiesFromSomewhere);
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return SendPropertyOfferDialog(tenantPreference: preference);
      },
    );
  }

  void _showTenantProfile(
    BuildContext context,
    User tenant,
    List<Property> properties,
  ) {
    print("Show profile for tenant: ${tenant.fullName}");

    // Show the tenant profile dialog
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return TenantProfileWidget(
          tenant: tenant,
          properties: properties,
          onSendMessage: () {
            // Close dialog first
            Navigator.of(dialogContext).pop();
            // Then navigate to chat
            _sendMessage(context, tenant);
          },
        );
      },
    );
  }

  void _navigateToPropertyDetails(BuildContext context, Property property) {
    print(
      'TenantsScreen: Navigating to property details for property ID: ${property.id}',
    );
    print('TenantsScreen: Property title: ${property.title}');
    print('TenantsScreen: Full property data: ${property.toString()}');
    context.push('/properties/${property.id}');
  }

  void _showTenantPreferenceDetails(
    BuildContext context,
    TenantPreference preference,
    User tenant, // Added User parameter
  ) {
    // Show the tenant preference details dialog
    showDialog(
      context: context,
      builder:
          (context) => TenantPreferenceDetailsDialog(
            preference: preference,
            tenant: tenant,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TenantCollectionProvider>(
      builder: (context, provider, child) {
        // Show loading screen during initial data load
        if (provider.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading tenant data...', style: TextStyle(fontSize: 16)),
              ],
            ),
          );
        }

        // Show error state with retry option
        if (provider.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(
                  'Failed to load tenant data',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  provider.error?.message ?? 'Unknown error occurred',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => provider.refreshAllData(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () => context.go('/'),
                      child: const Text('Go to Dashboard'),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        final currentTenants = provider.currentTenants;
        final searchingTenants = provider.prospectiveTenants;

        // Always show the tables - even with 0 data
        // Remove empty state check that was preventing tables from showing
        return RefreshIndicator(
          onRefresh: () => provider.refreshAllData(),
          child: Column(
            children: [
              // Tab bar
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Current Tenants'),
                        if (provider.isLoading) ...[
                          const SizedBox(width: 8),
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Tenants Advertisements'),
                        if (provider.isLoadingProspective) ...[
                          const SizedBox(width: 8),
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Theme.of(context).colorScheme.primary,
              ),

              // Search bar with refresh button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _searchLabelText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _buildSearchBar(provider)),
                    const SizedBox(width: 12),
                    // Tab-specific refresh button
                    IconButton(
                      onPressed: () {
                        if (_tabController.index == 0) {
                          provider.refreshCurrentTenants();
                        } else {
                          provider.refreshProspectiveTenants();
                        }
                      },
                      icon: Icon(
                        Icons.refresh,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      tooltip: 'Refresh current tab',
                    ),
                  ],
                ),
              ),

              // Tab views - always show tables
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    CurrentTenantsTableWidget(
                      tenants: currentTenants,
                      searchTerm: _searchTerm,
                      currentFilterField: _currentFilterField,
                      onSendMessage: (tenant) => _sendMessage(context, tenant),
                      onShowProfile:
                          (tenant, properties) =>
                              _showTenantProfile(context, tenant, properties),
                      onNavigateToProperty:
                          (property) =>
                              _navigateToPropertyDetails(context, property),
                    ),
                    TenantsAdvertisementTableWidget(
                      preferences: searchingTenants,
                      tenants: currentTenants,
                      searchTerm: _searchTerm,
                      currentFilterField: _currentFilterField,
                      onSendMessage:
                          (pref) =>
                              _sendMessageToSearchingTenant(context, pref),
                      onShowDetails:
                          (pref, tenant) => _showTenantPreferenceDetails(
                            context,
                            pref,
                            tenant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(TenantCollectionProvider provider) {
    final List<String> filterFields =
        _tabController.index == 0
            ? _currentTenantFilterFields
            : _searchingTenantFilterFields;

    return CustomSearchBar(
      controller: _searchController,
      hintText: 'Enter $_currentFilterField...',
      onFilterPressed: () {
        _showFilterOptionsDialog(context, filterFields);
      },
    );
  }

  void _showFilterOptionsDialog(
    BuildContext context,
    List<String> filterFields,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Search by Field'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children:
                    filterFields.map((field) {
                      return RadioListTile<String>(
                        title: Text(field),
                        value: field,
                        groupValue: _currentFilterField,
                        onChanged: (value) {
                          setState(() {
                            _currentFilterField = value!;
                          });
                          context.pop();
                        },
                      );
                    }).toList(),
              ),
            ),
          ),
    );
  }
}
