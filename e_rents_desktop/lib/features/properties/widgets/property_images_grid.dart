import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_desktop/models/image_info.dart' as erents;
import 'package:e_rents_desktop/utils/image_utils.dart';

class PropertyImagesGrid extends StatelessWidget {
  final List<erents.ImageInfo> images;

  const PropertyImagesGrid({super.key, required this.images});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Click on an image to view it in full size',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
          ),
          itemCount: images.length,
          itemBuilder: (context, index) {
            final image = images[index];
            return GestureDetector(
              onTap: () => _showImageDialog(context, image),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ImageUtils.buildImage(
                      image.url!,
                      fit: BoxFit.cover,
                      errorWidget: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey[600],
                          size: 48,
                        ),
                      ),
                    ),
                    if (index == 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Cover',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showImageDialog(BuildContext context, erents.ImageInfo image) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Stack(
              children: [
                ImageUtils.buildImage(
                  image.url!,
                  fit: BoxFit.contain,
                  errorWidget: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.grey[600],
                      size: 64,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
