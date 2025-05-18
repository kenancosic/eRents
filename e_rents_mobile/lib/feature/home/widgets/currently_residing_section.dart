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
import 'package:provider/provider.dart';
import 'package:e_rents_mobile/feature/profile/user_bookings_provider.dart';
import 'package:e_rents_mobile/core/models/booking_model.dart';

class CurrentlyResidingSection extends StatelessWidget {
  CurrentlyResidingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserBookingsProvider>(
      builder: (context, bookingsProvider, child) {
        // Find the first active booking
        Booking? activeBooking;
        try {
          activeBooking = bookingsProvider.upcomingBookings
              .firstWhere((b) => b.status == BookingStatus.Active);
        } catch (e) {
          activeBooking = null; // No active booking found
        }

        if (activeBooking == null) {
          // Optionally, show something else if no active lease, or just shrink
          return const SizedBox.shrink();
        }

        // Use details from the activeBooking
        // Creating a minimal Property object for the card from booking details
        // This is a simplification; ideally, you might fetch full property details
        // or have a more complete Property summary in your Booking model.
        final propertyForCard = Property(
          propertyId: activeBooking.propertyId,
          ownerId: activeBooking
              .userId, // Assuming userId on booking is ownerId, adjust if needed
          name: activeBooking.propertyName,
          price: activeBooking.totalPrice /
              ((activeBooking.endDate
                          ?.difference(activeBooking.startDate)
                          .inDays ??
                      30) /
                  30.0), // Approximate monthly price if possible
          images: activeBooking.propertyImageUrl != null
              ? [
                  ImageResponse(
                    imageId: 1, // Placeholder
                    fileName: activeBooking.propertyImageUrl!,
                    imageData: ByteData(0), // Placeholder
                    dateUploaded: DateTime.now(),
                  )
                ]
              : [],
          addressDetail: AddressDetail(
            // Mock address detail as it's not in booking model
            addressDetailId: 1,
            geoRegionId: 1,
            streetLine1: 'Tap to view details',
            geoRegion: GeoRegion(geoRegionId: 1, city: '', country: ''),
          ),
          averageRating:
              null, // Not directly in booking model, could be fetched separately
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
                title: 'Currently Residing',
                onSeeAll: () {
                  context.push('/profile/booking-history');
                }),
            const SizedBox(height: 8),
            PropertyCard(
              title: propertyForCard.name,
              location: propertyForCard.addressDetail?.streetLine1 ??
                  'Unknown location',
              details: 'Tap to see details', // Simplified details
              price:
                  '\$${(activeBooking.totalPrice / ((activeBooking.endDate?.difference(activeBooking.startDate).inDays ?? 30) / 30.0)).toStringAsFixed(0)} /mo',
              rating: propertyForCard.averageRating?.toString() ?? 'N/A',
              imageUrl: propertyForCard.images.isNotEmpty
                  ? propertyForCard.images.first.fileName
                  : 'assets/images/placeholder.png',
              review: 0, // Placeholder
              rooms: 0, // Placeholder
              area: 0, // Placeholder
              onTap: () {
                context.push(
                  '/property/${propertyForCard.propertyId}',
                  extra: {
                    'viewContext': ViewContext.activeLease,
                    'bookingId': activeBooking!.bookingId, // Pass the bookingId
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.report_problem_outlined),
                label: const Text('Report Maintenance Issue'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Report issue for ${propertyForCard.name} (Not implemented yet)')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                  foregroundColor:
                      Theme.of(context).colorScheme.onErrorContainer,
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
      },
    );
  }
}
