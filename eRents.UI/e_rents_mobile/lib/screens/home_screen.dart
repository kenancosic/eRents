import 'package:flutter/material.dart';
import '../routes/base_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Home',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Welcome to eRents!',
              style: Theme.of(context).textTheme.headline5,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/bookings');
              },
              child: Text('View Bookings'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/properties');
              },
              child: Text('View Properties'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/profile');
              },
              child: Text('User Profile'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/notifications');
              },
              child: Text('Notifications'),
            ),
          ],
        ),
      ),
    );
  }
}
