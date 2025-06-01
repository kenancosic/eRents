import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ImageUtils {
  /// Get base URL from the same source as ApiService
  static String get _baseApiUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000';

  /// Returns true if the URL is an asset path (starts with 'assets/')
  static bool isAssetPath(String url) {
    return url.startsWith('assets/');
  }

  /// Returns true if the URL is a network URL (contains protocol)
  static bool isNetworkUrl(String url) {
    return url.startsWith('http://') || url.startsWith('https://');
  }

  /// Converts relative API URLs to absolute URLs
  static String makeAbsoluteUrl(String url) {
    if (url.isEmpty) return url;

    // If already absolute, return as-is
    if (isNetworkUrl(url) || isAssetPath(url)) {
      return url;
    }

    // If it's a relative API URL (starts with /), make it absolute
    if (url.startsWith('/')) {
      return '$_baseApiUrl$url';
    }

    return url;
  }

  /// Creates the appropriate image widget based on the URL type
  /// Following frontend development rules for proper image handling
  static Widget buildImage(
    String? imageUrl, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    Widget? errorWidget,
  }) {
    // Handle null or empty URLs with fallback
    if (imageUrl == null || imageUrl.isEmpty) {
      return errorWidget ??
          Icon(Icons.image, size: width ?? height ?? 64, color: Colors.grey);
    }

    // Convert relative URLs to absolute URLs using existing logic
    final fullUrl = makeAbsoluteUrl(imageUrl);

    if (isAssetPath(imageUrl)) {
      return Image.asset(
        imageUrl,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ??
              Icon(
                Icons.broken_image,
                size: width ?? height ?? 64,
                color: Colors.grey,
              );
        },
      );
    } else {
      // Network image with proper loading and error handling
      return Image.network(
        fullUrl,
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                value:
                    loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                strokeWidth: 2,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ??
              Icon(
                Icons.broken_image,
                size: width ?? height ?? 64,
                color: Colors.grey,
              );
        },
      );
    }
  }

  /// Creates the appropriate ImageProvider based on the URL type
  /// Following frontend development rules for proper URL handling
  static ImageProvider buildImageProvider(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      // Return a placeholder provider - you might want to add a default asset
      return const NetworkImage(
        'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7',
      ); // 1x1 transparent gif
    }

    // Convert relative URLs to absolute URLs using existing logic
    final fullUrl = makeAbsoluteUrl(imageUrl);

    if (isAssetPath(imageUrl)) {
      return AssetImage(imageUrl);
    } else {
      return NetworkImage(fullUrl);
    }
  }
}
