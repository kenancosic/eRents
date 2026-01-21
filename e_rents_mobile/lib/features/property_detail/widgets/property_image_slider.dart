// lib/feature/property_detail/widgets/property_image_slider.dart
import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/widgets/custom_slider.dart';
import 'package:e_rents_mobile/core/models/property_detail.dart';
import 'package:e_rents_mobile/core/services/api_service.dart';
import 'package:provider/provider.dart';

class PropertyImageSlider extends StatefulWidget {
  final PropertyDetail property;
  final Function(int) onPageChanged;

  const PropertyImageSlider({
    super.key,
    required this.property,
    required this.onPageChanged,
  });

  @override
  State<PropertyImageSlider> createState() => _PropertyImageSliderState();
}

class _PropertyImageSliderState extends State<PropertyImageSlider> {
  bool _hasPrefetched = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Prefetch images only once to avoid repeated scheduling on every rebuild
    if (!_hasPrefetched) {
      _hasPrefetched = true;
      final apiService = context.read<ApiService>();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final toPrefetch = widget.property.imageIds.take(3);
        for (final imageId in toPrefetch) {
          final url = apiService.makeAbsoluteUrl('/api/Images/$imageId/content');
          precacheImage(NetworkImage(url), context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final apiService = context.read<ApiService>();
    
    return Stack(
      children: [
        CustomSlider(
          items: widget.property.imageIds
              .map((imageId) => apiService.buildImage(
                    // Serve raw bytes from backend ImagesController content endpoint
                    '/api/Images/$imageId/content',
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorWidget: Container(
                      width: double.infinity,
                      height: 200,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5F5F5),
                        image: DecorationImage(
                          image: AssetImage('assets/images/placeholder.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ))
              .toList(),
          onPageChanged: widget.onPageChanged,
          useNumbering: true,
        ),
      ],
    );
  }
}
