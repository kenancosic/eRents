import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:e_rents_desktop/models/enums/renting_type.dart';
import 'package:e_rents_desktop/base/lookups/lookup_key.dart';
import 'package:e_rents_desktop/providers/lookup_provider.dart';

/// A reusable dropdown widget for selecting property renting type
class PropertyRentingTypeDropdown extends StatelessWidget {
  final RentingType selected;
  final ValueChanged<RentingType> onChanged;

  const PropertyRentingTypeDropdown({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final lookup = context.watch<LookupProvider>();
    final items = lookup.items(LookupKey.rentingType);
    final menuItems = items.isEmpty
        ? RentingType.values
            .map((e) => DropdownMenuItem<int>(value: e.value, child: Text(e.displayName)))
            .toList()
        : items
            .map((li) => DropdownMenuItem<int>(value: li.value, child: Text(li.text)))
            .toList();

    return DropdownButtonFormField<int>(
      value: selected.value,
      items: menuItems,
      decoration: const InputDecoration(
        labelText: 'Renting Type',
        border: OutlineInputBorder(),
      ),
      onChanged: (val) {
        if (val == null || val == selected.value) return;
        onChanged(RentingType.fromValue(val));
      },
    );
  }
}
