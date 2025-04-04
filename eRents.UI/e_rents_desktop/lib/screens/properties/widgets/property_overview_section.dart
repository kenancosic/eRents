import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/property.dart';

class PropertyOverviewSection extends StatelessWidget {
  final Property property;
  final VoidCallback onEdit;

  const PropertyOverviewSection({
    super.key,
    required this.property,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Property Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Edit'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const Divider(),
        _buildInfoRow('Type', property.type),
        const Divider(),
        _buildInfoRow('Description', property.description),
        const Divider(),
        _buildInfoRow('Year Built', '2015'),
        const Divider(),
        _buildInfoRow('Last Renovated', '2020'),
        const Divider(),
        _buildInfoRow('Parking', '2 Covered Spaces'),
        const Divider(),
        _buildInfoRow('Amenities', 'Pool, Gym, Security System'),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}
