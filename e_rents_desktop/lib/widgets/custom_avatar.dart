import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/services/image_service.dart';

class CustomAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final double borderWidth;
  final VoidCallback? onTap;

  const CustomAvatar({
    super.key,
    this.imageUrl,
    this.size = 40.0,
    this.borderWidth = 1,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF917AFD), Color(0xFF6246EA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            width: borderWidth,
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: ClipOval(
            child: Builder(
              builder: (context) {
                ImageService? images;
                try {
                  images = context.read<ImageService>();
                } catch (_) {
                  images = null;
                }
                final fallbackAsset = 'assets/images/user-image.png';
                final url = imageUrl;

                // If url points to backend Images JSON endpoint, use safe builder
                if (images != null && url != null && url.startsWith('/api/Images/')) {
                  final idStr = url.replaceFirst('/api/Images/', '');
                  final id = int.tryParse(idStr);
                  if (id != null) {
                    return images.buildImageById(
                      id,
                      fit: BoxFit.cover,
                      width: size - 4,
                      height: size - 4,
                      errorWidget: Image.asset(
                        fallbackAsset,
                        fit: BoxFit.cover,
                        width: size - 4,
                        height: size - 4,
                      ),
                    );
                  }
                }

                if (images != null) {
                  // Use ImageService for generic URLs/assets
                  return images.buildImage(
                    url ?? fallbackAsset,
                    fit: BoxFit.cover,
                    width: size - 4,
                    height: size - 4,
                  );
                }

                // No service in scope: fallback to asset
                final assetPath = (url != null && url.startsWith('assets/')) ? url : fallbackAsset;
                return Image.asset(
                  assetPath,
                  fit: BoxFit.cover,
                  width: size - 4,
                  height: size - 4,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
