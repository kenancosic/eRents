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
  final List<String> _searchHistory = [];
  String _searchLabelText = 'Search current tenants: ';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
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
        _searchTerm = ''; // Clear search when changing tabs
        _searchLabelText = 'Search current tenants: ';
      });
    } else {
      setState(() {
        _currentFilterField =
            MockDataService.getSearchingTenantFilterFields().first;
        _searchTerm = ''; // Clear search when changing tabs
        _searchLabelText = 'Search tenants advertisements: ';
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
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

    // Create a list of search strings based on the current tab and filter field
    List<String> searchStrings = [];

    // Get mock properties for mapping tenant to properties
    final properties = MockDataService.getMockProperties();

    // For demonstration, assign properties to tenants based on index
    final Map<String, Property> tenantProperties = {};
    for (int i = 0; i < provider.currentTenants.length; i++) {
      // Assign property in a round-robin fashion
      tenantProperties[provider.currentTenants[i].id] =
          properties[i % properties.length];
    }

    if (_tabController.index == 0) {
      searchStrings =
          provider.currentTenants.map((tenant) {
            switch (_currentFilterField) {
              case 'Full Name':
                return tenant.fullName;
              case 'Email':
                return tenant.email;
              case 'Phone':
                return tenant.phone ?? '';
              case 'City':
                return tenant.city ?? '';
              default:
                return tenant.fullName;
            }
          }).toList();
    } else {
      searchStrings =
          provider.searchingTenants.map((preference) {
            switch (_currentFilterField) {
              case 'City':
                return preference.city;
              case 'Price Range':
                return '${preference.minPrice ?? "Any"} - ${preference.maxPrice ?? "Any"}';
              case 'Amenities':
                return preference.amenities.join(', ');
              case 'Description':
                return preference.description;
              default:
                return preference.city;
            }
          }).toList();
    }

    return CustomSearchBar<String>(
      hintText: 'Enter $_currentFilterField...',
      searchHistory: _searchHistory,
      localData: searchStrings,
      showFilterIcon: true,
      onSearchChanged: (value) {
        setState(() {
          _searchTerm = value;
          if (value.isNotEmpty && !_searchHistory.contains(value)) {
            _searchHistory.add(value);
            if (_searchHistory.length > 5) {
              _searchHistory.removeAt(0); // Keep history size manageable
            }
          }
        });
      },
      onFilterIconPressed: () {
        _showFilterOptionsDialog(context, filterFields);
      },
      customSuggestionBuilder: (suggestion, controller, onSelected) {
        // For current tenants tab
        if (_tabController.index == 0) {
          // Find the tenant that matches this suggestion
          final tenant = provider.currentTenants.firstWhere((t) {
            switch (_currentFilterField) {
              case 'Full Name':
                return t.fullName == suggestion;
              case 'Email':
                return t.email == suggestion;
              case 'Phone':
                return t.phone == suggestion;
              case 'City':
                return t.city == suggestion;
              default:
                return t.fullName == suggestion;
            }
          }, orElse: () => provider.currentTenants.first);

          // Get property for this tenant
          final property = tenantProperties[tenant.id];

          return ListTile(
            leading: CircleAvatar(
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
            title: Row(
              children: [
                Text(
                  tenant.fullName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${property?.title ?? 'No property'})',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
            onTap: () {
              controller.text = suggestion;
              onSelected(suggestion);
            },
          );
        }
        // For searching tenants tab
        else {
          // Find the tenant preference that matches this suggestion
          final preference = provider.searchingTenants.firstWhere((p) {
            switch (_currentFilterField) {
              case 'City':
                return p.city == suggestion;
              case 'Price Range':
                final priceRange =
                    '${p.minPrice ?? "Any"} - ${p.maxPrice ?? "Any"}';
                return priceRange == suggestion;
              case 'Amenities':
                return p.amenities.join(', ') == suggestion;
              case 'Description':
                return p.description == suggestion;
              default:
                return p.city == suggestion;
            }
          }, orElse: () => provider.searchingTenants.first);

          // Find the user associated with this preference
          final user = provider.currentTenants.firstWhere(
            (u) => u.id == preference.userId,
            orElse:
                () => User(
                  id: 'unknown',
                  email: 'unknown@example.com',
                  firstName: 'Unknown',
                  lastName: 'User',
                  role: 'tenant',
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
          );

          return ListTile(
            leading: CircleAvatar(
              radius: 20,
              backgroundImage:
                  user.profileImage != null
                      ? NetworkImage(user.profileImage!)
                      : null,
              child:
                  user.profileImage == null
                      ? Text('${user.firstName[0]}${user.lastName[0]}')
                      : null,
            ),
            title: Row(
              children: [
                Text(
                  user.fullName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Text(
                  '($_currentFilterField: $suggestion)',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
            onTap: () {
              controller.text = suggestion;
              onSelected(suggestion);
            },
          );
        }
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
                            _searchTerm =
                                ''; // Reset search when changing filter field
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
    context.read<TenantProvider>().sendMessageToTenant(
      preference.userId,
      'Hello, I have a property that might interest you!',
    );
  }

  void _navigateToPropertyDetails(Property property) {
    // Navigate to property details using GoRouter
    context.go('/properties/${property.id}', extra: property);
  }
}
