import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/property.dart';

class TenantInfo extends StatelessWidget {
  final Property property;

  const TenantInfo({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Current Tenant',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundImage: AssetImage('assets/images/user-image.png'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.status == 'Occupied' ? 'John Doe' : 'No Tenant',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    property.status == 'Occupied'
                        ? 'john.doe@example.com'
                        : 'N/A',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    property.status == 'Occupied' ? '+1 (555) 123-4567' : 'N/A',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(),
        _buildLeaseInfo(
          'Lease Start',
          property.status == 'Occupied' ? '2023-01-01' : 'N/A',
        ),
        const Divider(),
        _buildLeaseInfo(
          'Lease End',
          property.status == 'Occupied' ? '2023-12-31' : 'N/A',
        ),
        const Divider(),
        _buildLeaseInfo(
          'Monthly Rent',
          '\$${property.price.toStringAsFixed(2)}',
        ),
        const Divider(),
        _buildLeaseInfo(
          'Payment Status',
          property.status == 'Occupied' ? 'Paid' : 'N/A',
        ),
      ],
    );
  }

  Widget _buildLeaseInfo(String label, String value) {
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
