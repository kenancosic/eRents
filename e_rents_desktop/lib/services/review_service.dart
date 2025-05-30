import 'dart:convert';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/models/review.dart';
import 'package:e_rents_desktop/models/booking_summary.dart'; // For PropertyReviewStats

class ReviewService extends ApiService {
  ReviewService(super.baseUrl, super.storageService);

  Future<List<Review>> getPropertyReviews(String propertyId) async {
    try {
      final response = await get(
        '/Reviews?PropertyId=$propertyId',
        authenticated: true,
      );
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) {
        try {
          return Review.fromJson(json);
        } catch (e) {
          print('Error parsing review: $e');
          // Return a default review if parsing fails
          return Review(
            id: 0,
            bookingId: null,
            propertyId: int.tryParse(propertyId) ?? 0,
            starRating: 0.0,
            description: 'Error loading review',
            dateReported: DateTime.now(),
            status: ReviewStatus.pending,
            severity: ReviewSeverity.medium,
          );
        }
      }).toList();
    } catch (e) {
      print('Error loading reviews: $e');
      return [];
    }
  }

  Future<PropertyReviewStats> getPropertyReviewStats(String propertyId) async {
    try {
      final response = await get(
        '/Properties/$propertyId/review-stats',
        authenticated: true,
      );
      final Map<String, dynamic> data = json.decode(response.body);
      return PropertyReviewStats.fromJson(data);
    } catch (e) {
      print('Error loading review stats: $e');
      return PropertyReviewStats(
        averageRating: 0.0,
        totalReviews: 0,
        ratingDistribution: {},
        recentReviews: [],
      );
    }
  }

  Future<double> getAverageRating(String propertyId) async {
    try {
      final response = await get(
        '/Reviews/$propertyId/average-rating',
        authenticated: true,
      );
      final Map<String, dynamic> data = json.decode(response.body);

      // Handle different possible data types for averageRating
      final ratingValue = data['averageRating'];
      if (ratingValue == null) return 0.0;

      if (ratingValue is num) {
        return ratingValue.toDouble();
      } else if (ratingValue is String) {
        return double.tryParse(ratingValue) ?? 0.0;
      }

      return 0.0;
    } catch (e) {
      print('Error loading average rating: $e');
      return 0.0;
    }
  }
}
