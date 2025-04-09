import 'package:flutter/material.dart';
import 'package:e_rents_desktop/base/app_base_screen.dart';
import 'package:e_rents_desktop/models/tenant_preference.dart';
import 'package:e_rents_desktop/models/tenant_feedback.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/widgets/tenant_widgets.dart';
import 'package:e_rents_desktop/features/tenants/providers/tenant_provider.dart';
import 'package:provider/provider.dart';

class TenantsScreen extends StatefulWidget {
  const TenantsScreen({super.key});

  @override
  State<TenantsScreen> createState() => _TenantsScreenState();
}

class _TenantsScreenState extends State<TenantsScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCity;
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  late TabController _tabController;

  final List<String> _availableCities = const [
    'New York',
    'Los Angeles',
    'Chicago',
    'Boston',
    'Seattle',
  ];

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
    _searchController.dispose();
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
              TenantSearchBar(
                searchController: _searchController,
                selectedCity: _selectedCity,
                cities: _availableCities,
                onCityChanged: (city) => setState(() => _selectedCity = city),
                onSearch:
                    () => setState(() => _searchQuery = _searchController.text),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCurrentTenantsTab(provider),
                    _buildSearchingTenantsTab(provider),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCurrentTenantsTab(TenantProvider provider) {
    final tenants = provider.currentTenants;

    // Apply filters and pagination
    final filteredTenants =
        tenants.where((tenant) {
          final matchesSearch = tenant.fullName.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
          final matchesCity =
              _selectedCity == null || tenant.city == _selectedCity;
          return matchesSearch && matchesCity;
        }).toList();

    final totalPages = (filteredTenants.length / _itemsPerPage).ceil();
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    final paginatedTenants = filteredTenants.sublist(
      startIndex,
      endIndex > filteredTenants.length ? filteredTenants.length : endIndex,
    );

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: paginatedTenants.length,
            itemBuilder:
                (context, index) => TenantCard(
                  tenant: paginatedTenants[index],
                  isCurrentTenant: true,
                  onMessage: () => _sendMessage(paginatedTenants[index]),
                  onViewProfile:
                      () => _showTenantProfile(paginatedTenants[index], null),
                ),
          ),
        ),
        PaginationControls(
          currentPage: _currentPage,
          totalPages: totalPages,
          onPrevious:
              _currentPage > 1 ? () => setState(() => _currentPage--) : null,
          onNext:
              _currentPage < totalPages
                  ? () => setState(() => _currentPage++)
                  : null,
        ),
      ],
    );
  }

  Widget _buildSearchingTenantsTab(TenantProvider provider) {
    final searchingTenants = provider.searchingTenants;

    // Apply filters
    final filteredTenants =
        searchingTenants.where((preference) {
          final matchesSearch = preference.city.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
          final matchesCity =
              _selectedCity == null || preference.city == _selectedCity;
          return matchesSearch && matchesCity;
        }).toList();

    return ListView.builder(
      itemCount: filteredTenants.length,
      itemBuilder:
          (context, index) => TenantPreferenceCard(
            preference: filteredTenants[index],
            onSendOffer:
                () => _sendMessageToSearchingTenant(filteredTenants[index]),
          ),
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
              (feedback) => TenantFeedbackCard(feedback: feedback),
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
