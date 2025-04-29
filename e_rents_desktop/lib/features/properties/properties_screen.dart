import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_reorderable_grid_view/widgets/widgets.dart';
import 'package:e_rents_desktop/base/app_base_screen.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/features/properties/providers/property_provider.dart';
import 'package:e_rents_desktop/features/properties/property_form_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_desktop/utils/formatters.dart';
import 'package:e_rents_desktop/widgets/custom_search_bar.dart';
import 'package:e_rents_desktop/features/properties/widgets/status_chip.dart';
import 'package:e_rents_desktop/features/properties/widgets/property_info_row.dart';
import 'package:e_rents_desktop/widgets/confirmation_dialog.dart';
import 'package:e_rents_desktop/widgets/loading_or_error_widget.dart';

class PropertiesScreen extends StatefulWidget {
  const PropertiesScreen({super.key});

  @override
  State<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends State<PropertiesScreen> {
  bool _isListView = true;
  String _searchQuery = '';
  List<String> _searchHistory = [];
  List<Property> _filteredProperties = [];

  @override
  void initState() {
    super.initState();
    // Initial fetch and filter setup
    Future.microtask(() async {
      final provider = context.read<PropertyProvider>();
      await provider.fetchProperties();
      // Initially, show all properties
      if (mounted) {
        setState(() {
          _filteredProperties = provider.properties;
        });
      }
    });
  }

  void _filterProperties(String query) {
    final provider = context.read<PropertyProvider>();
    final lowerCaseQuery = query.toLowerCase();

    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredProperties = provider.properties;
      } else {
        _filteredProperties =
            provider.properties.where((property) {
              // Search by title (name)
              return property.title.toLowerCase().contains(lowerCaseQuery);
              // Add more fields to search if needed (e.g., description, address)
              // || property.description.toLowerCase().contains(lowerCaseQuery)
              // || property.address.toLowerCase().contains(lowerCaseQuery);
            }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBaseScreen(
      title: 'Properties',
      currentPath: '/properties',
      child: Consumer<PropertyProvider>(
        builder: (context, provider, child) {
          // Use the LoadingOrErrorWidget to handle loading/error states
          return LoadingOrErrorWidget(
            isLoading: provider.isLoading,
            error: provider.error,
            onRetry: () => provider.fetchProperties(), // Provide retry callback
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomSearchBar<Property>(
                        hintText: 'Search Properties by Name...',
                        showFilterIcon: false, // Hiding filter icon for now
                        searchHistory: _searchHistory,
                        localData:
                            provider
                                .properties, // Use all properties for suggestions
                        showSuggestions: true,
                        itemToString:
                            (Property item) =>
                                item.title, // For basic filtering
                        onSearchChanged:
                            _filterProperties, // Filter the main list
                        customSuggestionBuilder: (
                          Property item,
                          TextEditingController controller,
                          Function(String) onSelected,
                        ) {
                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.asset(
                                item
                                    .images
                                    .first, // Assuming at least one image
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                            title: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  item.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  kCurrencyFormat.format(item.price),
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              controller.text = item.title; // Set text field
                              _filterProperties(item.title); // Filter list
                              // Add to history (optional)
                              if (!_searchHistory.contains(item.title)) {
                                setState(
                                  () => _searchHistory.insert(0, item.title),
                                );
                                // Limit history size if needed
                              }
                              // Navigate to details
                              _navigateToPropertyDetails(context, item);
                              // Close suggestions view implicitly by navigation
                              // If not navigating, you might need `controller.closeView(item.title)`
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16), // Spacing after search bar
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth < 600) {
                            // Stack vertically on small screens
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Properties: ${_filteredProperties.length}',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        _isListView
                                            ? Icons.grid_view
                                            : Icons.list,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isListView = !_isListView;
                                        });
                                      },
                                    ),
                                    ElevatedButton.icon(
                                      onPressed:
                                          () => _navigateToAddProperty(context),
                                      icon: const Icon(Icons.add),
                                      label: const Text('Add Property'),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          } else {
                            // Use row layout on larger screens
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Properties: ${_filteredProperties.length}',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        _isListView
                                            ? Icons.grid_view
                                            : Icons.list,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isListView = !_isListView;
                                        });
                                      },
                                    ),
                                    ElevatedButton.icon(
                                      onPressed:
                                          () => _navigateToAddProperty(context),
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
                ),
                Expanded(
                  child:
                      _isListView
                          ? _buildListView(_filteredProperties)
                          : _buildGridView(_filteredProperties),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildListView(List<Property> properties) {
    // Check if properties list is empty after filtering
    if (properties.isEmpty) {
      return _buildEmptyListMessage(); // Use helper
    }
    return ListView.builder(
      itemCount: properties.length,
      itemBuilder: (context, index) {
        final property = properties[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: InkWell(
            onTap: () => _navigateToPropertyDetails(context, property),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  property.images.first,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              title: Text(
                property.title,
                style: Theme.of(context).textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    property.description,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 4, // Add run spacing for smaller screens
                    children: [
                      PropertyInfoRow(
                        icon: Icons.bed,
                        text: '${property.bedrooms} beds',
                      ),
                      PropertyInfoRow(
                        icon: Icons.bathtub,
                        text: '${property.bathrooms} baths',
                      ),
                      PropertyInfoRow(
                        icon: Icons.square_foot,
                        text: '${property.area} sqft',
                      ),
                    ],
                  ),
                ],
              ),
              trailing: Wrap(
                spacing: 8,
                children: [
                  Text(
                    kCurrencyFormat.format(property.price),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  StatusChip(status: property.status),
                  PopupMenuButton(
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete'),
                              ],
                            ),
                          ),
                        ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        context.push('/properties/${property.id}/edit');
                      } else if (value == 'delete') {
                        _showDeleteDialog(context, property);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridView(List<Property> properties) {
    // Check if properties list is empty after filtering
    if (properties.isEmpty) {
      return _buildEmptyListMessage(); // Use helper
    }
    final scrollController = ScrollController();
    final gridViewKey = GlobalKey();

    return ReorderableBuilder<Property>(
      scrollController: scrollController,
      children:
          properties.map((property) {
            return SizedBox(
              key: ValueKey(property.id),
              width: 300,
              height: 320,
              child: Card(
                clipBehavior: Clip.hardEdge,
                child: InkWell(
                  onTap: () => _navigateToPropertyDetails(context, property),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image section with fixed height
                      SizedBox(
                        height: 160,
                        width: double.infinity,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              property.images.first,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: StatusChip(status: property.status),
                            ),
                          ],
                        ),
                      ),
                      // Content section
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Text(
                                property.title,
                                style: Theme.of(context).textTheme.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              // Description
                              Expanded(
                                child: Text(
                                  property.description,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Bottom row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    kCurrencyFormat.format(property.price),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  PopupMenuButton(
                                    padding: EdgeInsets.zero,
                                    itemBuilder:
                                        (context) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.edit),
                                                SizedBox(width: 8),
                                                Text('Edit'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                ),
                                                SizedBox(width: 8),
                                                Text('Delete'),
                                              ],
                                            ),
                                          ),
                                        ],
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        context.push(
                                          '/properties/${property.id}/edit',
                                        );
                                      } else if (value == 'delete') {
                                        _showDeleteDialog(context, property);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
      onReorder: (reorderedListFunction) {
        setState(() {
          final provider = context.read<PropertyProvider>();
          final reorderedList = reorderedListFunction(provider.properties);
          provider.updateProperties(List<Property>.from(reorderedList));
        });
      },
      builder: (children) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            int crossAxisCount;

            if (screenWidth >= 1200) {
              crossAxisCount = 4;
            } else if (screenWidth >= 900) {
              crossAxisCount = 3;
            } else if (screenWidth >= 600) {
              crossAxisCount = 2;
            } else {
              crossAxisCount = 1;
            }

            return GridView(
              key: gridViewKey,
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                mainAxisExtent: 320, // Match the SizedBox height
              ),
              children: children,
            );
          },
        );
      },
    );
  }

  // Helper widget for displaying the empty list message
  Widget _buildEmptyListMessage() {
    return Center(
      child: Text(
        _searchQuery.isEmpty
            ? 'No properties found.' // Message when no properties exist at all
            : 'No properties match "$_searchQuery".', // Message when filter yields no results
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
        'Are you sure you want to delete "${property.title}"? This action cannot be undone.',
      ),
      confirmActionText: 'Delete',
      isDestructiveAction: true,
    );

    // Check explicitly for true, as dialog could return null if dismissed
    if (confirmed == true) {
      // Add loading indicator/disable UI while deleting if needed
      try {
        await context.read<PropertyProvider>().deleteProperty(property.id);
        // Optional: Show success message (e.g., SnackBar)
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('"${property.title}" deleted.')),
        // );
      } catch (e) {
        // Optional: Show error message
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
    context.push('/properties/${property.id}');
  }
}
