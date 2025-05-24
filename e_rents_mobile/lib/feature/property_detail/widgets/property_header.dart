// lib/feature/property_detail/widgets/property_header.dart
import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/feature/saved/saved_provider.dart';
import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:provider/provider.dart';

class PropertyHeader extends StatelessWidget {
  final Property property;

  const PropertyHeader({
    super.key,
    required this.property,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SavedProvider>(
      builder: (context, savedProvider, child) {
        final isSaved = savedProvider.isPropertySaved(property.propertyId);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                property.name,
                style: Theme.of(context).textTheme.headlineMedium,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              style: IconButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                minimumSize: Size.zero,
              ),
              onPressed: savedProvider.state == ViewState.busy
                  ? null
                  : () async {
                      await savedProvider.toggleSavedStatus(property);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isSaved
                                  ? 'Property removed from saved'
                                  : 'Property saved successfully',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
              icon: savedProvider.state == ViewState.busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      isSaved ? Icons.favorite : Icons.favorite_border,
                      size: 24,
                      color: isSaved ? Colors.red : null,
                    ),
            ),
          ],
        );
      },
    );
  }
}
