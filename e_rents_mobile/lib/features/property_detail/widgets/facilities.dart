// lib/feature/property_detail/widgets/facilities_section.dart
import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/models/amenity.dart';

class FacilitiesSection extends StatelessWidget {
  final List<Amenity> amenities;

  const FacilitiesSection({super.key, required this.amenities});

  @override
  Widget build(BuildContext context) {
    final Color grayColor = Colors.grey.shade600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Home Facilities',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        if (amenities.isEmpty)
          Text(
            'No amenities listed',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: amenities
                .map((a) => _buildFacilityItem(context, grayColor, a.amenityName))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildFacilityItem(BuildContext context, Color grayColor, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 16, color: grayColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: grayColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}