import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:e_rents_desktop/models/enums/property_status.dart';
import 'package:e_rents_desktop/base/lookups/lookup_key.dart';
import 'package:e_rents_desktop/providers/lookup_provider.dart';
import 'package:e_rents_desktop/presentation/status_pill.dart';

/// A reusable dropdown widget for selecting property status
class PropertyStatusDropdown extends StatelessWidget {
  final PropertyStatus selected;
  final ValueChanged<PropertyStatus> onChanged;

  const PropertyStatusDropdown({super.key, required this.selected, required this.onChanged});

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

    Widget _statusPill(PropertyStatus status) {
      final Color bg;
      final IconData icon;
      switch (status) {
        case PropertyStatus.available:
          bg = Colors.green.shade600;
          icon = Icons.check_circle_outline;
          break;
        case PropertyStatus.occupied:
          bg = Colors.deepOrange.shade600;
          icon = Icons.home_work_outlined;
          break;
        case PropertyStatus.underMaintenance:
          bg = Colors.amber.shade700;
          icon = Icons.build_outlined;
          break;
        case PropertyStatus.unavailable:
          bg = Colors.grey.shade600;
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

    return DropdownButtonFormField<int>(
      value: selected.value,
      items: menuItems,
      decoration: const InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(),
      ),
      onChanged: (val) {
        if (val == null || val == selected.value) return;
        onChanged(PropertyStatus.fromValue(val));
      },
      selectedItemBuilder: (_) => (items.isEmpty
              ? PropertyStatus.values.map((e) => e.value).toList()
              : items.map((li) => li.value).toList())
          .map((v) => Align(
                alignment: Alignment.centerLeft,
                child: _statusPill(PropertyStatus.fromValue(v)),
              ))
          .toList(),
      hint: _statusPill(selected),
    );
  }
}
