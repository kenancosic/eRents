import 'package:flutter/material.dart';
import 'package:e_rents_desktop/base/app_base_screen.dart';
import 'package:e_rents_desktop/models/tenant_preference.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/widgets/custom_table_widget.dart';
import 'package:e_rents_desktop/features/tenants/providers/tenant_provider.dart';
import 'package:e_rents_desktop/widgets/custom_search_bar.dart';
import 'package:e_rents_desktop/services/mock_data_service.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_desktop/features/tenants/widgets/index.dart';
import 'package:e_rents_desktop/features/tenants/widgets/send_property_offer_dialog.dart';

class TenantsScreen extends StatefulWidget {
  const TenantsScreen({super.key});

  @override
  State<TenantsScreen> createState() => _TenantsScreenState();
}

class _TenantsScreenState extends State<TenantsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchTerm = '';
  String _currentFilterField =
      MockDataService.getCurrentTenantFilterFields().first;
  final TextEditingController _searchController = TextEditingController();
  String _searchLabelText = 'Search current tenants: ';

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
      provider
          .loadAllData()
          .then((_) {
            if (mounted) {
              setState(() {});
            }
          })
          .catchError((error) {});
    });
  }

  void _handleTabChange() {
    if (_tabController.index == 0) {
      setState(() {
        _currentFilterField =
            MockDataService.getCurrentTenantFilterFields().first;
        _searchController.clear();
        _searchTerm = '';
        _searchLabelText = 'Search current tenants: ';
      });
    } else {
      setState(() {
        _currentFilterField =
            MockDataService.getSearchingTenantFilterFields().first;
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
              // Tab bar
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
              // Custom search bar with filter options
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
                      tenants: provider.currentTenants,
                      searchTerm: _searchTerm,
                      currentFilterField: _currentFilterField,
                      onSendMessage: _sendMessage,
                      onShowProfile: _showTenantProfile,
                      onNavigateToProperty: _navigateToPropertyDetails,
                    ),
                    TenantsAdvertisementTableWidget(
                      preferences: provider.searchingTenants,
                      tenants: provider.currentTenants,
                      searchTerm: _searchTerm,
                      currentFilterField: _currentFilterField,
                      onSendMessage: _sendMessageToSearchingTenant,
                      onShowDetails: _showTenantPreferenceDetails,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(TenantProvider provider) {
    final List<String> filterFields =
        _tabController.index == 0
            ? MockDataService.getCurrentTenantFilterFields()
            : MockDataService.getSearchingTenantFilterFields();

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
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => context.pop(),
              ),
            ],
          ),
    );
  }

  void _showTenantPreferenceDetails(TenantPreference preference, User tenant) {
    showDialog(
      context: context,
      builder:
          (context) => TenantPreferenceDetailsWidget(
            preference: preference,
            tenant: tenant,
            onSendOffer: () => _sendMessageToSearchingTenant(preference),
          ),
    );
  }

  void _showTenantProfile(User tenant, List<Property>? properties) {
    showDialog(
      context: context,
      builder:
          (context) => TenantProfileWidget(
            tenant: tenant,
            properties: properties,
            onSendMessage: () => _sendMessage(tenant),
          ),
    );
  }

  void _sendMessage(User tenant) {
    context.read<TenantProvider>().sendMessageToTenant(
      tenant.id,
      'Hello, how are you?',
    );
  }

  void _sendMessageToSearchingTenant(TenantPreference preference) {
    showDialog(
      context: context,
      builder:
          (BuildContext dialogContext) =>
              SendPropertyOfferDialog(tenantPreference: preference),
    );
  }

  void _navigateToPropertyDetails(Property property) {
    // Navigate to property details using GoRouter
    context.push('/properties/${property.id}', extra: property);
  }
}
