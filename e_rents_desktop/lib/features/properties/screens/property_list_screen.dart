import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/features/properties/providers/property_provider.dart';
import 'package:e_rents_desktop/base/crud/list_screen.dart';
import 'package:e_rents_desktop/router.dart';
import 'package:e_rents_desktop/features/properties/widgets/property_filter_panel.dart';
import 'package:e_rents_desktop/features/properties/widgets/property_status_chip.dart';
import 'package:e_rents_desktop/features/properties/widgets/property_amenities_display.dart';

class PropertyListScreen extends StatefulWidget {
  const PropertyListScreen({super.key});

  @override
  State<PropertyListScreen> createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends State<PropertyListScreen> {
  // External controller to trigger refreshes after updates/deletes
  final ListController listController = ListController();

  @override
  void initState() {
    super.initState();
  }


  Widget _statusChip(BuildContext context, Property p) {
    return PropertyStatusChip(status: p.status);
  }

  Future<List<Property>> _fetch(
    BuildContext context, {
    int page = 1,
    int pageSize = 20,
    Map<String, dynamic>? filters,
  }) async {
    final provider = context.read<PropertyProvider>();
    final paged = await provider.fetchPaged(
      page: page,
      pageSize: pageSize,
      filters: filters,
    );
    return paged?.items ?? <Property>[];
  }

  void _navigateToAdd(BuildContext context) async {
    final path = '${AppRoutes.properties}/${AppRoutes.addProperty}';
    await context.push(path);
    await listController.refresh();
  }

  void _navigateToDetails(BuildContext context, int id) async {
    final path = '${AppRoutes.properties}/$id';
    await context.push(path);
  }

  void _navigateToEdit(BuildContext context, int id) async {
    final path = '${AppRoutes.properties}/$id/${AppRoutes.editProperty}';
    await context.push(path);
    await listController.refresh();
  }

  Future<void> _confirmAndDelete(BuildContext context, Property property) async {
    final provider = context.read<PropertyProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete property?'),
        content: Text('Are you sure you want to delete "${property.name}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final ok = await provider.remove(property.propertyId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ok ? 'Property deleted' : 'Delete failed')),
        );
        if (ok) {
          await listController.refresh();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListScreen<Property>(
      title: 'Properties',
      enablePagination: true,
      pageSize: 20,
      inlineSearchBar: true,
      inlineSearchHint: 'Search properties...',
      showFilters: true,
      searchParamKey: 'nameContains',
      filterBuilder: (ctx, currentFilters, controller) {
        return PropertyFilterPanel(
          initialFilters: currentFilters,
          showSearchField: false,
          controller: controller,
        );
      },
      actions: [
        ElevatedButton.icon(
          onPressed: () => _navigateToAdd(context),
          icon: const Icon(Icons.add),
          label: const Text('Add Property'),
        ),
        const SizedBox(width: 8),
      ],
      fetchItems: ({int page = 1, int pageSize = 20, Map<String, dynamic>? filters}) =>
          _fetch(context, page: page, pageSize: pageSize, filters: filters),
      controller: listController,
      onItemTap: (Property item) {},
      onItemDoubleTap: (Property item) => _navigateToDetails(context, item.propertyId),
      itemBuilder: (BuildContext ctx, Property p) {
        // Fallback list item (used if tableColumns/tableRowsBuilder are not provided)
        return ListTile(
          title: Text(p.name),
          subtitle: Text(p.description?.trim().isEmpty == true ? '-' : (p.description ?? '-')),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _statusChip(ctx, p),
              const SizedBox(width: 12),
              Text('${p.currency.isNotEmpty ? '' : ''} ${p.price.toStringAsFixed(2)} ${p.currency.isNotEmpty ? p.currency : ''}'
                  ' / ${p.rentingType?.displayName.toLowerCase() ?? 'period'}'),
              const SizedBox(width: 12),
              PropertyAmenityChips(amenityIds: p.amenityIds, isListView: true),
              const SizedBox(width: 12),
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _navigateToEdit(ctx, p.propertyId),
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => _confirmAndDelete(ctx, p),
              ),
            ],
          ),
          onTap: null,
        );
      },
      tableColumns: const [
        DataColumn(label: Text('Name')),
        DataColumn(label: Text('City')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Amenities')),
        DataColumn(label: Text('Price')),
        DataColumn(label: Text('Actions')),
      ],
      tableRowsBuilder: (ctx, items) {
        return items.map((p) {
          return DataRow(
            // Single click does nothing; double-click handled via GestureDetector on first cell
            cells: [
              DataCell(Text(p.name)),
              DataCell(Text(p.address?.city ?? '-')),
              DataCell(_statusChip(ctx, p)),
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: PropertyAmenityChips(amenityIds: p.amenityIds, isListView: true),
                ),
              ),
              DataCell(Text('${p.currency.isNotEmpty ? '' : ''} ${p.price.toStringAsFixed(2)} ${p.currency.isNotEmpty ? p.currency : ''} / '
                  '${p.rentingType?.displayName.toLowerCase() ?? 'period'}')),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Edit',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _navigateToEdit(ctx, p.propertyId),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _confirmAndDelete(ctx, p),
                  ),
                ],
              )),
            ],
          );
        }).toList();
      },
    );
  }
}
