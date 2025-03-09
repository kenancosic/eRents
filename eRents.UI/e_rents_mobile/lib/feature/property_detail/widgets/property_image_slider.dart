// lib/feature/property_detail/widgets/property_image_slider.dart
import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/widgets/custom_slider.dart';
import 'package:e_rents_mobile/core/models/property.dart';

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
        Positioned(
          top: 48,
          left: 16,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: Colors.black.withValues(alpha: 0.7),
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}