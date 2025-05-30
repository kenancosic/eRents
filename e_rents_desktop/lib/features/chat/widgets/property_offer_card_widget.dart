import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/features/properties/providers/property_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class PropertyOfferCardWidget extends StatelessWidget {
  final String propertyId;

  const PropertyOfferCardWidget({super.key, required this.propertyId});

  @override
  Widget build(BuildContext context) {
    final propertyProvider = Provider.of<PropertyProvider>(
      context,
      listen: false,
    );
    Property? property;
    try {
      property = propertyProvider.items.firstWhere((p) => p.id == propertyId);
    } catch (e) {
      property = null; // Property not found
      // Optionally log this error: print('Property $propertyId not found for offer card: $e');
    }

    if (property == null) {
      // Fallback UI when property details are not found
      return Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: ListTile(
          leading: const Icon(Icons.error_outline, color: Colors.red),
          title: const Text('Property Offer'),
          subtitle: Text(
            'Details for property ID: $propertyId not found. Click to attempt navigation.',
          ),
          onTap: () {
            // Navigate to property details, which might fetch it if it exists
            context.push('/properties/$propertyId');
          },
        ),
      );
    }

    // Main UI when property details are found
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: InkWell(
        onTap: () {
          // Navigate using the non-null property object
          context.push('/properties/${property!.id}', extra: property);
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              property.images.isNotEmpty
                  ? (property.images.first.url!.startsWith('http')
                      ? Image.network(
                        property.images.first.url!,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      )
                      : Image.asset(
                        property.images.first.url!,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      ))
                  : Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.house_outlined,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Property Offer!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      property.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${property.type.name} - ₹${property.price.toStringAsFixed(0)}/month',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Click to view details',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
