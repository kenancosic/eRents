import 'package:e_rents_mobile/core/models/booking_model.dart'; // Using BookingModel for UI representation
import 'package:e_rents_mobile/core/widgets/property_card.dart'; // Can be adapted or a new card created
import 'package:e_rents_mobile/core/widgets/section_header.dart';
import 'package:e_rents_mobile/feature/property_detail/utils/view_context.dart'; // Added import
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart'; // For date formatting

class UpcomingStaysSection extends StatelessWidget {
  UpcomingStaysSection({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Booking> upcomingBookings = [
      Booking(
        bookingId: 101,
        propertyId: 201,
        userId: 1,
        propertyName: 'Sunny Beachside Condo',
        propertyImageUrl: 'assets/images/house.jpg', // Ensure this image exists
        startDate: DateTime.now().add(const Duration(days: 10)),
        endDate: DateTime.now().add(const Duration(days: 17)),
        totalPrice: 850.00,
        status: BookingStatus.Upcoming,
        currency: 'USD',
        bookingDate: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Booking(
        bookingId: 102,
        propertyId: 202,
        userId: 1,
        propertyName: 'Mountain View Cabin Retreat',
        propertyImageUrl:
            'assets/images/appartment.jpg', // Ensure this image exists
        startDate: DateTime.now().add(const Duration(days: 45)),
        endDate: DateTime.now().add(const Duration(days: 50)),
        totalPrice: 600.00,
        status: BookingStatus.Upcoming,
        currency: 'USD',
        bookingDate: DateTime.now().subtract(const Duration(days: 10)),
      ),
      Booking(
        bookingId: 103,
        propertyId: 203,
        userId: 1,
        propertyName: 'Historic Downtown Studio',
        propertyImageUrl: 'assets/images/house.jpg', // Ensure this image exists
        startDate: DateTime.now().add(const Duration(days: 90)),
        endDate: DateTime.now().add(const Duration(days: 97)),
        totalPrice: 475.00,
        status: BookingStatus.Upcoming,
        currency: 'USD',
        bookingDate: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];

    if (upcomingBookings.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
              title: 'Upcoming Stays',
              onSeeAll: () {
                context.push('/profile/booking-history');
              }),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
            child: Center(
              child: Text('No upcoming stays planned yet.',
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
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
            }),
        const SizedBox(height: 8),
        SizedBox(
          height: 210, // Adjusted height slightly for card design
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: upcomingBookings.length,
            itemBuilder: (context, index) {
              final booking = upcomingBookings[index];
              return SizedBox(
                width: MediaQuery.of(context).size.width *
                    0.75, // Card width adjustment
                child: _UpcomingStayCard(booking: booking),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _UpcomingStayCard extends StatelessWidget {
  final Booking booking;

  const _UpcomingStayCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('MMM d, yyyy');
    final DateFormat shortDateFormat = DateFormat('MMM d');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: InkWell(
        onTap: () {
          context.push(
            '/property/${booking.propertyId}',
            extra: {
              'viewContext': ViewContext.upcomingBooking,
              'bookingId': booking.bookingId,
            },
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 100, // Image height
              width: double.infinity,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.asset(
                  booking.propertyImageUrl ?? 'assets/images/placeholder.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child: Icon(Icons.broken_image, color: Colors.grey[600])),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      booking.propertyName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${shortDateFormat.format(booking.startDate)} - ${booking.endDate != null ? shortDateFormat.format(booking.endDate!) : 'N/A'}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      'Total: ${booking.totalPrice.toStringAsFixed(0)} ${booking.currency}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
