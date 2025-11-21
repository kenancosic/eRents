import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LocationWidget extends StatelessWidget {
  final String title;
  final String location;

  const LocationWidget({
    super.key,
    required this.title,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF7D7F88),
            fontSize: 14,
            fontFamily: 'Hind',
            fontWeight: FontWeight.w400,
            height: 1.3,
            letterSpacing: 0.18,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/icons/location.svg',
              height: 16,
              colorFilter: const ColorFilter.mode(
                Color(0xFF7065F0),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              location,
              style: const TextStyle(
                color: Color(0xFF7065F0),
                fontSize: 16,
                fontFamily: 'Hind',
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ],
        ),
      ],
    );
  }
}