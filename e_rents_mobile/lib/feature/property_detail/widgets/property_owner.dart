// lib/feature/property_detail/widgets/property_owner_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_mobile/core/widgets/custom_avatar.dart';
import 'package:e_rents_mobile/core/widgets/custom_button.dart';
import 'package:e_rents_mobile/core/widgets/custom_snack_bar.dart';

class PropertyOwnerSection extends StatelessWidget {
  final int? propertyId; // Add property ID for offers
  final String? ownerName;
  final String? ownerEmail;

  const PropertyOwnerSection({
    super.key,
    this.propertyId,
    this.ownerName,
    this.ownerEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const CustomAvatar(
              imageUrl: 'assets/images/user-image.png',
              size: 40,
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ownerName ?? 'Facility Owner',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    'Property Owner',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _contactPropertyOwner(context),
              icon: SvgPicture.asset('assets/icons/message.svg'),
              tooltip: 'Message Owner',
            ),
          ],
        ),
        if (propertyId != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  label: 'Make Offer',
                  isLoading: false,
                  onPressed: () => _makePropertyOffer(context),
                  icon: Icons.local_offer,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _contactPropertyOwner(BuildContext context) {
    context.push('/chat', extra: {
      'name': ownerName ?? 'Property Owner',
      'imageUrl': 'assets/images/user-image.png',
    });
  }

  void _makePropertyOffer(BuildContext context) {
    if (propertyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar.showErrorSnackBar(
          'Unable to send offer - property information not available',
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _PropertyOfferDialog(
          propertyId: propertyId!,
          ownerName: ownerName ?? 'Property Owner',
        );
      },
    );
  }
}

class _PropertyOfferDialog extends StatefulWidget {
  final int propertyId;
  final String ownerName;

  const _PropertyOfferDialog({
    required this.propertyId,
    required this.ownerName,
  });

  @override
  State<_PropertyOfferDialog> createState() => _PropertyOfferDialogState();
}

class _PropertyOfferDialogState extends State<_PropertyOfferDialog> {
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendOffer() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Replace with actual API call when property offer service is implemented
      // For now, simulate the API call
      await Future.delayed(const Duration(seconds: 1));

      // Show success message
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.showSuccessSnackBar(
            'Property offer sent successfully!',
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.showErrorSnackBar(
            'Failed to send offer. Please try again.',
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Make Offer to ${widget.ownerName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Express your interest in this property with a personal message:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _messageController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText:
                  'Hi! I\'m interested in your property. Could we discuss rental terms?',
              border: OutlineInputBorder(),
              labelText: 'Your message (optional)',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        CustomButton(
          label: _isLoading ? 'Sending...' : 'Send Offer',
          isLoading: _isLoading,
          onPressed: _isLoading ? () {} : () => _sendOffer(),
        ),
      ],
    );
  }
}
