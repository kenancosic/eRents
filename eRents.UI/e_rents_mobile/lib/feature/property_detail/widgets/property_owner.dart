// lib/feature/property_detail/widgets/property_owner_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:e_rents_mobile/core/widgets/custom_avatar.dart';

class PropertyOwnerSection extends StatelessWidget {
  const PropertyOwnerSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CustomAvatar(
          imageUrl: 'assets/images/user-image.png',
          size: 40,
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Facility Owner',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                'Property Owner',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            // Handle message action
          },
          icon: SvgPicture.asset('assets/icons/message.svg'),
        ),
      ],
    );
  }
}