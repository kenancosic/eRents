import 'dart:convert';
import 'dart:typed_data';

import 'package:e_rents_desktop/models/image.dart' as model;
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:flutter/widgets.dart';
import 'package:e_rents_desktop/utils/logger.dart';

/// Simplified ImageService that works with full images only (no thumbnails).
/// This approach eliminates the complex thumbnail handling that was causing corruption issues.
class ImageService {
  final ApiService api;
  ImageService(this.api);

  // Simple in-memory cache to avoid repeated network calls
  static const int _maxCacheSize = 20;
  final Map<int, model.Image> _imageCache = <int, model.Image>{};

  /// List images with basic filters. Returns only metadata + full images by default.
  Future<List<model.Image>> getImages({
    int? propertyId,
    int? maintenanceIssueId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };
    if (propertyId != null) params['propertyId'] = propertyId.toString();
    if (maintenanceIssueId != null) {
      params['maintenanceIssueId'] = maintenanceIssueId.toString();
    }
    final query = params.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&');
    final resp = await api.get('/Images?$query');
    final decoded = jsonDecode(resp.body);

    // Backend returns PagedResponse<ImageResponse> with Items property
    final items = (decoded['items'] ?? decoded['Items'] ?? []) as List<dynamic>;
    return items.map((e) => model.Image.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// Get a single image with full data. Always fetches full image data.
  Future<model.Image> getImage(int id) async {
    // Serve from cache if present
    final cached = _imageCache[id];
    if (cached != null) return cached;

    // Always fetch full image data
    final resp = await api.get('/Images/$id');
    final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
    final image = model.Image.fromJson(decoded);

    // Populate cache
    _cacheImage(id, image);

    return image;
  }

  void _cacheImage(int id, model.Image image) {
    if (_imageCache.length >= _maxCacheSize && _imageCache.isNotEmpty) {
      // Remove oldest key (approximate FIFO)
      _imageCache.remove(_imageCache.keys.first);
    }
    _imageCache[id] = image;
  }

  /// Simplified builder: single FutureBuilder + Image.memory with errorBuilder.
  /// Uses getImage() under the hood and avoids nested futures/decoding steps.
  Widget buildImageByIdSimple(
    int imageId, {
    double? width,
    double? height,
    BoxFit? fit,
    Widget? errorWidget,
  }) {
    return FutureBuilder<model.Image>(
      future: getImage(imageId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: width,
            height: height,
            child: const ColoredBox(color: Color(0xFFEAEAEA)),
          );
        }
        
        if (snapshot.hasError || !snapshot.hasData) {
          log.warning('ImageService.buildImageByIdSimple: failed to load imageId=$imageId error=${snapshot.error}');
          return errorWidget ?? SizedBox(
            width: width,
            height: height,
            child: const ColoredBox(color: Color(0xFFE0E0E0)),
          );
        }
        
        final image = snapshot.data!;
        final imageData = image.imageData;
        
        if (imageData == null || imageData.isEmpty) {
          log.warning('ImageService.buildImageByIdSimple: image data empty for imageId=$imageId');
          return errorWidget ?? SizedBox(
            width: width,
            height: height,
            child: const ColoredBox(color: Color(0xFFE0E0E0)),
          );
        }
        
        // Add extra validation to ensure we can create a valid Uint8List
        try {
          final bytes = Uint8List.fromList(imageData);
          
          // Log the image size for debugging
          log.info('ImageService.buildImageByIdSimple: Processing imageId=$imageId with size=${bytes.length} bytes');
          
          // Additional validation: check if the image data looks like valid image data
          // by checking for common image headers
          if (bytes.length >= 2) {
            // JPEG signature check
            if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
              // Valid JPEG header
              log.info('ImageService.buildImageByIdSimple: Valid JPEG image for imageId=$imageId');
            }
            // PNG signature check
            else if (bytes.length >= 8 &&
                bytes[0] == 0x89 &&
                bytes[1] == 0x50 &&
                bytes[2] == 0x4E &&
                bytes[3] == 0x47 &&
                bytes[4] == 0x0D &&
                bytes[5] == 0x0A &&
                bytes[6] == 0x1A &&
                bytes[7] == 0x0A) {
              // Valid PNG header
              log.info('ImageService.buildImageByIdSimple: Valid PNG image for imageId=$imageId');
            }
            // GIF signature check
            else if (bytes.length >= 6 &&
                (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) &&
                (bytes[3] == 0x87 || bytes[3] == 0x89)) {
              // Valid GIF header
              log.info('ImageService.buildImageByIdSimple: Valid GIF image for imageId=$imageId');
            }
            // If it's not a valid image format, treat as invalid data
            else if (bytes.length < 60) {
              // If it's very small, it's likely invalid placeholder data
              log.warning('ImageService.buildImageByIdSimple: image data looks invalid (small size) for imageId=$imageId');
              return errorWidget ?? SizedBox(
                width: width,
                height: height,
                child: const ColoredBox(color: Color(0xFFE0E0E0)),
              );
            }
          }
          
          // Additional safety check: if we have a very small image but it doesn't match
          // any known image format, return error widget
          // However, if it's a valid image format (PNG, JPEG, GIF), we should try to display it
          // Valid minimal PNG files can be as small as ~67 bytes
          if (bytes.length < 60 && bytes.length > 0) {
            log.warning('ImageService.buildImageByIdSimple: image data too small to be valid for imageId=$imageId (size: ${bytes.length})');
            return errorWidget ?? SizedBox(
              width: width,
              height: height,
              child: const ColoredBox(color: Color(0xFFE0E0E0)),
            );
          }
          
          // If we have valid data, try to create the image
          return Image.memory(
            bytes,
            width: width,
            height: height,
            fit: fit ?? BoxFit.cover,
            errorBuilder: (context, error, stack) {
              log.warning('ImageService.buildImageByIdSimple: codec error for imageId=$imageId error=$error');
              return errorWidget ?? SizedBox(
                width: width,
                height: height,
                child: const ColoredBox(color: Color(0xFFE0E0E0)),
              );
            },
          );
        } on Exception catch (e) {
          log.warning('ImageService.buildImageByIdSimple: failed to create image bytes for imageId=$imageId error=$e');
          return errorWidget ?? SizedBox(
            width: width,
            height: height,
            child: const ColoredBox(color: Color(0xFFE0E0E0)),
          );
        }
      },
    );
  }

  /// UI helper: build an Image widget for a backend image ID.
  /// Uses full image data only, with simple error handling.
  Widget buildImageById(
    int imageId, {
    double? width,
    double? height,
    BoxFit? fit,
    Widget? errorWidget,
  }) {
    // Delegate to the simplified version
    return buildImageByIdSimple(
      imageId,
      width: width,
      height: height,
      fit: fit,
      errorWidget: errorWidget,
    );
  }

  /// Upload a single image. Creates an Image using JSON payload (backend ImageRequest).
  Future<model.Image> uploadImage({
    int? propertyId,
    int? maintenanceIssueId,
    required Uint8List imageBytes,
    String fileName = 'image',
    String contentType = 'image/jpeg',
    bool isCover = false,
    int? width,
    int? height,
  }) async {
    final body = {
      'propertyId': propertyId,
      'maintenanceIssueId': maintenanceIssueId,
      'fileName': fileName,
      'contentType': contentType,
      'imageData': base64Encode(imageBytes),
      'isCover': isCover,
      'width': width,
      'height': height,
    }..removeWhere((key, value) => value == null);

    final resp = await api.post('/Images', body);
    final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
    return model.Image.fromJson(decoded);
  }

  /// Convenience: upload multiple raw byte images for a specific property.
  /// Matches simple UI calls using positional args: uploadImagesForProperty(propertyId, images)
  Future<List<model.Image>> uploadImagesForProperty(
    int propertyId,
    List<Uint8List> images, {
    String contentType = 'image/jpeg',
    bool markFirstAsCover = true,
  }) async {
    final list = <_ImageUpload>[];
    for (var i = 0; i < images.length; i++) {
      list.add(_ImageUpload(
        propertyId: propertyId,
        imageBytes: images[i],
        fileName: 'image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
        contentType: contentType,
        isCover: markFirstAsCover && i == 0,
      ));
    }
    return uploadImages(list);
  }

  /// Upload multiple images in one request.
  Future<List<model.Image>> uploadImages(List<_ImageUpload> images) async {
    final payload = images.map((i) => i.toJson()).toList();
    final resp = await api.postJson('/Images/bulk', payload);
    final decoded = jsonDecode(resp.body) as List<dynamic>;
    return decoded.map((e) => model.Image.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// Delete an image by ID
  Future<bool> deleteImage(int imageId) async {
    try {
      final resp = await api.delete('/Images/$imageId');
      return resp.statusCode == 204 || resp.statusCode == 200;
    } catch (e) {
      log.warning('ImageService.deleteImage: failed to delete imageId=$imageId error=$e');
      return false;
    }
  }

  /// UI helper: build an Image widget from a URL or asset path using ApiService.
  /// Allows UI to depend on ImageService even for generic paths.
  Widget buildImage(
    String pathOrUrl, {
    double? width,
    double? height,
    BoxFit? fit,
    Widget? errorWidget,
  }) {
    // If path points to Images API, use JSON->bytes flow instead of ApiService.buildImage
    if (pathOrUrl.startsWith('/Images/')) {
      final idStr = pathOrUrl.replaceFirst('/Images/', '');
      final id = int.tryParse(idStr);
      if (id != null) {
        return buildImageById(
          id,
          width: width,
          height: height,
          fit: fit,
          errorWidget: errorWidget,
        );
      }
    }
    return api.buildImage(
      pathOrUrl,
      width: width,
      height: height,
      fit: fit,
      errorWidget: errorWidget,
    );
  }
}

/// Simple helper for bulk uploads
class _ImageUpload {
  final int? propertyId;
  final int? maintenanceIssueId;
  final Uint8List imageBytes;
  final String fileName;
  final String contentType;
  final bool isCover;
  final int? width;
  final int? height;

  _ImageUpload({
    this.propertyId,
    this.maintenanceIssueId,
    required this.imageBytes,
    this.fileName = 'image',
    this.contentType = 'image/jpeg',
    this.isCover = false,
    this.width,
    this.height,
  });

  Map<String, dynamic> toJson() => {
        'propertyId': propertyId,
        'maintenanceIssueId': maintenanceIssueId,
        'fileName': fileName,
        'contentType': contentType,
        'imageData': base64Encode(imageBytes),
        'isCover': isCover,
        'width': width,
        'height': height,
      }..removeWhere((key, value) => value == null);
}
