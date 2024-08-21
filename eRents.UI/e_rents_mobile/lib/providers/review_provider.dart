import 'package:flutter/material.dart';
import '../models/review.dart';
import '../services/review_service.dart';
import 'base_provider.dart';

class ReviewProvider extends BaseProvider {
  final ReviewService _reviewService;

  ReviewProvider({required ReviewService reviewService})
      : _reviewService = reviewService;

  Future<Review?> getReviewById(int id) async {
    setState(ViewState.Busy);
    try {
      final review = await _reviewService.getReviewById(id);
      setState(ViewState.Idle);
      return review;
    } catch (e) {
      setError(e.toString());
      setState(ViewState.Idle);
      return null;
    }
  }

  Future<List<Review>> getReviews({dynamic search}) async {
    setState(ViewState.Busy);
    try {
      final reviews = await _reviewService.getReviews(search: search);
      setState(ViewState.Idle);
      return reviews;
    } catch (e) {
      setError(e.toString());
      setState(ViewState.Idle);
      return [];
    }
  }

  Future<Review?> createReview(Review review) async {
    setState(ViewState.Busy);
    try {
      final createdReview = await _reviewService.createReview(review);
      setState(ViewState.Idle);
      return createdReview;
    } catch (e) {
      setError(e.toString());
      setState(ViewState.Idle);
      return null;
    }
  }

  Future<Review?> updateReview(int id, Review review) async {
    setState(ViewState.Busy);
    try {
      final updatedReview = await _reviewService.updateReview(id, review);
      setState(ViewState.Idle);
      return updatedReview;
    } catch (e) {
      setError(e.toString());
      setState(ViewState.Idle);
      return null;
    }
  }

  Future<bool> deleteReview(int id) async {
    setState(ViewState.Busy);
    try {
      final success = await _reviewService.deleteReview(id);
      setState(ViewState.Idle);
      return success;
    } catch (e) {
      setError(e.toString());
      setState(ViewState.Idle);
      return false;
    }
  }
}
