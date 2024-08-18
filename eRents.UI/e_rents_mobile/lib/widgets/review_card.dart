import 'package:flutter/material.dart';

class ReviewCard extends StatelessWidget {
  final String reviewerName;
  final double starRating;
  final String reviewText;
  final String reviewDate;

  const ReviewCard({
    Key? key,
    required this.reviewerName,
    required this.starRating,
    required this.reviewText,
    required this.reviewDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  reviewerName,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Spacer(),
                Text(
                  '$starRating ★',
                  style: TextStyle(color: Colors.orange),
                ),
              ],
            ),
            SizedBox(height: 5),
            Text(
              reviewText,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 5),
            Text(
              reviewDate,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
