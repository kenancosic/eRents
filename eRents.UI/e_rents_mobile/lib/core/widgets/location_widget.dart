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
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text(
              "Your location: ",
              style: TextStyle(
                color: Color(0xFF7D7F88),
                fontSize: 16,
                fontFamily: 'Hind',
                fontWeight: FontWeight.w400,
                height: 1.3,
                letterSpacing: 0.18,
              ),
            ),
            Wrap(
              children: [
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
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: SvgPicture.asset(
                    'assets/icons/location.svg',
                    height: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}