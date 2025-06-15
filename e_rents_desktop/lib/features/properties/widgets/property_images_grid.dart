import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/base/service_locator.dart';

class PropertyImagesGrid extends StatelessWidget {
  final List<int> images;

  const PropertyImagesGrid({super.key, required this.images});

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text('No Images Available'),
            ],
          ),
        ),
      );
    }

    final primaryImage = images.first;
    final otherImages = images.skip(1).toList();

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _buildImageTile(context, primaryImage, isPrimary: true),
          ),
          if (otherImages.isNotEmpty) ...[
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: Column(
                children:
                    otherImages
                        .take(3)
                        .map(
                          (id) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: _buildImageTile(context, id),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageTile(
    BuildContext context,
    int imageId, {
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: () => _showImageDialog(context, imageId),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            getService<ApiService>().buildImage(
              '/Image/$imageId',
              fit: BoxFit.cover,
            ),
            if (isPrimary)
              Positioned(
                top: 8,
                left: 8,
                child: Chip(
                  label: const Text('Cover'),
                  backgroundColor: Colors.black.withValues(alpha: 0.5),
                  labelStyle: const TextStyle(color: Colors.white),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageDialog(BuildContext context, int imageId) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: getService<ApiService>().buildImage(
                    '/Image/$imageId',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text(
                    'Close',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
