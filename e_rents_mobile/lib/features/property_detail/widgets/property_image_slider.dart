// lib/feature/property_detail/widgets/property_image_slider.dart
import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/widgets/custom_slider.dart';
import 'package:e_rents_mobile/core/models/property_detail.dart';
import 'package:e_rents_mobile/core/services/api_service.dart';
import 'package:provider/provider.dart';

class PropertyImageSlider extends StatelessWidget {
  final PropertyDetail property;
  final Function(int) onPageChanged;

  const PropertyImageSlider({
    super.key,
    required this.property,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final apiService = context.read<ApiService>();
    // Lightweight prefetch of first few images to reduce perceived loading time
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final toPrefetch = property.imageIds.take(3);
      for (final imageId in toPrefetch) {
        final url = apiService.makeAbsoluteUrl('/api/Images/$imageId/content');
        precacheImage(NetworkImage(url), context);
      }
    });
    
    return Stack(
      children: [
        CustomSlider(
          items: property.imageIds
              .map((imageId) => apiService.buildImage(
                    // Serve raw bytes from backend ImagesController content endpoint
                    '/api/Images/$imageId/content',
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
