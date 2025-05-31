import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/features/tenants/providers/tenant_provider.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class TenantProfileWidget extends StatefulWidget {
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
  State<TenantProfileWidget> createState() => _TenantProfileWidgetState();
}

class _TenantProfileWidgetState extends State<TenantProfileWidget> {
  @override
  void initState() {
    super.initState();
    // Load tenant feedbacks after the widget is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<TenantProvider>(context, listen: false);
      provider.loadTenantFeedbacks(widget.tenant.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage:
                (widget.tenant.profileImage != null &&
                        widget.tenant.profileImage!.url != null &&
                        widget.tenant.profileImage!.url!.isNotEmpty)
                    ? NetworkImage(widget.tenant.profileImage!.url!)
                    : const AssetImage('assets/images/user-image.png'),
            child:
                widget.tenant.profileImage == null
                    ? Text(
                      '${widget.tenant.firstName[0]}${widget.tenant.lastName[0]}',
                    )
                    : null,
          ),
          const SizedBox(width: 12),
          Text(widget.tenant.fullName),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildProfileSection(),
            if (widget.properties != null && widget.properties!.isNotEmpty)
              _buildPropertiesSection(),
            _buildFeedbackSection(),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => context.pop(), child: const Text('Close')),
        TextButton(
          onPressed: widget.onSendMessage,
          child: const Text('Send Message'),
        ),
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
        Text('Email: ${widget.tenant.email}'),
        if (widget.tenant.phone != null) Text('Phone: ${widget.tenant.phone}'),
        if (widget.tenant.addressDetail?.geoRegion?.city != null)
          Text('City: ${widget.tenant.addressDetail?.geoRegion?.city}'),
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
        ...widget.properties!.map(
          (property) => ListTile(
            title: Text(property.title),
            subtitle: Text(property.addressDetail?.streetLine1 ?? ''),
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
        final feedbacks = provider.getTenantFeedbacks(widget.tenant.id);
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
                          index < feedback.starRating!.toInt()
                              ? Colors.amber
                              : Colors.grey[300],
                    ),
                  ),
                ),
                subtitle: Text(feedback.description),
                trailing: Text(
                  '${feedback.dateCreated.year}',
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
