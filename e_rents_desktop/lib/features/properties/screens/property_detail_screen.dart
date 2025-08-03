import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/base/crud/detail_screen.dart';
import 'package:e_rents_desktop/features/properties/providers/property_provider.dart';
import 'package:provider/provider.dart';

class PropertyDetailScreen extends StatelessWidget {
  final int propertyId;
  
  const PropertyDetailScreen({super.key, required this.propertyId});

  @override
  Widget build(BuildContext context) {
    final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
    
    return DetailScreen<Property>(
      title: 'Property Details',
      item: Property(
        propertyId: 0,
        ownerId: 0,
        name: '',
        description: '',
        price: 0.0,
        status: 'Available',
        imageIds: [],
        amenityIds: [],
      ), // Placeholder while loading
      fetchItem: (id) async {
        final property = await propertyProvider.loadProperty(int.parse(id));
        if (property == null) {
          throw Exception('Property not found');
        }
        return property;
      },
      itemId: propertyId.toString(),
      detailBuilder: (context, property) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Property title and basic info
              Text(
                property.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              
              // Location and price
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    property.address?.getCityStateCountry() ?? 'No address',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '\$${property.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Status chip
              Chip(
                label: Text(property.status),
                backgroundColor: _getStatusColor(property.status),
              ),
              const SizedBox(height: 16),
              
              // Description
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                property.description ?? '',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              
              // Created date
              if (property.dateAdded != null)
                Text(
                  'Created: ${property.dateAdded.toString()}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
            ],
          ),
        );
      },
      onEdit: (property) {
        // Handle edit action
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green.withOpacity(0.3);
      case 'rented':
        return Colors.blue.withOpacity(0.3);
      case 'maintenance':
        return Colors.orange.withOpacity(0.3);
      default:
        return Colors.grey.withOpacity(0.3);
    }
  }
}