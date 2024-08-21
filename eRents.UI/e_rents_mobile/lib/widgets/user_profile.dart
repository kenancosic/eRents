import 'package:flutter/material.dart';
import 'profile_picture.dart'; // Import the ProfilePicture widget

class UserProfile extends StatelessWidget {
  final String username;
  final String email;
  final String phoneNumber;
  final String address;
  final String profilePictureUrl;

  const UserProfile({
    Key? key,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.profilePictureUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ProfilePicture(imageUrl: profilePictureUrl),
            SizedBox(height: 20),
            Text(
              username,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(email),
            SizedBox(height: 5),
            Text(phoneNumber),
            SizedBox(height: 5),
            Text(address),
          ],
        ),
      ),
    );
  }
}
