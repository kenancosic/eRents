import 'package:flutter/material.dart';

class ProfilePicture extends StatelessWidget {
  final String imageUrl;

  const ProfilePicture({
    Key? key,
    required this.imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 50,
      backgroundImage: NetworkImage(imageUrl),
    );
  }
}
