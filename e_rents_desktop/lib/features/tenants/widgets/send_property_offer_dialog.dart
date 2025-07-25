import 'package:e_rents_desktop/models/tenant_preference.dart';
import 'package:e_rents_desktop/features/tenants/providers/tenants_provider.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class SendPropertyOfferDialog extends StatefulWidget {
  final TenantPreference tenantPreference;

  const SendPropertyOfferDialog({super.key, required this.tenantPreference});

  @override
  State<SendPropertyOfferDialog> createState() =>
      _SendPropertyOfferDialogState();
}

class _SendPropertyOfferDialogState extends State<SendPropertyOfferDialog> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TenantsProvider>(
      builder: (context, provider, child) {
        // Load available properties when dialog opens
        WidgetsBinding.instance.addPostFrameCallback((_) {
          provider.loadAvailableProperties();
        });
        return AlertDialog(
          title: Text(
            'Send Property Offer to ${widget.tenantPreference.userFullName ?? "Tenant"}',
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 450,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom message input
                Text(
                  'Personal message (optional):',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _messageController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText:
                        'Add a personal message to make your offer more appealing...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select a property to offer:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildContent(context, provider),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, TenantsProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.hasError) {
      return Center(child: Text('Error: ${provider.error}'));
    }

    if (provider.availableProperties.isEmpty) {
      return const Center(child: Text('No available properties to offer.'));
    }

    return ListView.builder(
      itemCount: provider.availableProperties.length,
      itemBuilder: (context, index) {
        final property = provider.availableProperties[index];
        return ListTile(
          leading:
              property.imageIds.isNotEmpty
                  ? Image.network(
                      context.read<ApiService>().makeAbsoluteUrl(
                        '/Image/${property.imageIds.first}',
                      ),
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    )
                  : const Icon(Icons.house, size: 40),
          title: Text(property.name),
          subtitle: Text(
            '${property.price.toStringAsFixed(0)} KM/month - ${property.type.name}',
          ),
          trailing: ElevatedButton(
            onPressed: provider.isSendingOffer
                ? null
                : () async {
                    final success = await provider.sendPropertyOffer(
                      widget.tenantPreference.userId.toString(),
                      property.propertyId.toString(),
                      customMessage: _messageController.text.trim(),
                    );
                    if (success && context.mounted) {
                      context.pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Property offer sent for ${property.name}',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
            child: provider.isSendingOffer
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Send Offer'),
          ),
        );
      },
    );
  }
}
