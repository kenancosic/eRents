// lib/feature/property_detail/widgets/property_header.dart
import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/models/property.dart';

class PropertyHeader extends StatelessWidget {
  final Property property;

  const PropertyHeader({
    super.key,
    required this.property,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            property.name,
            style: Theme.of(context).textTheme.headlineMedium,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
        const SizedBox(width: 16),
        IconButton(
          style: IconButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            minimumSize: Size.zero,
          ),
          onPressed: () {},
          icon: const Icon(Icons.favorite_border, size: 24)
        ),
      ],
    );
  }
}