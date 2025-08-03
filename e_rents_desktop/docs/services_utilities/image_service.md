# eRents Desktop Application Image Service Documentation

## Overview

This document provides documentation for the image service used in the eRents desktop application. The image service is responsible for handling all image-related operations including URL construction, thumbnail generation, image uploading, and image management. It extends the API service and provides specialized functionality for image handling in the rental management system.

## Service Structure

The image service is located in the `lib/services/image_service.dart` file and provides:

1. Image URL construction and management
2. Thumbnail URL generation
3. Image widget creation
4. Image uploading capabilities
5. Image retrieval and management
6. Error handling with AppError integration

## Core Features

### Image URL Management

Centralized handling of image URLs:

- `getImageUrl()` - Convert relative image URLs to absolute URLs
- `getThumbnailUrl()` - Generate thumbnail URLs for images
- `buildImageWidget()` - Create image widgets with centralized handling

### Image Uploading

Comprehensive image uploading capabilities:

- `uploadImage()` - Upload images for properties, reviews, or maintenance issues
- `uploadPropertyImage()` - Upload images specifically for properties
- `uploadImageFromFile()` - Upload images from file paths

### Image Management

Image retrieval and management operations:

- `getPropertyImages()` - Retrieve images for specific properties
- `deleteImage()` - Delete images by ID
- `setCoverImage()` - Set cover images for properties

## Implementation Details

### Constructor

```dart
class ImageService extends ApiService {
  ImageService(super.baseUrl, super.secureStorageService);
  // ...
}
```

The service extends ApiService to inherit HTTP capabilities and centralized image handling.

### URL Management

```dart
/// Convert relative image URLs to absolute URLs
String getImageUrl(String? relativeUrl) {
  // Delegate to ApiService for centralized URL handling
  return makeAbsoluteUrl(relativeUrl ?? '');
}

/// Get thumbnail URL for an image
String getThumbnailUrl(String? relativeUrl) {
  if (relativeUrl == null || relativeUrl.isEmpty) {
    return '';
  }

  // If the URL is already a thumbnail URL, return as-is
  if (relativeUrl.contains('/thumbnail')) {
    return makeAbsoluteUrl(relativeUrl);
  }

  // If it's an image URL like /Image/123, convert to /Image/123/thumbnail
  if (relativeUrl.startsWith('/Image/')) {
    return makeAbsoluteUrl('$relativeUrl/thumbnail');
  }

  return makeAbsoluteUrl(relativeUrl);
}
```

### Image Widget Creation

```dart
/// Build image widget using ApiService's centralized image handling
Widget buildImageWidget(
  String? imageUrl, {
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
  Widget? errorWidget,
}) {
  return buildImage(
    imageUrl,
    fit: fit,
    width: width,
    height: height,
    errorWidget: errorWidget,
  );
}
```

### Image Uploading

```dart
/// Upload image for property, maintenance issue, or review
/// Returns the uploaded image response with ID
Future<Map<String, dynamic>> uploadImage({
  required Uint8List imageData,
  required String fileName,
  int? propertyId,
  int? reviewId,
  int? maintenanceIssueId,
  bool? isCover,
}) async {
  try {
    final token = await secureStorageService.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    final url = Uri.parse('$baseUrl/Image/upload');
    final request = http.MultipartRequest('POST', url);

    // Add headers
    request.headers['Authorization'] = 'Bearer $token';

    // Add the image file
    request.files.add(
      http.MultipartFile.fromBytes(
        'ImageFile',
        imageData,
        filename: fileName,
      ),
    );

    // Add form fields
    if (propertyId != null) {
      request.fields['PropertyId'] = propertyId.toString();
    }
    if (reviewId != null) {
      request.fields['ReviewId'] = reviewId.toString();
    }
    if (maintenanceIssueId != null) {
      request.fields['MaintenanceIssueId'] = maintenanceIssueId.toString();
    }
    if (isCover != null) {
      request.fields['IsCover'] = isCover.toString();
    }

    final response = await request.send();
    final responseString = await response.stream.bytesToString();

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(responseString);
    } else {
      throw AppError.fromHttpResponse(response.statusCode, responseString);
    }
  } catch (e, stackTrace) {
    throw AppError.fromException(e, stackTrace);
  }
}
```

### Image Management

```dart
/// Get images for a specific property
Future<List<Map<String, dynamic>>> getPropertyImages(int propertyId) async {
  try {
    final response = await get(
      '/Image/property/$propertyId',
      authenticated: true,
    );
    final List<dynamic> data = json.decode(response.body);
    return data.cast<Map<String, dynamic>>();
  } catch (e, stackTrace) {
    throw AppError.fromException(e, stackTrace);
  }
}

/// Delete an image by ID
Future<bool> deleteImage(int imageId) async {
  try {
    final response = await delete('/Image/$imageId', authenticated: true);
    return response.statusCode >= 200 && response.statusCode < 300;
  } catch (e, stackTrace) {
    throw AppError.fromException(e, stackTrace);
  }
}

/// Set cover image for a property
Future<bool> setCoverImage(int propertyId, int imageId) async {
  try {
    final response = await put('/Image/cover', {
      'propertyId': propertyId,
      'imageId': imageId,
    }, authenticated: true);
    return response.statusCode >= 200 && response.statusCode < 300;
  } catch (e, stackTrace) {
    throw AppError.fromException(e, stackTrace);
  }
}
```

## Usage Examples

### Image URL Handling

```dart
final imageService = ImageService('https://api.example.com', secureStorageService);

// Get absolute image URL
final imageUrl = imageService.getImageUrl('/Image/123');

// Get thumbnail URL
final thumbnailUrl = imageService.getThumbnailUrl('/Image/123');

// Build image widget
final imageWidget = imageService.buildImageWidget(
  imageUrl,
  width: 200,
  height: 150,
  fit: BoxFit.cover,
);
```

### Image Uploading

```dart
// Upload image from bytes
final imageData = await File('path/to/image.jpg').readAsBytes();
final uploadResult = await imageService.uploadPropertyImage(
  imageData: imageData,
  fileName: 'property_image.jpg',
  propertyId: 123,
  isCover: true,
);

// Upload image from file path
final uploadResult = await imageService.uploadImageFromFile(
  filePath: 'path/to/image.jpg',
  propertyId: 123,
);
```

### Image Management

```dart
// Get property images
final images = await imageService.getPropertyImages(123);

// Delete image
final deleted = await imageService.deleteImage(456);

// Set cover image
final coverSet = await imageService.setCoverImage(123, 789);
```

## Integration with Providers

The image service integrates with property providers:

```dart
// In PropertyProvider
Future<List<Map<String, dynamic>>?> loadPropertyImages(int propertyId) async {
  return executeWithCache(
    'property_images_$propertyId',
    () => imageService.getPropertyImages(propertyId),
    cacheTtl: const Duration(minutes: 10),
  );
}

Future<Map<String, dynamic>?> uploadPropertyImage({
  required Uint8List imageData,
  required String fileName,
  int? propertyId,
  bool? isCover,
}) async {
  return executeWithState(() async {
    return await imageService.uploadPropertyImage(
      imageData: imageData,
      fileName: fileName,
      propertyId: propertyId,
      isCover: isCover,
    );
  });
}
```

## Integration with Widgets

Widgets use the image service for image display:

```dart
// In PropertyImageWidget
Widget build(BuildContext context) {
  return imageService.buildImageWidget(
    imageService.getImageUrl(imagePath),
    fit: BoxFit.cover,
    width: 200,
    height: 150,
  );
}

// In ThumbnailWidget
Widget build(BuildContext context) {
  return imageService.buildImageWidget(
    imageService.getThumbnailUrl(imagePath),
    fit: BoxFit.cover,
    width: 50,
    height: 50,
  );
}
```

## Error Handling

The image service implements robust error handling:

1. **Authentication Errors**: Token validation for uploads
2. **Network Errors**: HTTP status code handling
3. **Data Validation**: Response validation and parsing
4. **AppError Integration**: Consistent error handling with AppError
5. **Logging**: Comprehensive error logging
6. **Recovery**: Graceful recovery from errors

## Best Practices

1. **URL Handling**: Use centralized URL construction methods
2. **Image Optimization**: Use thumbnails for list views
3. **Error Handling**: Handle upload errors gracefully
4. **Authentication**: Ensure proper token handling for uploads
5. **Memory Management**: Handle large image data efficiently
6. **Validation**: Validate image data before upload
7. **Caching**: Leverage caching for image lists
8. **Loading States**: Show loading indicators during uploads
9. **File Handling**: Proper file reading and error handling
10. **Security**: Validate file types and sizes

## Extensibility

The image service supports easy extension:

1. **New Image Types**: Add support for new image entity types
2. **Custom Processing**: Add image processing capabilities
3. **Storage Options**: Add support for different storage backends
4. **Format Support**: Add support for additional image formats
5. **Compression**: Add image compression options
6. **Resizing**: Add server-side resizing options
7. **Watermarking**: Add image watermarking capabilities
8. **Batch Operations**: Add batch image operations

This image service documentation ensures consistent implementation of image handling and provides a solid foundation for future development.
