import 'package:e_rents_mobile/providers/base_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../routes/base_screen.dart';

class BookingListScreen extends StatelessWidget {
  const BookingListScreen({Key? key}) : super(key: key); // Add Key parameter

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Bookings',
      body: Consumer<BookingProvider>(
        builder: (context, provider, child) {
          if (provider.state == ViewState.Busy) {
            return const Center(child: CircularProgressIndicator()); // Add const
          }

          return ListView.builder(
            itemCount: provider.bookings.length,
            itemBuilder: (context, index) {
              final booking = provider.bookings[index];
              return ListTile(
                title: Text(booking.propertyName),
                subtitle: Text('${booking.startDate} - ${booking.endDate}'),
                trailing: Text(booking.status),
                onTap: () {
                  Navigator.pushNamed(context, '/booking_details', arguments: booking);
                },
              );
            },
          );
        },
      ),
    );
  }
}
