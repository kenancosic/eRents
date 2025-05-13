import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/tenant_preference.dart';
import 'package:e_rents_desktop/features/properties/providers/property_provider.dart';
import 'package:e_rents_desktop/features/tenants/providers/tenant_provider.dart';
import 'package:e_rents_desktop/features/chat/providers/chat_provider.dart';
import 'package:e_rents_desktop/features/auth/providers/auth_provider.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Fetch available properties when the dialog is shown
      Provider.of<PropertyProvider>(context, listen: false).fetchItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final propertyProvider = Provider.of<PropertyProvider>(context);
    final tenantProvider = Provider.of<TenantProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.id ?? 'unknown_landlord_id';

    // Filter for available properties
    final availableProperties =
        propertyProvider.items
            .where((property) => property.status == PropertyStatus.available)
            .toList();

    return AlertDialog(
      title: Text(
        'Send Property Offer to Tenant ${widget.tenantPreference.userId}',
      ), // Placeholder for tenant name
      content: SizedBox(
        width: double.maxFinite,
        height: 300, // Adjust as needed
        child:
            propertyProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : availableProperties.isEmpty
                ? const Center(child: Text('No available properties to offer.'))
                : ListView.builder(
                  itemCount: availableProperties.length,
                  itemBuilder: (context, index) {
                    final property = availableProperties[index];
                    return ListTile(
                      leading:
                          property.images.isNotEmpty
                              ? Image.asset(
                                property.images.first,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              )
                              : const Icon(Icons.house, size: 40),
                      title: Text(property.title),
                      subtitle: Text(
                        '${property.price.toStringAsFixed(0)} KM/month - ${property.type.name}',
                      ),
                      trailing: ElevatedButton(
                        child: const Text('Send Offer'),
                        onPressed: () async {
                          // Step 1: Record the offer (optional, if you need to track it outside of chat)
                          await tenantProvider.recordPropertyOffer(
                            widget.tenantPreference.userId,
                            property.id,
                          );

                          // Step 2: Send the actual message via ChatProvider
                          await chatProvider.sendPropertyOfferMessage(
                            widget.tenantPreference.userId,
                            property.id,
                            currentUserId,
                          );

                          if (!mounted) return;
                          context.pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Property offer sent for ${property.title}',
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
      ),
      actions: [
        TextButton(child: const Text('Cancel'), onPressed: () => context.pop()),
      ],
    );
  }
}
