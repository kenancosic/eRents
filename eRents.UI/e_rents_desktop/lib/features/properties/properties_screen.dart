import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_reorderable_grid_view/widgets/widgets.dart';
import 'package:e_rents_desktop/base/app_base_screen.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/features/properties/providers/property_provider.dart';
import 'package:e_rents_desktop/features/properties/property_form_screen.dart';
import 'package:e_rents_desktop/features/properties/property_details_screen.dart';
import 'package:go_router/go_router.dart';

class PropertiesScreen extends StatefulWidget {
  const PropertiesScreen({super.key});

  @override
  State<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends State<PropertiesScreen> {
  bool _isListView = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<PropertyProvider>().fetchProperties());
  }

  @override
  Widget build(BuildContext context) {
    return AppBaseScreen(
      title: 'Properties',
      currentPath: '/properties',
      child: Consumer<PropertyProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    provider.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchProperties(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 600) {
                      // Stack vertically on small screens
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Properties: ${provider.properties.length}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
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
                                onPressed: () => _showPropertyDialog(context),
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
                            'Total Properties: ${provider.properties.length}',
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
                                onPressed: () => _showPropertyDialog(context),
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
              ),
              Expanded(
                child:
                    _isListView
                        ? _buildListView(provider.properties)
                        : _buildGridView(provider.properties),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildListView(List<Property> properties) {
    return ListView.builder(
      itemCount: properties.length,
      itemBuilder: (context, index) {
        final property = properties[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: InkWell(
            onTap: () => _showPropertyDetails(context, property),
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
                    children: [
                      _buildPropertyInfo(
                        Icons.bed,
                        '${property.bedrooms} beds',
                      ),
                      _buildPropertyInfo(
                        Icons.bathtub,
                        '${property.bathrooms} baths',
                      ),
                      _buildPropertyInfo(
                        Icons.square_foot,
                        '${property.area} sqft',
                      ),
                    ],
                  ),
                ],
              ),
              trailing: Wrap(
                spacing: 8,
                children: [
                  Text(
                    '\$${property.price.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  _buildStatusChip(property.status),
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
                        _showPropertyDialog(context, property);
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
                  onTap: () => _showPropertyDetails(context, property),
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
                              child: _buildStatusChip(property.status),
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
                                    '\$${property.price.toStringAsFixed(2)}',
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
                                        _showPropertyDialog(context, property);
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

  Widget _buildPropertyInfo(IconData icon, String text) {
    return Row(
      children: [Icon(icon, size: 16), const SizedBox(width: 4), Text(text)],
    );
  }

  Widget _buildStatusChip(String status) {
    final isAvailable = status == 'Available';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            isAvailable
                ? Colors.green.withOpacity(0.2)
                : Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: isAvailable ? Colors.green : Colors.red,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Future<void> _showPropertyDialog(
    BuildContext context, [
    Property? property,
  ]) async {
    final result = await Navigator.push<Property>(
      context,
      MaterialPageRoute(
        builder: (context) => PropertyFormScreen(property: property),
      ),
    );

    if (result != null) {
      final provider = context.read<PropertyProvider>();
      if (property == null) {
        await provider.addProperty(result);
      } else {
        await provider.updateProperty(result);
      }
    }
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    Property property,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Property'),
            content: Text(
              'Are you sure you want to delete "${property.title}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await context.read<PropertyProvider>().deleteProperty(property.id);
    }
  }

  void _showPropertyDetails(BuildContext context, Property property) {
    context.go('/properties/${property.id}');
  }
}
