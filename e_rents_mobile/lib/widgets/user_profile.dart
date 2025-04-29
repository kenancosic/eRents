import 'package:flutter/material.dart';
import 'profile_picture.dart'; // Import the ProfilePicture widget

class UserProfile extends StatelessWidget {
  final String username;
  final String email;
  final String phoneNumber;
  final String address;
  final String profilePictureUrl;

  const UserProfile({
    super.key,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.profilePictureUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ProfilePicture(imageUrl: profilePictureUrl),
            const SizedBox(height: 20),
            Text(
              username,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(email),
            const SizedBox(height: 5),
            Text(phoneNumber),
            const SizedBox(height: 5),
            Text(address),
          ],
        ),
      ),
    );
  }
}
