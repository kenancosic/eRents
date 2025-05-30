import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/renting_type.dart';
import 'package:e_rents_desktop/features/properties/providers/property_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

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
        _buildDetailRow('Renting Type', property.rentingType.displayName),
        const Divider(),
        _buildDetailRow(
          'Monthly Price',
          '${property.price.toStringAsFixed(0)} ${property.currency}',
        ),
        if (property.dailyRate != null) ...[
          const Divider(),
          _buildDetailRow(
            'Daily Rate',
            '${property.dailyRate!.toStringAsFixed(0)} ${property.currency}',
          ),
        ],
        if (property.minimumStayDays != null) ...[
          const Divider(),
          _buildDetailRow('Minimum Stay', '${property.minimumStayDays} days'),
        ],
        const Divider(),
        _buildDetailRow('Bedrooms', property.bedrooms.toString()),
        const Divider(),
        _buildDetailRow('Bathrooms', property.bathrooms.toString()),
        const Divider(),
        _buildDetailRow('Area', '${property.area.toStringAsFixed(0)} sqft'),
        const Divider(),
        _buildDetailRow('Status', property.status.toString().split('.').last),
        const Divider(),
        _buildDetailRow('Description', property.description),
        const Divider(),
        _buildDetailRow(
          'Date Added',
          DateFormat.yMMMd().format(property.dateAdded),
        ),
        const Divider(),
        _buildDetailRow('Currency', property.currency),
        const Divider(),
        _buildAmenityRow(context, 'Amenities', property.amenities ?? []),
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
            width: 120,
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

  Widget _buildAmenityRow(
    BuildContext context,
    String label,
    List<String> amenities,
  ) {
    return Consumer<PropertyProvider>(
      builder: (context, propertyProvider, _) {
        return FutureBuilder<Map<String, IconData>>(
          future: propertyProvider.fetchAmenitiesWithIcons(),
          builder: (context, snapshot) {
            // Use fetched amenities if available, otherwise fallback to provider's local amenities
            final Map<String, IconData> amenityIcons =
                snapshot.data ?? propertyProvider.amenityIcons;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child:
                        amenities.isEmpty
                            ? Text(
                              'None',
                              style: TextStyle(color: Colors.grey[600]),
                            )
                            : Wrap(
                              spacing: 8.0,
                              runSpacing: 4.0,
                              children:
                                  amenities.map((amenity) {
                                    final icon = amenityIcons[amenity];
                                    return Chip(
                                      avatar:
                                          icon != null
                                              ? Icon(icon, size: 18)
                                              : null,
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
          },
        );
      },
    );
  }
}
