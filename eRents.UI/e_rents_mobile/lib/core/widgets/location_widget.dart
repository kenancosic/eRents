import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LocationWidget extends StatelessWidget {
  final String title;
  final String location;

  const LocationWidget({
    Key? key,
    required this.title,
    required this.location,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF7D7F88),
            fontSize: 14,
            fontFamily: 'Hind',
            fontWeight: FontWeight.w400,
            height: 1.2,
            letterSpacing: 0.18,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic, // Align based on the text baseline
          children: [
            SvgPicture.asset(
              'assets/icons/location.svg',
              height: 20, // Adjust the height as needed
            ),
            const SizedBox(width: 8),
            Text(
              location,
              style: const TextStyle(
                color: Color(0xFF1A1E25),
                fontSize: 20,
                fontFamily: 'Hind',
                fontWeight: FontWeight.w700,
                height: 1.4, // Ensure the text height is normal
              ),
            ),
          ],
        ),
      ],
    );
  }
}
