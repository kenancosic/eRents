import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/property.dart';

class PropertyStatsCard extends StatelessWidget {
  final List<Property> properties;

  const PropertyStatsCard({super.key, required this.properties});

  @override
  Widget build(BuildContext context) {
    final totalProperties = properties.length;
    final occupiedProperties =
        properties.where((p) => p.status == 'Occupied').length;
    final vacantProperties = totalProperties - occupiedProperties;
    final averagePrice =
        properties.isEmpty
            ? 0
            : properties.map((p) => p.price).reduce((a, b) => a + b) /
                totalProperties;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Property Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Total Properties',
                    totalProperties.toString(),
                    Colors.blue,
                    Icons.home,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Occupied',
                    occupiedProperties.toString(),
                    Colors.green,
                    Icons.people,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Vacant',
                    vacantProperties.toString(),
                    Colors.orange,
                    Icons.home_work,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Avg. Price',
                    '\$${averagePrice.toStringAsFixed(0)}',
                    Colors.purple,
                    Icons.attach_money,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
