import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/tenant_feedback.dart';
import 'package:e_rents_desktop/features/tenants/providers/tenant_provider.dart';
import 'package:provider/provider.dart';

class TenantProfileWidget extends StatelessWidget {
  final User tenant;
  final List<Property>? properties;
  final VoidCallback onSendMessage;

  const TenantProfileWidget({
    super.key,
    required this.tenant,
    this.properties,
    required this.onSendMessage,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TenantProvider>(context, listen: false);
    provider.loadTenantFeedbacks(tenant.id);

    return AlertDialog(
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage:
                tenant.profileImage != null
                    ? NetworkImage(tenant.profileImage!)
                    : null,
            child:
                tenant.profileImage == null
                    ? Text('${tenant.firstName[0]}${tenant.lastName[0]}')
                    : null,
          ),
          const SizedBox(width: 12),
          Text(tenant.fullName),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildProfileSection(),
            if (properties != null && properties!.isNotEmpty)
              _buildPropertiesSection(),
            _buildFeedbackSection(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        TextButton(onPressed: onSendMessage, child: const Text('Send Message')),
      ],
    );
  }

  Widget _buildProfileSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Profile Information',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text('Email: ${tenant.email}'),
        if (tenant.phone != null) Text('Phone: ${tenant.phone}'),
        if (tenant.city != null) Text('City: ${tenant.city}'),
        const Divider(),
      ],
    );
  }

  Widget _buildPropertiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Current Properties',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...properties!.map(
          (property) => ListTile(
            title: Text(property.title),
            subtitle: Text(property.address),
            trailing: Text('\$${property.price}/month'),
          ),
        ),
        const Divider(),
      ],
    );
  }

  Widget _buildFeedbackSection() {
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
            ...feedbacks.map(
              (feedback) => ListTile(
                title: Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      Icons.star,
                      size: 18,
                      color:
                          index < feedback.rating
                              ? Colors.amber
                              : Colors.grey[300],
                    ),
                  ),
                ),
                subtitle: Text(feedback.comment),
                trailing: Text(
                  '${feedback.stayStartDate.year}-${feedback.stayEndDate.year}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
