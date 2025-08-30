import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/enums/property_status.dart';
import 'package:e_rents_desktop/features/properties/widgets/property_status_widgets.dart';

/// A widget for displaying property status as a non-interactive chip
class PropertyStatusChip extends StatelessWidget {
  final PropertyStatus status;

  const PropertyStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return PropertyStatusPill(status: status);
  }
}

/// A widget for displaying property status as a dropdown with tenant-aware options
class PropertyStatusTenantAwareDropdown extends StatefulWidget {
  final PropertyStatus selected;
  final bool hasTenant;
  final ValueChanged<PropertyStatus> onChanged;

  const PropertyStatusTenantAwareDropdown({
    super.key,
    required this.selected,
    required this.hasTenant,
    required this.onChanged,
  });

  @override
  State<PropertyStatusTenantAwareDropdown> createState() =>
      _PropertyStatusTenantAwareDropdownState();
}

class _PropertyStatusTenantAwareDropdownState
    extends State<PropertyStatusTenantAwareDropdown> {
  @override
  Widget build(BuildContext context) {
    final List<PropertyStatus> availableStatuses = widget.hasTenant
        ? [
            PropertyStatus.occupied,
            PropertyStatus.underMaintenance,
          ]
        : PropertyStatus.values;

    final menuItems = availableStatuses
        .map((status) => DropdownMenuItem<PropertyStatus>(
              value: status,
              child: Text(status.displayName),
            ))
        .toList();

    return DropdownButton<PropertyStatus>(
      value: widget.selected,
      items: menuItems,
      onChanged: (value) {
        if (value != null) {
          widget.onChanged(value);
        }
      },
      selectedItemBuilder: (context) => availableStatuses
          .map((status) => PropertyStatusPill(status: status))
          .toList(),
      hint: PropertyStatusPill(status: widget.selected),
    );
  }
}
