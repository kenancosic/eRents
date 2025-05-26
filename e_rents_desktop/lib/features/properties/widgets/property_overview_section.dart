import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/services/mock_data_service.dart';

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
        _buildDetailRow('Type', property.type.toString().split('.').last),
        const Divider(),
        _buildDetailRow('Description', property.description),
        const Divider(),
        _buildDetailRow('Last Renovated', '2020'),
        const Divider(),
        _buildDetailRow('Parking', '2 Covered Spaces'),
        const Divider(),
        _buildAmenityRow('Amenities', property.amenities ?? []),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value, softWrap: true)),
        ],
      ),
    );
  }

  Widget _buildAmenityRow(String label, List<String> amenities) {
    final Map<String, IconData> amenityIcons =
        MockDataService.getMockAmenitiesWithIcons();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child:
                amenities.isEmpty
                    ? Text('None', style: TextStyle(color: Colors.grey[600]))
                    : Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children:
                          amenities.map((amenity) {
                            final icon = amenityIcons[amenity];
                            return Chip(
                              avatar:
                                  icon != null ? Icon(icon, size: 18) : null,
                              label: Text(amenity),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              labelStyle: const TextStyle(fontSize: 12),
                              backgroundColor: Colors.grey[200],
                            );
                          }).toList(),
                    ),
          ),
        ],
      ),
    );
  }
}
