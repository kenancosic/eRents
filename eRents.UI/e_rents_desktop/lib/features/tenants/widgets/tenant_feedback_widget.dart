import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/tenant_feedback.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/features/tenants/providers/tenant_provider.dart';
import 'package:provider/provider.dart';

class TenantFeedbackWidget extends StatelessWidget {
  final User tenant;

  const TenantFeedbackWidget({super.key, required this.tenant});

  @override
  Widget build(BuildContext context) {
    return Consumer<TenantProvider>(
      builder: (context, provider, child) {
        final feedbacks = provider.getTenantFeedbacks(tenant.id);
        if (feedbacks.isEmpty) {
          return const Text('No feedback available');
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Previous Landlord Feedback',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...feedbacks.map((feedback) => _buildFeedbackItem(feedback)),
          ],
        );
      },
    );
  }

  Widget _buildFeedbackItem(TenantFeedback feedback) {
    return ListTile(
      title: Row(
        children: List.generate(
          5,
          (index) => Icon(
            Icons.star,
            size: 18,
            color: index < feedback.rating ? Colors.amber : Colors.grey[300],
          ),
        ),
      ),
      subtitle: Text(feedback.comment),
      trailing: Text(
        '${feedback.stayStartDate.year}-${feedback.stayEndDate.year}',
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
    );
  }
}
