import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/services/image_service.dart';
import 'package:e_rents_desktop/models/image.dart' as model;
import 'package:go_router/go_router.dart';

class PropertyImagesGrid extends StatelessWidget {
  final List<int> images; // image IDs (fallback path)
  final List<model.Image>? imagesData; // optional preloaded images (single-call path)
  final double? height;
  final int? primaryImageId;

  const PropertyImagesGrid({
    super.key,
    required this.images,
    this.imagesData,
    this.height,
    this.primaryImageId,
  });


  @override
  Widget build(BuildContext context) {
    final hasDataList = (imagesData != null && imagesData!.isNotEmpty);
    if (!hasDataList && images.isEmpty) {
      return Container(
        height: height ?? 300,
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

  Widget _buildImageTileFromData(
    BuildContext context,
    model.Image image, {
    bool isPrimary = false,
    required int imageIndex,
  }) {
    return GestureDetector(
      onTap: () => _showImageCarousel(context, imageIndex),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildImageWidget(
                context,
                imageId: image.imageId,
                fit: BoxFit.cover,
                errorWidget: Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
              if (isPrimary)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
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
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.1),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewAllOverlayFromData(
    BuildContext context,
    model.Image image,
    int remainingCount,
  ) {
    return GestureDetector(
      onTap: () => _showImageCarousel(context, 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildImageWidget(
                context,
                imageId: image.imageId,
                fit: BoxFit.cover,
                errorWidget: Container(
                  color: Colors.grey.shade200,
                  child: Icon(Icons.broken_image, size: 48, color: Colors.grey.shade400),
                ),
              ),
              Container(
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6)),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.photo_library,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '+${remainingCount + 1} more',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
    
    // Prefer provided data list; otherwise fall back to IDs list
    final firstIsData = hasDataList;
    final primaryImage = firstIsData ? imagesData!.first : images.first;
    final otherImages = firstIsData
        ? imagesData!.skip(1).toList()
        : images.skip(1).toList();

    return Container(
      height: height ?? 300, // Fixed height constraint (overridable)
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          // Primary image (left side)
          Expanded(
            flex: 3,
            child: firstIsData
                ? _buildImageTileFromData(
                    context,
                    primaryImage as model.Image,
                    isPrimary: true,
                    imageIndex: 0,
                  )
                : _buildImageTile(
                    context,
                    primaryImage as int,
                    isPrimary: true,
                    imageIndex: 0,
                  ),
          ),

          // Secondary images (right side)
          if (otherImages.isNotEmpty) ...[
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  ...otherImages.take(2).toList().asMap().entries.map((entry) {
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: entry.key == 0 ? 4.0 : 0,
                        ),
                        child: firstIsData
                            ? _buildImageTileFromData(
                                context,
                                entry.value as model.Image,
                                imageIndex: entry.key + 1,
                              )
                            : _buildImageTile(
                                context,
                                entry.value as int,
                                imageIndex: entry.key + 1,
                              ),
                      ),
                    );
                  }),

                  // "View All" overlay for remaining images
                  if (otherImages.length > 2)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: firstIsData
                            ? _buildViewAllOverlayFromData(
                                context,
                                otherImages[2] as model.Image,
                                (firstIsData ? imagesData!.length : images.length) - 3,
                              )
                            : _buildViewAllOverlay(
                                context,
                                otherImages[2] as int,
                                images.length - 3,
                              ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Safely try to read ImageService; return null if not provided in this route
  ImageService? _tryGetImages(BuildContext context) {
    try {
      return context.read<ImageService>();
    } catch (_) {
      return null;
    }
  }

  // Unified image builder: uses ImageService for network image by id
  Widget _buildImageWidget(
    BuildContext context, {
    int? imageId,
    BoxFit fit = BoxFit.cover,
    required Widget errorWidget,
  }) {
    final imagesService = _tryGetImages(context);
    if (imageId != null && imagesService != null) {
      // Delegate to centralized helper which handles image loading and errors
      return imagesService.buildImageByIdSimple(
        imageId,
        fit: fit,
        errorWidget: errorWidget,
      );
    }
    return errorWidget;
  }

  Widget _buildImageTile(
    BuildContext context,
    int imageId, {
    bool isPrimary = false,
    required int imageIndex,
  }) {
    return GestureDetector(
      onTap: () => _showImageCarousel(context, imageIndex),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildImageWidget(
                context,
                imageId: imageId,
                fit: BoxFit.cover,
                errorWidget: Container(
                  color: Colors.grey.shade200,
                  child: Icon(Icons.broken_image, size: 48, color: Colors.grey.shade400),
                ),
              ),

              // Primary image badge
              if (isPrimary)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
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

              // Hover overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.1)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewAllOverlay(
    BuildContext context,
    int imageId,
    int remainingCount,
  ) {
    return GestureDetector(
      onTap: () => _showImageCarousel(context, 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildImageWidget(
                context,
                imageId: imageId,
                fit: BoxFit.cover,
                errorWidget: Container(
                  color: Colors.grey.shade200,
                  child: Icon(Icons.broken_image, size: 48, color: Colors.grey.shade400),
                ),
              ),
              Container(
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6)),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.photo_library,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '+${remainingCount + 1} more',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageCarousel(BuildContext context, int initialIndex) {
    context.push(
      '/property-images',
      extra: {
        'images': images,
        'initialIndex': initialIndex,
      },
    );
  }
}
