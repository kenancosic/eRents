import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/tenant_preference.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/widgets/custom_search_bar.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_desktop/features/tenants/widgets/index.dart';
import 'package:e_rents_desktop/features/tenants/widgets/send_property_offer_dialog.dart';
import 'package:e_rents_desktop/base/base_provider.dart'; // For ViewState
import 'package:e_rents_desktop/features/chat/providers/chat_provider.dart';
import 'package:e_rents_desktop/features/tenants/providers/tenant_provider.dart';
import 'package:e_rents_desktop/features/tenants/widgets/index.dart';

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
      final provider = Provider.of<TenantProvider>(context, listen: false);
      // loadAllData already handles setting state to Busy/Idle/Error
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
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.selectContact(tenant.id);
    context.go('/chat/${tenant.id.toString()}');
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
    return Consumer<TenantProvider>(
      builder: (context, provider, child) {
        // Updated loading state check
        if (provider.state == ViewState.Busy &&
            provider.items.isEmpty &&
            provider.searchingTenants.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        // Added error handling
        if (provider.state == ViewState.Error) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  provider.errorMessage ?? 'Failed to load tenant data.',
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.loadAllData(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Use provider.items for current tenants if TenantProvider maps _currentTenants to items_
        final currentTenants = provider.items;
        final searchingTenants = provider.searchingTenants;

        if (currentTenants.isEmpty && searchingTenants.isEmpty) {
          return const Center(
            child: Text(
              'No tenants data available.',
              style: TextStyle(fontSize: 18),
            ),
          );
        }

        return Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Current Tenants'),
                Tab(text: 'Tenants Advertisements'),
              ],
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).colorScheme.primary,
            ),
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
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  CurrentTenantsTableWidget(
                    tenants: currentTenants, // Using updated variable
                    searchTerm: _searchTerm,
                    currentFilterField: _currentFilterField,
                    onSendMessage:
                        (tenant) => _sendMessage(
                          context,
                          tenant,
                        ), // Pass context if needed by impl
                    onShowProfile:
                        (tenant, properties) => _showTenantProfile(
                          context,
                          tenant,
                          properties,
                        ), // Adjusted
                    onNavigateToProperty:
                        (property) => // Adjusted to take Property object
                            _navigateToPropertyDetails(context, property),
                  ),
                  TenantsAdvertisementTableWidget(
                    preferences: searchingTenants, // Using updated variable
                    tenants:
                        currentTenants, // Pass current tenants if needed for context
                    searchTerm: _searchTerm,
                    currentFilterField: _currentFilterField,
                    onSendMessage:
                        (pref) => _sendMessageToSearchingTenant(
                          context,
                          pref,
                        ), // Pass context
                    onShowDetails:
                        (pref, tenant) => _showTenantPreferenceDetails(
                          // Adjusted
                          context,
                          pref,
                          tenant,
                        ), // Pass context
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar(TenantProvider provider) {
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
