import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_mobile/providers/property_provider.dart';
import 'package:e_rents_mobile/widgets/loading_indicator.dart';
import 'package:e_rents_mobile/widgets/custom_snack_bar.dart';

class PropertyListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PropertyProvider()..fetchProperties(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Properties')),
        body: Consumer<PropertyProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const LoadingIndicator();  // Reusable loading indicator
            }
            if (provider.error != null) {
              WidgetsBinding.instance?.addPostFrameCallback((_) {
                CustomSnackBar.showErrorSnackBar(provider.error!);  // Reusable error snackbar
              });
              return Center(child: Text(provider.error!));
            }
            return ListView.builder(
              itemCount: provider.items.length,
              itemBuilder: (context, index) {
                final property = provider.items[index];
                return ListTile(
                  title: Text(property.name),
                  subtitle: Text('${property.price} \$'),
                  onTap: () {
                    // Navigate to property details
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
