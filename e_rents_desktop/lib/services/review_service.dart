import 'dart:convert';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/models/review.dart';

class ReviewService extends ApiService {
  ReviewService(super.baseUrl, super.storageService);

  Future<List<Review>> getPropertyReviews(String propertyId) async {
    final response = await get(
      '/Reviews?PropertyId=$propertyId',
      authenticated: true,
    );
    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => Review.fromJson(json)).toList();
  }

  Future<PropertyReviewStats> getPropertyReviewStats(String propertyId) async {
    final response = await get(
      '/Properties/$propertyId/review-stats',
      authenticated: true,
    );
    final Map<String, dynamic> data = json.decode(response.body);
    return PropertyReviewStats.fromJson(data);
  }

  Future<double> getAverageRating(String propertyId) async {
    final response = await get(
      '/Reviews/$propertyId/average-rating',
      authenticated: true,
    );
    final Map<String, dynamic> data = json.decode(response.body);
    return (data['averageRating'] as num?)?.toDouble() ?? 0.0;
  }
}

class PropertyReviewStats {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution;
  final List<Review> recentReviews;

  PropertyReviewStats({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
    required this.recentReviews,
  });

  factory PropertyReviewStats.fromJson(Map<String, dynamic> json) {
    return PropertyReviewStats(
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['totalReviews'] ?? 0,
      ratingDistribution: Map<int, int>.from(json['ratingDistribution'] ?? {}),
      recentReviews:
          (json['recentReviews'] as List<dynamic>?)
              ?.map((reviewJson) => Review.fromJson(reviewJson))
              .toList() ??
          [],
    );
  }
}
