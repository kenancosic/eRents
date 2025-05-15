import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/widgets/custom_app_bar.dart'; // For a consistent AppBar
import 'package:e_rents_mobile/core/base/base_screen.dart'; // If you want to use BaseScreen

class BookingHistoryScreen extends StatelessWidget {
  const BookingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appBar = CustomAppBar(
      title: 'Booking History',
      showBackButton: true, // Allow navigation back to profile screen
    );

    // Using BaseScreen for consistency, ensuring no bottom nav bar here
    return BaseScreen(
      showAppBar: true,
      appBar: appBar,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Booking History',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Your past bookings will appear here.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              '(Coming Soon)',
              style: TextStyle(fontSize: 14, color: Colors.blueGrey),
            ),
          ],
        ),
      ),
    );
  }
}
