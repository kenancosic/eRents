// lib/feature/saved/saved_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/core/widgets/custom_app_bar.dart';
import 'package:e_rents_mobile/core/widgets/elevated_text_button.dart';
import 'package:e_rents_mobile/core/widgets/property_card.dart';
import 'package:e_rents_mobile/core/models/property_card_model.dart';
import 'package:e_rents_mobile/features/saved/saved_provider.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  @override
  void initState() {
    super.initState();
    // Load saved properties when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SavedProvider>().loadSavedProperties();
    });
  }

  Future<void> _removeFromSaved(PropertyCardModel property) async {
    try {
      final provider = context.read<SavedProvider>();
      await provider.unsaveProperty(property.propertyId);
      
      if (mounted) {
        // Show a snackbar to confirm removal
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${property.name} removed from saved'),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () async {
                // Add the property back if user taps UNDO
                await provider.saveProperty(property.propertyId);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove ${property.name}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appBar = CustomAppBar(
      title: 'Saved Properties',
      showBackButton: false,
    );

    return BaseScreen(
      showAppBar: true,
      appBar: appBar,
      body: Consumer<SavedProvider>(
        builder: (context, provider, child) => _buildBody(provider),
      ),
    );
  }

  Widget _buildBody(SavedProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (provider.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              provider.errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.refreshSavedProperties(),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (provider.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No saved properties yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Properties you save will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Navigate to explore screen
                context.go('/explore');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7265F0),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Explore Properties'),
            ),
          ],
        ),
      );
    }

    // Use ListView to avoid unbounded height issues
    final items = provider.items;
    return ListView.separated(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: items.length + 2, // header + items + footer spacer
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        if (index == 0) {
          // Header with refresh button
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Center(
              child: ElevatedTextButton.icon(
                text: 'Refresh',
                icon: Icons.refresh,
                isCompact: true,
                onPressed: () => provider.refreshSavedProperties(),
              ),
            ),
          );
        }
        if (index == items.length + 1) {
          // Footer spacer
          return const SizedBox(height: 12);
        }

        final property = items[index - 1];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Dismissible(
            key: Key('saved_property_${property.propertyId}'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: Colors.red,
              child: const Icon(
                Icons.delete,
                color: Colors.white,
              ),
            ),
            onDismissed: (direction) {
              _removeFromSaved(property);
            },
            child: PropertyCard(
              property: property,
              onTap: () {
                context.push('/property/${property.propertyId}');
              },
            ),
          ),
        );
      },
    );
  }
}
