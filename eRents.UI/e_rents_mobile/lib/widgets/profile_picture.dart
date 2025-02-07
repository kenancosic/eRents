import 'package:flutter/material.dart';

class ProfilePicture extends StatelessWidget {
  final String imageUrl;

  const ProfilePicture({
    super.key,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 50,
      backgroundImage: NetworkImage(imageUrl),
    );
  }
}
