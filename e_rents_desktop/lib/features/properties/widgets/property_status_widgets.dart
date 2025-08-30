import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:e_rents_desktop/models/enums/property_status.dart';
import 'package:e_rents_desktop/base/lookups/lookup_key.dart';
import 'package:e_rents_desktop/providers/lookup_provider.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/presentation/status_pill.dart';
import 'package:e_rents_desktop/features/properties/providers/property_provider.dart';

/// A utility class for shared property status functionality
class PropertyStatusUtils {
  /// Returns the color associated with a property status
  static Color statusColor(PropertyStatus status, BuildContext context) {
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
}

/// A reusable widget for displaying property status as a pill
class PropertyStatusPill extends StatelessWidget {
  final PropertyStatus status;

  const PropertyStatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final bg = PropertyStatusUtils.statusColor(status, context);
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
}

/// A reusable dropdown widget for changing property status
class PropertyStatusDropdown extends StatefulWidget {
  final Property property;
  final Function(PropertyStatus)? onStatusChanged;

  const PropertyStatusDropdown({
    super.key,
    required this.property,
    this.onStatusChanged,
  });

  @override
  State<PropertyStatusDropdown> createState() => _PropertyStatusDropdownState();
}

class _PropertyStatusDropdownState extends State<PropertyStatusDropdown> {
  Future<void> _onStatusChanged(BuildContext context, Property p, int newStatusValue) async {
    final provider = context.read<PropertyProvider>();
    final updated = Property(
      propertyId: p.propertyId,
      ownerId: p.ownerId,
      description: p.description,
      price: p.price,
      currency: p.currency,
      facilities: p.facilities,
      status: PropertyStatus.fromValue(newStatusValue),
      dateAdded: p.dateAdded,
      name: p.name,
      averageRating: p.averageRating,
      imageIds: p.imageIds,
      amenityIds: p.amenityIds,
      address: p.address,
      propertyType: p.propertyType,
      rentingType: p.rentingType,
      rooms: p.rooms,
      area: p.area,
      minimumStayDays: p.minimumStayDays,
      requiresApproval: p.requiresApproval,
      coverImageId: p.coverImageId,
    );
    final res = await provider.update(updated);
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res != null ? 'Status updated' : 'Failed to update status')),
    );
    
    if (res != null && widget.onStatusChanged != null) {
      widget.onStatusChanged!(PropertyStatus.fromValue(newStatusValue));
    }
  }

  @override
  Widget build(BuildContext context) {
    final lookup = context.watch<LookupProvider>();
    final items = lookup.items(LookupKey.propertyStatus);
    final menuItems = items.isEmpty
        ? PropertyStatus.values
            .map((e) => DropdownMenuItem<int>(value: e.value, child: Text(e.displayName)))
            .toList()
        : items
            .map((li) => DropdownMenuItem<int>(value: li.value, child: Text(li.text)))
            .toList();

    return DropdownButtonHideUnderline(
      child: DropdownButton<int>(
        value: widget.property.status.value,
        items: menuItems,
        onChanged: (val) async {
          if (val == null || val == widget.property.status.value) return;
          await _onStatusChanged(context, widget.property, val);
        },
        style: Theme.of(context).textTheme.bodyMedium,
        hint: PropertyStatusPill(status: widget.property.status),
        selectedItemBuilder: (_) => menuItems
            .map((mi) => Align(
                  alignment: Alignment.centerLeft,
                  child: PropertyStatusPill(status: PropertyStatus.fromValue(mi.value!)),
                ))
            .toList(),
      ),
    );
  }
}
