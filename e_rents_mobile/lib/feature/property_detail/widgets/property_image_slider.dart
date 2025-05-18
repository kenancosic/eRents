// lib/feature/property_detail/widgets/property_image_slider.dart
import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/widgets/custom_slider.dart';
import 'package:e_rents_mobile/core/models/property.dart';
import 'package:go_router/go_router.dart';

class PropertyImageSlider extends StatelessWidget {
  final Property property;
  final Function(int) onPageChanged;

  const PropertyImageSlider({
    super.key,
    required this.property,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomSlider(
          items: property.images
              .map((image) => Image.asset(
                    image.fileName,
                    width: double.infinity,
                    height: 350,
                    fit: BoxFit.cover,
                  ))
              .toList(),
          onPageChanged: onPageChanged,
          useNumbering: true,
        ),
      ],
    );
  }
}
