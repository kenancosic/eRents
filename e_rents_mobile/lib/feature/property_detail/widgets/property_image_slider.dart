// lib/feature/property_detail/widgets/property_image_slider.dart
import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/widgets/custom_slider.dart';
import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/core/services/api_service.dart';
import 'package:e_rents_mobile/core/services/service_locator.dart';

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
          items: property.imageIds
              .map((imageId) => ServiceLocator.get<ApiService>().buildImage(
                    '/Image/$imageId',
                    width: double.infinity,
                    height: 350,
                    fit: BoxFit.cover,
                    errorWidget: Container(
                      width: double.infinity,
                      height: 350,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.image,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                  ))
              .toList(),
          onPageChanged: onPageChanged,
          useNumbering: true,
        ),
      ],
    );
  }
}
