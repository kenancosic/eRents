import 'package:provider/provider.dart';
import 'package:flutter_reorderable_grid_view/widgets/widgets.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/renting_type.dart';
import 'package:e_rents_desktop/features/properties/providers/property_collection_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_desktop/utils/formatters.dart';
import 'package:e_rents_desktop/widgets/custom_search_bar.dart';
import 'package:e_rents_desktop/widgets/status_chip.dart';
import 'package:e_rents_desktop/features/properties/widgets/property_info_row.dart';
import 'package:e_rents_desktop/widgets/confirmation_dialog.dart';
import 'package:e_rents_desktop/widgets/loading_or_error_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:e_rents_desktop/base/base.dart';
import 'package:flutter/material.dart';
import 'package:e_rents_desktop/utils/constants.dart';
import 'package:e_rents_desktop/utils/image_utils.dart';

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
        _filteredProperties = provider.properties;
      });
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
    return Consumer<PropertyCollectionProvider>(
      builder: (context, provider, child) {
        // Update _filteredProperties when provider.properties changes
        if (_searchController.text.isEmpty &&
            !listEquals(_filteredProperties, provider.properties)) {
          _filteredProperties = provider.properties;
        }

        return LoadingOrErrorWidget(
          isLoading:
              provider.state == ProviderState.loading &&
              _filteredProperties.isEmpty,
          error: provider.error?.message,
          onRetry: () async {
            await provider.fetchItems();
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderSection(BuildContext context, List<Property> properties) {
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
                      'Total Properties: ${properties.length}',
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
                      'Total Properties: ${properties.length}',
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
  }

  Widget _buildListView(List<Property> properties) {
    return ListView.builder(
      itemCount: properties.length,
      itemBuilder: (context, index) {
        final property = properties[index];
        return _PropertyListItem(
          property: property,
          statusDisplayProperties: _getStatusDisplayProperties(property.status),
          onTap: () => _navigateToPropertyDetails(context, property),
          onEdit: () => context.push('/properties/${property.id}/edit'),
          onDelete: () => _showDeleteDialog(context, property),
        );
      },
    );
  }

  Widget _buildGridView(List<Property> properties) {
    final scrollController = ScrollController();
    final gridViewKey = GlobalKey();

    // Note: ReorderableBuilder might need careful state management if properties list
    // is also being filtered. For simplicity, if filtering causes issues with
    // ReorderableBuilder's keying or index assumptions, consider disabling reordering
    // when a search query is active or using a stable key that doesn't change
    // with filtering (e.g., property.id itself, if unique and stable).

    return ReorderableBuilder<Property>(
      scrollController: scrollController,
      key: ValueKey(
        _filteredProperties.length,
      ), // Ensure key changes if list changes significantly
      children:
          properties.map((property) {
            return _PropertyGridItem(
              key: ValueKey(
                property.id.toString(),
              ), // Use stable key for each item
              property: property,
              statusDisplayProperties: _getStatusDisplayProperties(
                property.status,
              ),
              onTap: () => _navigateToPropertyDetails(context, property),
              onEdit: () => context.push('/properties/${property.id}/edit'),
              onDelete: () => _showDeleteDialog(context, property),
            );
          }).toList(),
      onReorder: (reorderedListFunction) {
        // This needs to be carefully managed with filtering.
        // If _filteredProperties is a subset of provider.properties,
        // reordering needs to be mapped back to the original list or
        // the provider should handle reordering of the filtered list if that's the intent.
        // For now, assuming reordering applies to the currently displayed list.
        setState(() {
          // Create a new list from the reordered items.
          final reorderedItems = reorderedListFunction(
            List.from(_filteredProperties),
          );
          _filteredProperties = List<Property>.from(reorderedItems);

          // If you want to persist this order in the provider, you might need a more complex logic:
          // final provider = context.read<PropertyProvider>();
          // provider.updateOrderOfProperties(_filteredProperties); // Hypothetical method
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
        await context.read<PropertyCollectionProvider>().removeItem(
          property.id.toString(),
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
    context.push('/properties/${property.id}');
  }
}

// New Private Widget for List Item
class _PropertyListItem extends StatelessWidget {
  final Property property;
  final ({Color color, IconData icon}) statusDisplayProperties;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PropertyListItem({
    required this.property,
    required this.statusDisplayProperties,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: SizedBox(
            width: 56,
            height: 56,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child:
                  property.images.isNotEmpty &&
                          property.images.first.url != null &&
                          property.images.first.url!.isNotEmpty
                      ? ImageUtils.buildImage(
                        property.images.first.url!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorWidget: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey[600],
                            size: 24,
                          ),
                        ),
                      )
                      : Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.apartment,
                          color: Colors.grey[600],
                          size: 24,
                        ),
                      ),
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
                    text: '${property.area} m²', // Corrected unit
                  ),
                ],
              ),
            ],
          ),
          trailing: Wrap(
            spacing: 4, // Reduced spacing for better fit
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                kCurrencyFormat.format(property.price),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              StatusChip(
                label: property.status.displayName, // Use displayName
                backgroundColor: statusDisplayProperties.color,
                iconData: statusDisplayProperties.icon,
              ),
              PopupMenuButton(
                tooltip: "Actions",
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_outlined),
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
                            Icon(Icons.delete_outline, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// New Private Widget for Grid Item
class _PropertyGridItem extends StatelessWidget {
  final Property property;
  final ({Color color, IconData icon}) statusDisplayProperties;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PropertyGridItem({
    super.key, // Pass the key here
    required this.property,
    required this.statusDisplayProperties,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:
          300, // These are defaults, actual size determined by GridView delegate
      height: 320,
      child: Card(
        clipBehavior:
            Clip.antiAlias, // Changed from hardEdge for smoother corners
        elevation: 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 160,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    property.images.isNotEmpty &&
                            property.images.first.url != null &&
                            property.images.first.url!.isNotEmpty
                        ? ImageUtils.buildImage(
                          property.images.first.url!,
                          fit: BoxFit.cover,
                          errorWidget: Container(
                            // Consistent error widget
                            decoration: BoxDecoration(color: Colors.grey[200]),
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.grey[600],
                              size: 48,
                            ),
                          ),
                        )
                        : Container(
                          // Consistent placeholder
                          decoration: BoxDecoration(color: Colors.grey[200]),
                          child: Icon(
                            Icons.apartment_outlined,
                            color: Colors.grey[600],
                            size: 48,
                          ),
                        ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: StatusChip(
                        label: property.status.displayName, // Use displayName
                        backgroundColor: statusDisplayProperties.color,
                        iconData: statusDisplayProperties.icon,
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
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween, // Better spacing
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            property.title,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            property.description,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            kCurrencyFormat.format(property.price),
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          PopupMenuButton(
                            tooltip: "Actions",
                            padding: EdgeInsets.zero,
                            itemBuilder:
                                (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.edit_outlined),
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
                                          Icons.delete_outline,
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
                                onEdit();
                              } else if (value == 'delete') {
                                onDelete();
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
  }
}

// Helper extension for PropertyStatus display names (if not already defined elsewhere)
// Add this if your PropertyStatus enum doesn't have a suitable displayName getter.
extension PropertyStatusExtension on PropertyStatus {
  String get displayName {
    switch (this) {
      case PropertyStatus.available:
        return 'Available';
      case PropertyStatus.rented:
        return 'Rented';
      case PropertyStatus.maintenance:
        return 'Maintenance';
      case PropertyStatus.unavailable:
        return 'Unavailable';
      default:
        // Capitalize first letter of enum value name
        final name = toString().split('.').last;
        return name[0].toUpperCase() + name.substring(1);
    }
  }
}
