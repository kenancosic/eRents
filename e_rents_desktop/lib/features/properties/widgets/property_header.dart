import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/widgets/status_chip.dart';

class PropertyHeader extends StatelessWidget {
  final Property property;

  const PropertyHeader({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    property.address,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildInfoChip(
                        icon: Icons.bed,
                        text: '${property.bedrooms} Beds',
                      ),
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        icon: Icons.bathtub,
                        text: '${property.bathrooms} Baths',
                      ),
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        icon: Icons.square_foot,
                        text: '${property.area} sqft',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildStatusChip(property.status),
                  const SizedBox(height: 16),
                  Text(
                    '\$${property.price.toStringAsFixed(2)}/month',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(PropertyStatus status) {
    String label;
    Color backgroundColor;
    IconData iconData;

    switch (status) {
      case PropertyStatus.available:
        label = 'Available';
        backgroundColor = Colors.green.shade600;
        iconData = Icons.check_circle_outline;
        break;
      case PropertyStatus.rented:
        label = 'Rented';
        backgroundColor = Colors.orange.shade700;
        iconData = Icons.house_outlined;
        break;
      case PropertyStatus.maintenance:
        label = 'Maintenance';
        backgroundColor = Colors.blueGrey.shade500;
        iconData = Icons.build_outlined;
        break;
      case PropertyStatus.unavailable:
      default:
        label = status.toString().split('.').last;
        backgroundColor = Colors.grey.shade500;
        iconData = Icons.help_outline;
    }

    return StatusChip(
      label: label,
      backgroundColor: backgroundColor,
      iconData: iconData,
    );
  }

  Widget _buildInfoChip({required IconData icon, required String text}) {
    return Chip(avatar: Icon(icon, size: 16), label: Text(text));
  }

  Widget _buildInfoRow(String label, String value) {
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
}
