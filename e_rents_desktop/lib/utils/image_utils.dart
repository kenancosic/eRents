import 'package:flutter/material.dart';

class ImageUtils {
  /// Returns true if the URL is an asset path (starts with 'assets/')
  static bool isAssetPath(String url) {
    return url.startsWith('assets/');
  }

  /// Returns true if the URL is a network URL (contains protocol)
  static bool isNetworkUrl(String url) {
    return url.startsWith('http://') || url.startsWith('https://');
  }

  /// Creates the appropriate image widget based on the URL type
  static Widget buildImage(
    String url, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    Widget? errorWidget,
  }) {
    if (url.isEmpty) {
      return errorWidget ?? const Icon(Icons.image_not_supported);
    }

    if (isAssetPath(url)) {
      return Image.asset(
        url,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ??
              Image.asset(
                'assets/images/placeholder.jpg',
                fit: fit,
                width: width,
                height: height,
              );
        },
      );
    } else if (isNetworkUrl(url)) {
      return Image.network(
        url,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ??
              Image.asset(
                'assets/images/placeholder.jpg',
                fit: fit,
                width: width,
                height: height,
              );
        },
      );
    } else {
      // Assume it's a local file path
      return Image.asset(
        'assets/images/placeholder.jpg',
        fit: fit,
        width: width,
        height: height,
      );
    }
  }

  /// Creates the appropriate ImageProvider based on the URL type
  static ImageProvider buildImageProvider(String url) {
    if (url.isEmpty) {
      return const AssetImage('assets/images/placeholder.jpg');
    }

    if (isAssetPath(url)) {
      return AssetImage(url);
    } else if (isNetworkUrl(url)) {
      return NetworkImage(url);
    } else {
      // Assume it's a local file path
      return const AssetImage('assets/images/placeholder.jpg');
    }
  }
}
