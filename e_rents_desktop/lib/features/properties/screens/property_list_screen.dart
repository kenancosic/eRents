import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/base/crud/list_screen.dart';
import 'package:e_rents_desktop/features/properties/providers/property_provider.dart';
import 'package:provider/provider.dart';

class PropertyListScreen extends StatelessWidget {
  const PropertyListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
    
    return ListScreen<Property>(
      title: 'Properties',
      fetchItems: ({int page = 1, int pageSize = 20, Map<String, dynamic>? filters}) async {
        // Use PropertyProvider instead of mock data
        if (filters != null && filters.containsKey('search')) {
          final query = filters['search'] as String;
          return await propertyProvider.searchProperties(query);
        }
        return await propertyProvider.loadProperties();
      },
      itemBuilder: (context, property) {
        return Card(
          child: ListTile(
            title: Text(property.name),
            subtitle: Text('${property.address?.getCityStateCountry() ?? 'No address'} - \$${property.price}'),
            trailing: Chip(
              label: Text(property.status),
              backgroundColor: _getStatusColor(property.status),
            ),
            onTap: () {
              // Navigate to detail screen
            },
          ),
        );
      },
      onItemTap: (property) {
        // Handle item tap
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'rented':
        return Colors.blue;
      case 'maintenance':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}