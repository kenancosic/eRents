import 'package:e_rents_desktop/utils/image_utils.dart';
import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/models/property.dart';
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
    // Note: Feedback functionality temporarily disabled during provider migration
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage:
                widget.tenant.profileImageId != null
                    ? NetworkImage('/Image/${widget.tenant.profileImageId}')
                    : const AssetImage('assets/images/user-image.png'),
            child:
                widget.tenant.profileImageId == null
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
    // Temporarily disabled during provider migration
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Previous Landlord Feedback',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text('Feedback functionality temporarily unavailable'),
      ],
    );
  }
}
