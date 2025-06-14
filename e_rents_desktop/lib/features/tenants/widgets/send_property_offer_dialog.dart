import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/tenant_preference.dart';
import 'package:e_rents_desktop/repositories/property_repository.dart';
import 'package:e_rents_desktop/features/tenants/providers/tenant_collection_provider.dart';
import 'package:e_rents_desktop/features/chat/providers/chat_collection_provider.dart';
import 'package:e_rents_desktop/base/service_locator.dart';
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
  List<Property> _availableProperties = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAvailableProperties();
  }

  Future<void> _loadAvailableProperties() async {
    try {
      final propertyRepository = getService<PropertyRepository>();
      final properties = await propertyRepository.getAvailableProperties();
      setState(() {
        _availableProperties = properties;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenantProvider = Provider.of<TenantCollectionProvider>(
      context,
      listen: false,
    );
    final chatProvider = Provider.of<ChatCollectionProvider>(
      context,
      listen: false,
    );

    return AlertDialog(
      title: Text(
        'Send Property Offer to Tenant ${widget.tenantPreference.userId}',
      ), // Placeholder for tenant name
      content: SizedBox(
        width: double.maxFinite,
        height: 300, // Adjust as needed
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text('Error: $_error'))
                : _availableProperties.isEmpty
                ? const Center(child: Text('No available properties to offer.'))
                : ListView.builder(
                  itemCount: _availableProperties.length,
                  itemBuilder: (context, index) {
                    final property = _availableProperties[index];
                    return ListTile(
                      leading:
                          property.imageIds.isNotEmpty
                              ? getService<ApiService>().buildImage(
                                '/Image/${property.imageIds.first}',
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
                        child: const Text('Send Offer'),
                        onPressed: () async {
                          // Step 1: Record the offer (optional, if you need to track it outside of chat)
                          await tenantProvider.recordPropertyOffer(
                            widget.tenantPreference.userId,
                            property.propertyId,
                          );

                          // Step 2: Send the actual message via ChatCollectionProvider
                          await chatProvider.sendPropertyOfferMessage(
                            widget.tenantPreference.userId,
                            property.propertyId,
                          );

                          if (!mounted) return;
                          context.pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Property offer sent for ${property.name}',
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
