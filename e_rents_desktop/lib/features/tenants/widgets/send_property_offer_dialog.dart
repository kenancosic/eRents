import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/tenant_preference.dart';
import 'package:e_rents_desktop/repositories/property_repository.dart';
import 'package:e_rents_desktop/features/chat/providers/chat_collection_provider.dart';
import 'package:e_rents_desktop/base/service_locator.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/features/tenants/state/send_property_offer_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class SendPropertyOfferDialog extends StatelessWidget {
  final TenantPreference tenantPreference;

  const SendPropertyOfferDialog({super.key, required this.tenantPreference});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (_) => SendPropertyOfferState(
            getService<PropertyRepository>(),
            context.read<ChatCollectionProvider>(),
            tenantPreference.userId,
          ),
      child: Consumer<SendPropertyOfferState>(
        builder: (context, state, child) {
          return AlertDialog(
            title: Text(
              'Send Property Offer to Tenant #${tenantPreference.userId}',
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: _buildContent(context, state),
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => context.pop(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, SendPropertyOfferState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(child: Text('Error: ${state.error!.message}'));
    }

    if (state.availableProperties.isEmpty) {
      return const Center(child: Text('No available properties to offer.'));
    }

    return ListView.builder(
      itemCount: state.availableProperties.length,
      itemBuilder: (context, index) {
        final property = state.availableProperties[index];
        return ListTile(
          leading:
              property.imageIds.isNotEmpty
                  ? Image.network(
                    getService<ApiService>().makeAbsoluteUrl(
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
            onPressed:
                state.isSending
                    ? null
                    : () async {
                      final success = await context
                          .read<SendPropertyOfferState>()
                          .sendOffer(property.propertyId);
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
            child:
                state.isSending
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
