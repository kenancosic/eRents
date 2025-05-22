import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/models/tenant_preference.dart';
import 'package:go_router/go_router.dart';

class TenantPreferenceDetailsWidget extends StatelessWidget {
  final TenantPreference preference;
  final User tenant;
  final VoidCallback onSendOffer;

  const TenantPreferenceDetailsWidget({
    super.key,
    required this.preference,
    required this.tenant,
    required this.onSendOffer,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage:
                (tenant.profileImage != null &&
                        tenant.profileImage!.url.isNotEmpty)
                    ? NetworkImage(tenant.profileImage!.url)
                    : const AssetImage('assets/images/user-image.png'),
            child:
                tenant.profileImage == null
                    ? Text('${tenant.firstName[0]}${tenant.lastName[0]}')
                    : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(tenant.fullName),
                Text(
                  'Housing Requirements',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tenant details
            _buildDetailSection('Tenant Contact', [
              'Email: ${tenant.email}',
              if (tenant.phone != null) 'Phone: ${tenant.phone}',
            ]),

            // Location preferences
            _buildDetailSection('Location Preference', [
              'City: ${preference.city}',
            ]),

            // Housing requirements
            _buildDetailSection('Housing Requirements', [
              'Required Amenities: ${preference.amenities.join(", ")}',
              'Price Range: ${preference.minPrice != null ? "\$${preference.minPrice}" : "Any"} - ${preference.maxPrice != null ? "\$${preference.maxPrice}" : "Any"} per month',
            ]),

            // Timeline
            _buildDetailSection('Timeline', [
              'Move-in Date: ${_formatDate(preference.searchStartDate)}',
              'Lease End: ${preference.searchEndDate != null ? _formatDate(preference.searchEndDate!) : "Open-ended"}',
            ]),

            // Description
            _buildDetailSection('Additional Notes', [preference.description]),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => context.pop(), child: const Text('Close')),
        TextButton(
          onPressed: onSendOffer,
          child: const Text('Send Property Offer'),
        ),
      ],
    );
  }

  // Helper method to build a section in the detail dialog
  Widget _buildDetailSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(item),
          ),
        ),
        const Divider(),
        const SizedBox(height: 8),
      ],
    );
  }

  // Helper method to format dates in a user-friendly way
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
