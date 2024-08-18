import 'dart:convert';
import 'package:e_rents_mobile/models/review.dart';
import 'package:e_rents_mobile/providers/base_provider.dart';

class ReviewProvider extends BaseProvider<Review> {
  ReviewProvider() : super("Reviews");

  @override
  Review fromJson(data) {
    return Review.fromJson(data);
  }

  Future<Review?> getReviewById(int id) async {
    try {
      return await getById(id);
    } catch (e) {
      logError(e, 'getReviewById');
      rethrow;
    }
  }

  Future<List<Review>> getReviews({dynamic search}) async {
    try {
      return await get(search: search);
    } catch (e) {
      logError(e, 'getReviews');
      rethrow;
    }
  }

  Future<Review?> createReview(Review review) async {
    try {
      return await insert(review);
    } catch (e) {
      logError(e, 'createReview');
      rethrow;
    }
  }

  Future<Review?> updateReview(int id, Review review) async {
    try {
      return await update(id, review);
    } catch (e) {
      logError(e, 'updateReview');
      rethrow;
    }
  }

  Future<bool> deleteReview(int id) async {
    try {
      return await delete(id);
    } catch (e) {
      logError(e, 'deleteReview');
      rethrow;
    }
  }
}
