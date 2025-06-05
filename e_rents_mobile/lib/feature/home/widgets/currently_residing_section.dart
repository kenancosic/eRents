import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/core/models/address.dart';

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
  const CurrentlyResidingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserBookingsProvider>(
      builder: (context, bookingsProvider, child) {
        // Find the first active booking
        Booking? activeBooking;
        try {
          activeBooking = bookingsProvider.upcomingBookings
              .firstWhere((b) => b.status == BookingStatus.active);
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
          imageIds: activeBooking.propertyImageUrl != null ? [1] : [],
          amenityIds: [1, 2, 3], // Default amenities for booking card
          address: Address(
            // Mock address as it's not in booking model
            streetLine1: 'Tap to view details',
            city: '',
            country: '',
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
            PropertyCard(
              property: propertyForCard,
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
          ],
        );
      },
    );
  }
}
