import 'package:flutter/material.dart';

class ReviewCard extends StatelessWidget {
  final String reviewerName;
  final double starRating;
  final String reviewText;
  final String reviewDate;

  const ReviewCard({
    super.key,
    required this.reviewerName,
    required this.starRating,
    required this.reviewText,
    required this.reviewDate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  reviewerName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '$starRating ★',
                  style: const TextStyle(color: Colors.orange),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              reviewText,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 5),
            Text(
              reviewDate,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
