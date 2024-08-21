import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/review_provider.dart';
import '../../models/review.dart';
import '../../routes/base_screen.dart';

class ReviewDetailsScreen extends StatelessWidget {
  final Review review;

  const ReviewDetailsScreen({Key? key, required this.review}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Review Details',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Description: ${review.description}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text('Severity: ${review.severity}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // Handle updating or deleting review here
              },
              child: Text('Edit Review'),
            ),
          ],
        ),
      ),
    );
  }
}
