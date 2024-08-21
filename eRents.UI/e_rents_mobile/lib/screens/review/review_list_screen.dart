import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/base_provider.dart';
import '../../providers/review_provider.dart';
import '../../models/review.dart';
import '../../routes/base_screen.dart';

class ReviewListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Reviews',
      body: Consumer<ReviewProvider>(
        builder: (context, provider, child) {
          if (provider.state == ViewState.Busy) {
            return Center(child: CircularProgressIndicator());
          }

          final reviews = provider.getReviews(); // Fetch reviews here
          
          return ListView.builder(
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              return ListTile(
                title: Text(review.description ?? 'No description'),
                subtitle: Text(review.severity ?? 'No severity'),
                onTap: () {
                  Navigator.pushNamed(context, '/review_details', arguments: review);
                },
              );
            },
          );
        },
      ),
    );
  }
}
