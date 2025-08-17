import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/enums/property_status.dart';
import 'package:e_rents_desktop/core/lookups/lookup_key.dart';
import 'package:e_rents_desktop/providers/lookup_provider.dart';
import 'package:e_rents_desktop/features/properties/providers/property_provider.dart';
import 'package:e_rents_desktop/base/crud/list_screen.dart';
import 'package:e_rents_desktop/router.dart';
import 'package:e_rents_desktop/features/properties/widgets/property_filter_panel.dart';
import 'package:e_rents_desktop/presentation/status_pill.dart';

class PropertyListScreen extends StatelessWidget {
  const PropertyListScreen({super.key});
  // ── Helpers ──────────────────────────────────────────────────────────────
  Color _statusColor(PropertyStatus status, BuildContext context) {
    switch (status) {
      case PropertyStatus.available:
        return Colors.green.shade600;
      case PropertyStatus.occupied:
        return Colors.deepOrange.shade600;
      case PropertyStatus.underMaintenance:
        return Colors.amber.shade700;
      case PropertyStatus.unavailable:
        return Colors.grey.shade600;
    }
  }

  Widget _statusChip(PropertyStatus status, BuildContext context) {
    final bg = _statusColor(status, context);
    final IconData icon;
    switch (status) {
      case PropertyStatus.available:
        icon = Icons.check_circle_outline;
        break;
      case PropertyStatus.occupied:
        icon = Icons.home_work_outlined;
        break;
      case PropertyStatus.underMaintenance:
        icon = Icons.build_outlined;
        break;
      case PropertyStatus.unavailable:
        icon = Icons.block;
        break;
    }
    return StatusPill(
      label: status.displayName,
      backgroundColor: bg,
      iconData: icon,
      foregroundColor: Colors.white,
    );
  }

  List<Widget> _amenityChips(BuildContext context, List<int> amenityIds) {
    final lookup = context.read<LookupProvider>();
    // Try registry labels; keep it light in list view
    final names = amenityIds
        .map((id) => lookup.label(LookupKey.amenity, id: id) ?? 'ID $id')
        .toList();
    // Avoid overloading the row: show up to 3 + "+N"
    final chips = <Widget>[];
    for (var i = 0; i < names.length && i < 3; i++) {
      chips.add(Chip(
        label: Text(names[i]),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      ));
    }
    final remaining = names.length - 3;
    if (remaining > 0) {
      chips.add(Chip(
        label: Text('+$remaining'),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      ));
    }
    return chips;
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
  }

  void _navigateToDetails(BuildContext context, int id) async {
    final path = '${AppRoutes.properties}/$id';
    await context.push(path);
  }

  void _navigateToEdit(BuildContext context, int id) async {
    final path = '${AppRoutes.properties}/$id/${AppRoutes.editProperty}';
    await context.push(path);
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
              _statusChip(p.status, ctx),
              const SizedBox(width: 12),
              Text('${p.currency.isNotEmpty ? '' : ''} ${p.price.toStringAsFixed(2)} ${p.currency.isNotEmpty ? p.currency : ''}'
                  ' / ${p.rentingType?.displayName.toLowerCase() ?? 'period'}'),
              const SizedBox(width: 12),
              if (p.amenityIds.isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 2,
                    children: _amenityChips(ctx, p.amenityIds),
                  ),
                ),
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
              DataCell(_statusChip(p.status, ctx)),
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 2,
                    children: _amenityChips(ctx, p.amenityIds),
                  ),
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
