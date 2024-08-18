import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_mobile/providers/booking_provider.dart';
import 'package:e_rents_mobile/models/booking.dart';
import 'package:e_rents_mobile/widgets/loading_indicator.dart';
import 'package:e_rents_mobile/widgets/custom_snack_bar.dart';

class BookingListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bookingProvider = Provider.of<BookingProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
      ),
      body: FutureBuilder<List<Booking>>(
        future: bookingProvider.getBookingsByUserId(1), // Replace with actual userId
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();  // Reusable loading indicator
          } else if (snapshot.hasError) {
            WidgetsBinding.instance?.addPostFrameCallback((_) {
              CustomSnackBar.showErrorSnackBar(snapshot.error.toString());  // Reusable error snackbar
            });
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final bookings = snapshot.data!;
            return ListView.builder(
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return ListTile(
                  title: Text(booking.propertyName),
                  subtitle: Text('${booking.startDate} - ${booking.endDate}'),
                );
              },
            );
          } else {
            return const Center(child: Text('No bookings found.'));
          }
        },
      ),
    );
  }
}
