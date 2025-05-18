import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/core/models/address_detail.dart';
import 'package:e_rents_mobile/core/models/geo_region.dart';
import 'package:e_rents_mobile/core/models/image_response.dart';
import 'package:e_rents_mobile/core/widgets/property_card.dart';
import 'package:e_rents_mobile/core/widgets/section_header.dart';
import 'package:e_rents_mobile/feature/property_detail/utils/view_context.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:typed_data';

class CurrentlyResidingSection extends StatelessWidget {
  CurrentlyResidingSection({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for an active lease
    final bool isTenant = true; // Assume user is a tenant
    final bool hasActiveLease = true; // Assume user has an active lease

    // Mock Property data
    // NOTE: Removed bedrooms and area from here as they are not in the mobile Property model
    final mockProperty = Property(
      propertyId: 101,
      ownerId: 1,
      name: 'Cozy Downtown Apartment',
      price: 1250.00,
      description:
          'A lovely apartment in the heart of the city, perfect for long-term stays.',
      averageRating: 4.7,
      images: [
        ImageResponse(
            imageId: 1,
            fileName:
                'assets/images/appartment.jpg', // Ensure this image exists
            imageData: ByteData(0), // Placeholder
            dateUploaded:
                DateTime.now() // This is fine as mockProperty is not const
            )
      ],
      addressDetail: AddressDetail(
        addressDetailId: 1,
        geoRegionId: 1,
        streetLine1: '123 Main Street',
        geoRegion: GeoRegion(
          geoRegionId: 1,
          city: 'Metropolis',
          country: 'USA',
        ),
      ),
    );

    if (isTenant && hasActiveLease) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
              title: 'Currently Residing',
              onSeeAll: () {
                // Navigate to a screen with more lease details or options
                // For example: context.push('/lease-details');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('See all lease details (Not implemented yet)')),
                );
              }),
          const SizedBox(height: 8),
          PropertyCard(
            title: mockProperty.name,
            location:
                '${mockProperty.addressDetail?.streetLine1}, ${mockProperty.addressDetail?.geoRegion?.city}',
            details: '2 rooms, 800 m²',
            price: '\$${mockProperty.price.toStringAsFixed(0)}',
            rating: mockProperty.averageRating?.toString() ?? 'N/A',
            imageUrl: mockProperty.images.isNotEmpty
                ? mockProperty.images.first.fileName
                : 'assets/images/placeholder.png',
            review: 75,
            rooms: 2,
            area: 800,
            onTap: () {
              context.push(
                '/property/${mockProperty.propertyId}',
                extra: {'viewContext': ViewContext.activeLease},
              );
            },
          ),
          const SizedBox(height: 12),
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.report_problem_outlined),
              label: const Text('Report Maintenance Issue'),
              onPressed: () {
                // TODO: Navigate to Maintenance Issue Reporting Screen/Dialog
                // Example: context.push('/report-maintenance-issue/${mockProperty.propertyId}');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Report issue for ${mockProperty.name} (Not implemented yet)')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      // Optionally, show something if the user is not currently residing anywhere
      // or if they are not a tenant. For now, returning an empty container.
      return SizedBox.shrink();
    }
  }
}
