import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/features/properties/providers/property_form_provider.dart';
import 'package:e_rents_desktop/widgets/amenity_manager.dart';

/// Atomic widget for property amenities selection.
class AmenitiesSection extends StatelessWidget {
  const AmenitiesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Amenities', style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),
        
        Selector<PropertyFormProvider, List<int>>(
          selector: (_, p) => p.state.amenityIds,
          builder: (context, amenityIds, _) {
            return AmenityManager(
              mode: AmenityManagerMode.edit,
              initialAmenityIds: amenityIds,
              onAmenityIdsChanged: (ids) {
                context.read<PropertyFormProvider>().updateAmenities(ids);
              },
            );
          },
        ),
      ],
    );
  }
}
