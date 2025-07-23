import 'package:provider/provider.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/features/properties/providers/properties_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_desktop/widgets/custom_search_bar.dart';
import 'package:e_rents_desktop/widgets/confirmation_dialog.dart';
import 'package:e_rents_desktop/widgets/loading_or_error_widget.dart';
import 'package:flutter/foundation.dart';
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
    // The initial fetch is now triggered by the router.
    // We just need to listen for search changes.
    _searchController.addListener(() {
      _filterProperties(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterProperties(String query) {
    final provider = context.read<PropertiesProvider>();
    final lowerCaseQuery = query.toLowerCase();

    List<Property> newlyFiltered;
    if (query.isEmpty) {
      newlyFiltered = provider.properties;
    } else {
      newlyFiltered = provider.properties.where((property) {
        return property.name.toLowerCase().contains(lowerCaseQuery);
      }).toList();
    }

    // Use foundation's listEquals for efficient comparison
    if (!listEquals(_filteredProperties, newlyFiltered)) {
      setState(() {
        _filteredProperties = newlyFiltered;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PropertiesProvider>(
      builder: (context, provider, child) {
        // Synchronize local filtered list with provider's list
        if (_searchController.text.isEmpty &&
            !listEquals(_filteredProperties, provider.properties)) {
          _filteredProperties = provider.properties;
        }

        return LoadingOrErrorWidget(
          isLoading: provider.isLoading && _filteredProperties.isEmpty,
          error: provider.error,
          onRetry: () => provider.getPagedProperties(),
          child: Column(
            children: [
              _buildHeaderSection(context),
              Expanded(
                child: _filteredProperties.isEmpty
                    ? _buildEmptyListMessage()
                    : _isListView
                        ? _buildListView(_filteredProperties)
                        : _buildGridView(_filteredProperties),
              ),
              if (provider.pagedResult != null &&
                  provider.pagedResult!.totalCount > provider.pagedResult!.pageSize)
                _buildPaginationControls(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: CustomSearchBar(
              controller: _searchController,
              hintText: 'Search by property name...',
            ),
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              IconButton(
                icon: Icon(_isListView ? Icons.grid_view : Icons.view_list),
                onPressed: () => setState(() => _isListView = !_isListView),
                tooltip: _isListView ? 'Grid View' : 'List View',
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _navigateToAddProperty(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Property'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<Property> properties) {
    return ListView.builder(
      itemCount: properties.length,
      itemBuilder: (context, index) {
        final property = properties[index];
        return PropertyCard(
          property: property,
          isGridView: false,
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
        childAspectRatio: 3 / 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
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
      final success = await context
          .read<PropertiesProvider>()
          .deleteProperty(property.propertyId.toString());
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(context.read<PropertiesProvider>().error ??
                  'Failed to delete property.')),
        );
      }
    }
  }

  void _navigateToAddProperty(BuildContext context) {
    context.push('/properties/add');
  }

  void _navigateToPropertyDetails(BuildContext context, Property property) {
    context.push('/properties/${property.propertyId}');
  }

  Widget _buildPaginationControls(PropertiesProvider provider) {
    final pagedResult = provider.pagedResult!;
    final bool hasPreviousPage = pagedResult.page > 0;
    final bool hasNextPage = (pagedResult.page + 1) * pagedResult.pageSize < pagedResult.totalCount;

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
            onPressed: hasPreviousPage
                ? () => provider.getPagedProperties(params: {'page': pagedResult.page})
                : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Previous'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  hasPreviousPage ? null : Colors.grey.shade300,
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
              'Page ${pagedResult.page + 1} of ${pagedResult.totalPages}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),

          // Next button
          ElevatedButton.icon(
            onPressed: hasNextPage
                ? () => provider.getPagedProperties(params: {'page': pagedResult.page + 2})
                : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Next'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  hasNextPage ? null : Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }
}
