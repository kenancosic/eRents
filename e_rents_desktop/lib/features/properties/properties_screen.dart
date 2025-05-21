import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_reorderable_grid_view/widgets/widgets.dart';
import 'package:e_rents_desktop/base/app_base_screen.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/features/properties/providers/property_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_desktop/utils/formatters.dart';
import 'package:e_rents_desktop/widgets/custom_search_bar.dart';
import 'package:e_rents_desktop/widgets/status_chip.dart';
import 'package:e_rents_desktop/features/properties/widgets/property_info_row.dart';
import 'package:e_rents_desktop/widgets/confirmation_dialog.dart';
import 'package:e_rents_desktop/widgets/loading_or_error_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:e_rents_desktop/base/base_provider.dart';

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
    Future.microtask(() async {
      final provider = context.read<PropertyProvider>();
      await provider.fetchProperties();
      if (mounted) {
        setState(() {
          _filteredProperties = provider.properties;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterProperties(String query) {
    final provider = context.read<PropertyProvider>();
    final lowerCaseQuery = query.toLowerCase();

    List<Property> newlyFiltered;
    if (query.isEmpty) {
      newlyFiltered = provider.properties;
    } else {
      newlyFiltered =
          provider.properties.where((property) {
            return property.title.toLowerCase().contains(lowerCaseQuery);
          }).toList();
    }

    if (!listEquals(_filteredProperties, newlyFiltered)) {
      setState(() {
        _filteredProperties = newlyFiltered;
      });
    }
  }

  // --- Helper for Status Chip ---
  // Updated to work with PropertyStatus enum
  ({Color color, IconData icon}) _getStatusDisplayProperties(
    PropertyStatus status,
  ) {
    switch (status) {
      case PropertyStatus.available:
        return (color: Colors.green, icon: Icons.check_circle_outline);
      case PropertyStatus.rented:
        return (color: Colors.blue, icon: Icons.person_outline);
      case PropertyStatus.maintenance:
        return (color: Colors.orange, icon: Icons.build_circle_outlined);
      case PropertyStatus.unavailable:
      default:
        return (color: Colors.grey, icon: Icons.help_outline);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBaseScreen(
      title: 'Properties',
      currentPath: '/properties',
      child: Consumer<PropertyProvider>(
        builder: (context, provider, child) {
          return LoadingOrErrorWidget(
            isLoading: provider.state == ViewState.Busy,
            error: provider.errorMessage,
            onRetry: () => provider.fetchProperties(),
            child: Column(
              children: [
                Padding(
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
    if (properties.isEmpty) {
      return _buildEmptyListMessage();
    }
    return ListView.builder(
      itemCount: properties.length,
      itemBuilder: (context, index) {
        final property = properties[index];
        final statusProps = _getStatusDisplayProperties(property.status);
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
                    runSpacing: 4,
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
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    kCurrencyFormat.format(property.price),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  // Use refactored StatusChip with parameters
                  StatusChip(
                    label: property.status,
                    backgroundColor: statusProps.color,
                    iconData: statusProps.icon,
                  ),
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
    if (properties.isEmpty) {
      return _buildEmptyListMessage();
    }
    final scrollController = ScrollController();
    final gridViewKey = GlobalKey();

    return ReorderableBuilder<Property>(
      scrollController: scrollController,
      children:
          properties.map((property) {
            final statusProps = _getStatusDisplayProperties(property.status);
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
                              // Use refactored StatusChip with parameters
                              child: StatusChip(
                                label: property.status,
                                backgroundColor: statusProps.color,
                                iconData: statusProps.icon,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                property.title,
                                style: Theme.of(context).textTheme.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Expanded(
                                child: Text(
                                  property.description,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
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
                mainAxisExtent: 320,
              ),
              children: children,
            );
          },
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
        'Are you sure you want to delete "${property.title}"? This action cannot be undone.',
      ),
      confirmActionText: 'Delete',
      isDestructiveAction: true,
    );

    if (confirmed == true) {
      try {
        await context.read<PropertyProvider>().deleteProperty(property.id);
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
    context.push('/properties/${property.id}');
  }
}
