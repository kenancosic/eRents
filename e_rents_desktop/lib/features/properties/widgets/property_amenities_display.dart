import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:e_rents_desktop/base/lookups/lookup_key.dart';
import 'package:e_rents_desktop/providers/lookup_provider.dart';

/// A reusable widget for displaying property amenities as chips
class PropertyAmenityChips extends StatelessWidget {
  final List<int> amenityIds;
  final bool isListView;

  const PropertyAmenityChips({
    super.key,
    required this.amenityIds,
    this.isListView = false,
  });

  @override
  Widget build(BuildContext context) {
    final lookup = context.read<LookupProvider>();
    
    if (isListView) {
      // For list view, show up to 3 amenities + "+N" for remaining
      final names = amenityIds
          .map((id) => lookup.label(LookupKey.amenity, id: id) ?? 'ID $id')
          .toList();
      
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
      
      return Wrap(
        spacing: 6,
        runSpacing: 2,
        children: chips,
      );
    } else {
      // For detail view, show all amenities
      final names = amenityIds
          .map((id) => lookup.label(LookupKey.amenity, id: id) ?? 'ID $id')
          .toList();
      
      return Wrap(
        spacing: 6,
        runSpacing: 2,
        children: names
            .map(
              (name) => Chip(
                label: Text(name),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              ),
            )
            .toList(),
      );
    }
  }
}
