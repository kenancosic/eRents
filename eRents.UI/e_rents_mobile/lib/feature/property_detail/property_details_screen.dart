import 'package:e_rents_mobile/feature/property_detail/property_details_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PropertyDetailScreen extends StatelessWidget {
  final int propertyId;

  PropertyDetailScreen({required this.propertyId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PropertyDetailProvider()..fetchPropertyDetail(propertyId),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Property Details'),
        ),
        body: Consumer<PropertyDetailProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return Center(child: CircularProgressIndicator());
            } else if (provider.errorMessage != null) {
              return Center(child: Text(provider.errorMessage!));
            } else if (provider.property == null) {
              return Center(child: Text('Property not found'));
            }

            final property = provider.property!;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image.network(property.images.first.fileName),  // Assuming there's a main image URL
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          property.name,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        SizedBox(height: 8),
                        Text(
                          '${property.city}, ${property.address}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Price: \$${property.price.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        SizedBox(height: 16),
                        Text(property.description ?? 'No description available.'),
                        SizedBox(height: 16),
                        Text(
                          'Rating: ${property.averageRating ?? 'N/A'} ★',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            // Action to book property, save, or any other interaction
                          },
                          child: Text('Book Now'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}