import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/tenant_preference.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_desktop/features/tenants/widgets/index.dart';
import 'package:e_rents_desktop/features/tenants/widgets/send_property_offer_dialog.dart';

import 'package:e_rents_desktop/features/tenants/providers/tenants_provider.dart';

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
      final provider = Provider.of<TenantsProvider>(
        context,
        listen: false,
      );
      provider.loadAllData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _sendMessage(BuildContext context, User tenant) {
    // Navigate to chat with contact ID as parameter
    // The chat screen will handle contact selection when it loads
    context.go('/chat?contactId=${tenant.id}');
  }

  void _sendMessageToSearchingTenant(
    BuildContext context,
    TenantPreference preference,
  ) {
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
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return TenantProfileWidget(
          tenant: tenant,
          properties: properties,
          onSendMessage: () {
            Navigator.of(dialogContext).pop();
            _sendMessage(context, tenant);
          },
        );
      },
    );
  }

  void _navigateToPropertyDetails(BuildContext context, Property property) {
    context.push('/properties/${property.propertyId}');
  }

  void _showTenantPreferenceDetails(
    BuildContext context,
    TenantPreference preference,
    User tenant,
  ) {
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
    return Consumer<TenantsProvider>(
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
                  provider.error ?? 'Unknown error occurred',
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
        final tenantPreferences = provider.tenantPreferences;

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
                        const Text('Tenant Advertisements'),
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

              // Tab views - Universal Tables handle their own search
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    CurrentTenantsTableWidget(
                      tenants: currentTenants,
                      searchTerm:
                          '', // No longer used - Universal Table handles search
                      currentFilterField: '', // No longer used
                      onSendMessage: (tenant) => _sendMessage(context, tenant),
                      onShowProfile:
                          (tenant, properties) =>
                              _showTenantProfile(context, tenant, properties),
                      onNavigateToProperty:
                          (property) =>
                              _navigateToPropertyDetails(context, property),
                    ),
                    TenantsAdvertisementTableWidget(
                      preferences: tenantPreferences,
                      tenants: currentTenants,
                      searchTerm:
                          '', // No longer used - Universal Table handles search
                      currentFilterField: '', // No longer used
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
}
