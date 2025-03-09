// lib/feature/property_detail/widgets/facilities_section.dart
import 'package:flutter/material.dart';

class FacilitiesSection extends StatelessWidget {
  const FacilitiesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Home Facilities',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildFacilityItem(context, Icons.wifi, 'WiFi'),
            _buildFacilityItem(context, Icons.local_parking, 'Parking'),
            _buildFacilityItem(context, Icons.ac_unit, 'AC'),
            _buildFacilityItem(context, Icons.tv, 'TV'),
            _buildFacilityItem(context, Icons.kitchen, 'Kitchen'),
            _buildFacilityItem(context, Icons.pool, 'Pool'),
            _buildFacilityItem(context, Icons.local_laundry_service, 'Laundry'),
            _buildFacilityItem(context, Icons.security, 'Security'),
          ],
        ),
      ],
    );
  }

  Widget _buildFacilityItem(BuildContext context, IconData icon, String label) {
    final Color grayColor = Colors.grey.shade600;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: grayColor),
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