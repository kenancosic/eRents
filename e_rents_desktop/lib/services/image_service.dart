import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:e_rents_desktop/base/app_error.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/widgets.dart';

class ImageService extends ApiService {
  ImageService(super.baseUrl, super.secureStorageService);

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

  /// Upload image for property specifically
  Future<Map<String, dynamic>> uploadPropertyImage({
    required Uint8List imageData,
    required String fileName,
    int? propertyId, // Optional for temporary uploads
    bool? isCover,
  }) async {
    return uploadImage(
      imageData: imageData,
      fileName: fileName,
      propertyId: propertyId,
      isCover: isCover,
    );
  }

  /// Upload image from file path
  Future<Map<String, dynamic>> uploadImageFromFile({
    required String filePath,
    int? propertyId,
    int? reviewId,
    int? maintenanceIssueId,
    bool? isCover,
  }) async {
    final file = File(filePath);
    final imageData = await file.readAsBytes();
    final fileName = file.path.split('/').last;

    return uploadImage(
      imageData: imageData,
      fileName: fileName,
      propertyId: propertyId,
      reviewId: reviewId,
      maintenanceIssueId: maintenanceIssueId,
      isCover: isCover,
    );
  }

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
}
