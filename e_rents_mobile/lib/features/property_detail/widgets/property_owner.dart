// lib/feature/property_detail/widgets/property_owner_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_mobile/core/widgets/custom_avatar.dart';
// Removed legacy Make Offer flow; booking proceeds via Checkout

class PropertyOwnerSection extends StatelessWidget {
  final int? ownerId;
  final int? propertyId; // Add property ID for offers
  final String? ownerName;
  final String? ownerEmail;
  final String? profileImageUrl;

  const PropertyOwnerSection({
    super.key,
    this.ownerId,
    this.propertyId,
    this.ownerName,
    this.ownerEmail,
    this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            if (ownerId != null && ownerId! > 0) {
              context.push('/user/${ownerId!.toString()}', extra: {
                'displayName': ownerName ?? 'User',
              });
            }
          },
          child: Row(
            children: [
              CustomAvatar(
                imageUrl: profileImageUrl ?? 'assets/images/user-image.png',
                size: 40,
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ownerName ?? 'Facility Owner',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      ownerEmail ?? 'Property Owner',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _contactPropertyOwner(context),
                icon: SvgPicture.asset('assets/icons/message.svg'),
                tooltip: 'Message Owner',
              ),
            ],
          ),
        ),
        // Legacy 'Make Offer' flow removed in favor of direct Checkout booking.
      ],
    );
  }

  void _contactPropertyOwner(BuildContext context) {
    if (ownerId != null && ownerId! > 0) {
      // Use go() to navigate to Chat tab with conversation open
      // This properly switches to the Chat tab instead of pushing onto current stack
      context.go('/chat/${ownerId!.toString()}', extra: {
        'name': ownerName ?? 'Property Owner',
      });
    } else {
      // Use go() to switch to Chat tab (contacts list)
      context.go('/chat');
    }
  }
}
