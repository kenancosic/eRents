import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/services/secure_storage_service.dart';

class ImageService extends ApiService {
  ImageService(super.baseUrl, super.secureStorageService);

  /// Convert relative image URLs to absolute URLs
  String getImageUrl(String? relativeUrl) {
    if (relativeUrl == null || relativeUrl.isEmpty) {
      return '';
    }

    // If already absolute, return as-is
    if (relativeUrl.startsWith('http://') ||
        relativeUrl.startsWith('https://')) {
      return relativeUrl;
    }

    // If it's a relative API URL (starts with /), make it absolute
    if (relativeUrl.startsWith('/')) {
      return '$baseUrl$relativeUrl';
    }

    return relativeUrl;
  }

  /// Get thumbnail URL for an image
  String getThumbnailUrl(String? relativeUrl) {
    if (relativeUrl == null || relativeUrl.isEmpty) {
      return '';
    }

    // If the URL is already a thumbnail URL, return as-is
    if (relativeUrl.contains('/thumbnail')) {
      return getImageUrl(relativeUrl);
    }

    // If it's an image URL like /Image/123, convert to /Image/123/thumbnail
    if (relativeUrl.startsWith('/Image/')) {
      return getImageUrl('$relativeUrl/thumbnail');
    }

    return getImageUrl(relativeUrl);
  }
}
