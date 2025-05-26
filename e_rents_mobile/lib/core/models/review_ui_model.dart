// DEPRECATED: This UI-specific model should be merged with the base Review model
// Use the Review model directly with UI formatting methods instead

/*
import 'package:e_rents_mobile/core/models/review.dart';

class ReviewUIModel {
  final String userName;
  final String? userImage;
  final double rating;
  final String comment;
  final String date;
  final Review? originalReview; // Reference to the original model if needed

  ReviewUIModel({
    required this.userName,
    this.userImage,
    required this.rating,
    required this.comment,
    required this.date,
    this.originalReview,
  });

  // Factory method to create from the core Review model
  factory ReviewUIModel.fromReview(Review review,
      {required String userName, String? userImage}) {
    return ReviewUIModel(
      userName: userName,
      userImage: userImage,
      rating: review.starRating ?? 0.0,
      comment: review.description ?? '',
      date: review.dateReported != null
          ? '${review.dateReported!.day}/${review.dateReported!.month}/${review.dateReported!.year}'
          : 'Unknown date',
      originalReview: review,
    );
  }

  // For mock data or UI testing
  factory ReviewUIModel.mock({
    required String userName,
    String? userImage,
    required double rating,
    required String comment,
    required String date,
  }) {
    return ReviewUIModel(
      userName: userName,
      userImage: userImage,
      rating: rating,
      comment: comment,
      date: date,
    );
  }
}
*/
