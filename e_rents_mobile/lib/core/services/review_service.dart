import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:e_rents_mobile/core/models/review.dart';
import 'package:e_rents_mobile/core/services/api_service.dart';

class ReviewService {
  final ApiService _apiService;

  ReviewService(this._apiService);

  /// Get review by ID
  Future<Review?> getReviewById(int reviewId) async {
    try {
      final response = await _apiService.get(
        '/Reviews/$reviewId',
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return Review.fromJson(data);
      } else if (response.statusCode == 404) {
        debugPrint('ReviewService: Review $reviewId not found');
        return null;
      } else {
        debugPrint(
            'ReviewService: Failed to load review: ${response.statusCode} ${response.body}');
        throw Exception('Failed to load review: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ReviewService.getReviewById: $e');
      if (e is Exception) rethrow;
      throw Exception('An error occurred while fetching review: $e');
    }
  }

  /// Get reviews with optional filtering parameters
  Future<List<Review>> getReviews([Map<String, dynamic>? params]) async {
    try {
      String endpoint = '/Reviews';

      // Add query parameters if provided
      if (params != null && params.isNotEmpty) {
        final queryParams = params.entries
            .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
            .join('&');
        endpoint += '?$queryParams';
      }

      final response = await _apiService.get(endpoint, authenticated: true);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Review.fromJson(json)).toList();
      } else {
        debugPrint(
            'ReviewService: Failed to load reviews: ${response.statusCode} ${response.body}');
        throw Exception('Failed to load reviews: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ReviewService.getReviews: $e');
      if (e is Exception) rethrow;
      throw Exception('An error occurred while fetching reviews: $e');
    }
  }

  /// Create a new review
  Future<Review> createReview(Review review) async {
    try {
      final response = await _apiService.post(
        '/Reviews',
        review.toJson(),
        authenticated: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return Review.fromJson(data);
      } else {
        debugPrint(
            'ReviewService: Failed to create review: ${response.statusCode} ${response.body}');
        throw Exception('Failed to create review: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ReviewService.createReview: $e');
      if (e is Exception) rethrow;
      throw Exception('An error occurred while creating review: $e');
    }
  }

  /// Update an existing review
  Future<Review> updateReview(int reviewId, Review review) async {
    try {
      final response = await _apiService.put(
        '/Reviews/$reviewId',
        review.toJson(),
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return Review.fromJson(data);
      } else {
        debugPrint(
            'ReviewService: Failed to update review: ${response.statusCode} ${response.body}');
        throw Exception('Failed to update review: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ReviewService.updateReview: $e');
      if (e is Exception) rethrow;
      throw Exception('An error occurred while updating review: $e');
    }
  }

  /// Delete a review
  Future<bool> deleteReview(int reviewId) async {
    try {
      final response = await _apiService.delete(
        '/Reviews/$reviewId',
        authenticated: true,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        debugPrint(
            'ReviewService: Failed to delete review: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('ReviewService.deleteReview: $e');
      return false;
    }
  }
}
