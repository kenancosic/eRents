import 'package:e_rents_mobile/core/models/booking_model.dart'; // Using BookingModel for UI representation
import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/core/models/address_detail.dart';
import 'package:e_rents_mobile/core/models/geo_region.dart';

import 'package:e_rents_mobile/core/widgets/section_header.dart';
import 'package:e_rents_mobile/core/widgets/property_card.dart';
import 'package:e_rents_mobile/feature/property_detail/utils/view_context.dart'; // Added import
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:provider/provider.dart'; // Added import
import 'package:e_rents_mobile/feature/profile/user_bookings_provider.dart'; // Added import
import 'dart:typed_data';

class UpcomingStaysSection extends StatelessWidget {
  const UpcomingStaysSection({super.key});

  /// Converts a Booking to a Property-like object for display in PropertyCard
  Property _createPropertyFromBooking(Booking booking) {
    return Property(
      propertyId: booking.propertyId,
      ownerId: 1, // Mock owner ID
      name: booking.propertyName,
      price: booking.totalPrice,
      description:
          'Your upcoming booking from ${DateFormat.yMMMd().format(booking.startDate)}${booking.endDate != null ? ' to ${DateFormat.yMMMd().format(booking.endDate!)}' : ''}',
      averageRating: 4.8, // Mock rating since it's not in booking
      imageIds: [
        booking.propertyId
      ], // Use booking propertyId as imageId placeholder
      amenityIds: [1, 2, 3], // Default amenities for booking card
      addressDetail: AddressDetail(
        addressDetailId: booking.propertyId,
        geoRegionId: 1,
        streetLine1: 'Property Address', // Mock address
        geoRegion: GeoRegion(
          geoRegionId: 1,
          city: 'City',
          country: 'Country',
          state: 'State',
        ),
      ),
      facilities: "Wi-Fi, Kitchen, Air Conditioning", // Mock facilities
      status: PropertyStatus.rented,
      dateAdded: booking.bookingDate ?? DateTime.now(),
      rentalType: _determineRentalType(booking),
      minimumStayDays: booking.endDate != null
          ? booking.endDate!.difference(booking.startDate).inDays
          : 30,
    );
  }

  /// Determines rental type based on booking duration
  PropertyRentalType _determineRentalType(Booking booking) {
    if (booking.endDate == null) {
      return PropertyRentalType
          .monthly; // Open-ended bookings are typically monthly
    }

    final duration = booking.endDate!.difference(booking.startDate).inDays;
    if (duration <= 30) {
      return PropertyRentalType.daily;
    } else {
      return PropertyRentalType.monthly;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserBookingsProvider>(
      builder: (context, bookingsProvider, child) {
        // Filter for bookings that are Upcoming and not Active
        final List<Booking> upcomingDisplayBookings = bookingsProvider
            .upcomingBookings
            .where((b) => b.status == BookingStatus.upcoming)
            .toList();

        if (upcomingDisplayBookings.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Upcoming Stays',
                onSeeAll: () {
                  context.push('/profile/booking-history');
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                child: Center(
                  child: Text(
                    'No upcoming stays planned yet.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Upcoming Stays',
              onSeeAll: () {
                context.push('/profile/booking-history');
              },
            ),
            SizedBox(
              height: 240, // Height for vertical cards
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: upcomingDisplayBookings.length,
                itemBuilder: (context, index) {
                  final booking = upcomingDisplayBookings[index];
                  final property = _createPropertyFromBooking(booking);

                  return SizedBox(
                    width: MediaQuery.of(context).size.width * 0.75,
                    child: Stack(
                      children: [
                        // Use the new PropertyCard.vertical
                        PropertyCard.vertical(
                          property: property,
                          onTap: () {
                            context.push(
                              '/property/${booking.propertyId}',
                              extra: {
                                'viewContext': ViewContext.upcomingBooking,
                                'bookingId': booking.bookingId,
                              },
                            );
                          },
                        ),
                        // Overlay booking-specific information
                        Positioned(
                          bottom: 8,
                          left: 8,
                          right: 8,
                          child: _buildBookingOverlay(booking),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// Builds an overlay with booking-specific information
  Widget _buildBookingOverlay(Booking booking) {
    final DateFormat shortDateFormat = DateFormat('MMM d');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              '${shortDateFormat.format(booking.startDate)} - ${booking.endDate != null ? shortDateFormat.format(booking.endDate!) : 'Open'}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${booking.totalPrice.toStringAsFixed(0)} ${booking.currency}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
