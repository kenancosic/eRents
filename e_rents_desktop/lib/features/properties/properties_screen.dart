import 'package:provider/provider.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/renting_type.dart';
import 'package:e_rents_desktop/features/properties/providers/property_collection_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_desktop/widgets/custom_search_bar.dart';
import 'package:e_rents_desktop/widgets/confirmation_dialog.dart';
import 'package:e_rents_desktop/widgets/loading_or_error_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:e_rents_desktop/base/provider_state.dart';
import 'package:flutter/material.dart';
import 'package:e_rents_desktop/features/properties/widgets/property_card.dart';

class PropertiesScreen extends StatefulWidget {
  const PropertiesScreen({super.key});

  @override
  State<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends State<PropertiesScreen> {
  bool _isListView = true;
  final TextEditingController _searchController = TextEditingController();
  List<Property> _filteredProperties = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _filterProperties(_searchController.text);
    });

    // Initialize filtered properties with current data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PropertyCollectionProvider>();
      setState(() {
        _filteredProperties = provider.items;
      });

      // If provider is idle and has no data, trigger initial paginated load
      if (provider.state == ProviderState.idle && provider.items.isEmpty) {
        provider.loadPaginatedProperties(pageSize: 25);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterProperties(String query) {
    final provider = context.read<PropertyCollectionProvider>();
    final lowerCaseQuery = query.toLowerCase();

    List<Property> newlyFiltered;
    if (query.isEmpty) {
      newlyFiltered = provider.items;
    } else {
      newlyFiltered =
          provider.items.where((property) {
            return property.name.toLowerCase().contains(lowerCaseQuery);
          }).toList();
    }

    if (!listEquals(_filteredProperties, newlyFiltered)) {
      setState(() {
        _filteredProperties = newlyFiltered;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PropertyCollectionProvider>(
      builder: (context, provider, child) {
        // Update _filteredProperties when provider.items changes
        if (_searchController.text.isEmpty &&
            !listEquals(_filteredProperties, provider.items)) {
          _filteredProperties = provider.items;
        }

        return LoadingOrErrorWidget(
          isLoading:
              provider.state == ProviderState.loading &&
              _filteredProperties.isEmpty,
          error: provider.error?.message,
          onRetry: () async {
            await provider.loadPaginatedProperties(pageSize: 25);
            // After fetching, ensure to update _filteredProperties
            if (mounted) {
              _filterProperties(_searchController.text);
            }
          },
          child: Column(
            children: [
              _buildHeaderSection(context, _filteredProperties),
              Expanded(
                child:
                    _filteredProperties.isEmpty
                        ? _buildEmptyListMessage()
                        : _isListView
                        ? _buildListView(_filteredProperties)
                        : _buildGridView(_filteredProperties),
              ),
              if (provider.totalPages > 1) _buildPaginationControls(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderSection(BuildContext context, List<Property> properties) {
    return Consumer<PropertyCollectionProvider>(
      builder: (context, provider, _) {
        // Build count text with pagination info
        String countText;
        if (provider.totalCount > 0) {
          final startItem = (provider.currentPage * provider.pageSize) + 1;
          final endItem = ((provider.currentPage + 1) * provider.pageSize)
              .clamp(0, provider.totalCount);
          countText =
              'Showing $startItem-$endItem of ${provider.totalCount} properties';
        } else {
          countText = 'No properties found';
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomSearchBar(
                controller: _searchController,
                hintText: 'Search Properties by Name...',
                onChanged: _filterProperties,
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 600) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          countText,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            IconButton(
                              icon: Icon(
                                _isListView ? Icons.grid_view : Icons.list,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isListView = !_isListView;
                                });
                              },
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _navigateToAddProperty(context),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Property'),
                            ),
                          ],
                        ),
                      ],
                    );
                  } else {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          countText,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Wrap(
                          spacing: 8,
                          children: [
                            IconButton(
                              icon: Icon(
                                _isListView ? Icons.grid_view : Icons.list,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isListView = !_isListView;
                                });
                              },
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _navigateToAddProperty(context),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Property'),
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildListView(List<Property> properties) {
    return ListView.builder(
      itemCount: properties.length,
      itemBuilder: (context, index) {
        final property = properties[index];
        return PropertyCard(
          property: property,
          onTap: () => _navigateToPropertyDetails(context, property),
          onEdit: () => context.push('/properties/${property.propertyId}/edit'),
          onDelete: () => _showDeleteDialog(context, property),
        );
      },
    );
  }

  Widget _buildGridView(List<Property> properties) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        mainAxisExtent: 320,
      ),
      itemCount: properties.length,
      itemBuilder: (context, index) {
        final property = properties[index];
        return PropertyCard(
          property: property,
          isGridView: true,
          onTap: () => _navigateToPropertyDetails(context, property),
          onEdit: () => context.push('/properties/${property.propertyId}/edit'),
          onDelete: () => _showDeleteDialog(context, property),
        );
      },
    );
  }

  Widget _buildEmptyListMessage() {
    return Center(
      child: Text(
        _searchController.text.isEmpty
            ? 'No properties found.'
            : 'No properties match "${_searchController.text}".',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    Property property,
  ) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Delete Property',
      content: Text(
        'Are you sure you want to delete "${property.name}"? This action cannot be undone.',
      ),
      confirmActionText: 'Delete',
      isDestructiveAction: true,
    );

    if (confirmed == true) {
      try {
        await context.read<PropertyCollectionProvider>().removeItem(
          property.propertyId.toString(),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete property: $e')),
          );
        }
      }
    }
  }

  void _navigateToAddProperty(BuildContext context) {
    context.push('/properties/add');
  }

  void _navigateToPropertyDetails(BuildContext context, Property property) {
    // Debug logging to track data consistency
    debugPrint(
      '🏠 PropertiesScreen: Navigating to property ${property.propertyId}',
    );
    debugPrint('🏠 PropertiesScreen: Property name: ${property.name}');
    debugPrint('🏠 PropertiesScreen: Renting type: ${property.rentingType}');
    debugPrint(
      '🏠 PropertiesScreen: Renting type display: ${property.rentingType.displayName}',
    );

    context.push('/properties/${property.propertyId}');
  }

  Widget _buildPaginationControls(PropertyCollectionProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous button
          ElevatedButton.icon(
            onPressed:
                provider.hasPreviousPage
                    ? () => provider.loadPreviousPage()
                    : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Previous'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  provider.hasPreviousPage ? null : Colors.grey.shade300,
            ),
          ),

          // Page info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              'Page ${provider.currentPage + 1} of ${provider.totalPages}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),

          // Next button
          ElevatedButton.icon(
            onPressed:
                provider.hasNextPage ? () => provider.loadNextPage() : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Next'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  provider.hasNextPage ? null : Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }
}
