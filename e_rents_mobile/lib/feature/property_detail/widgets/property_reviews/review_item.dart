// lib/feature/property_detail/widgets/property_reviews/review_item.dart
import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/models/review.dart';

class ReviewItem extends StatelessWidget {
  final Review review;

  const ReviewItem({
    super.key,
    required this.review,
  });

  @override
  Widget build(BuildContext context) {
    // Extract available data from Review model
    final rating = review.starRating ?? 0.0;
    final comment = review.description ?? 'No comment provided';
    final date = review.dateCreated != null
        ? '${review.dateCreated.day}/${review.dateCreated.month}/${review.dateCreated.year}'
        : 'Unknown date';
    // Generate a user name from review ID (placeholder)
    final userName = 'User ${review.reviewId}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                child: Text(userName.substring(0, 1)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      date,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Text(
                    rating.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            comment,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
