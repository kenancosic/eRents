// lib/feature/saved/saved_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/core/widgets/custom_app_bar.dart';
import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/core/mock/mock_properties.dart';
import 'package:e_rents_mobile/core/widgets/property_card.dart';
import 'package:e_rents_mobile/feature/property_detail/property_details_screen.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  late List<Property> _savedProperties;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedProperties();
  }

  @override
  void dispose() {
    // Clean up any resources here
    super.dispose();
  }

  Future<void> _loadSavedProperties() async {
    // In a real app, you would fetch this from a database or API
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));
      // Get mock properties (in a real app, filter for saved ones)
      final allProperties = MockProperties.getAllProperties();

      // Simulate that some properties are saved (every other property)
      final savedProperties =
          allProperties.where((p) => p.propertyId % 2 == 0).toList();

      if (mounted) {
        setState(() {
          _savedProperties = savedProperties;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load saved properties. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  void _removeFromSaved(Property property) {
    // In a real app, you would update this in your database or API
    setState(() {
      _savedProperties.removeWhere((p) => p.propertyId == property.propertyId);
    });

    // Show a snackbar to confirm removal
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${property.name} removed from saved'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            // Add the property back if user taps UNDO
            setState(() {
              _savedProperties.add(property);
              // Re-sort by ID to maintain original order
              _savedProperties
                  .sort((a, b) => a.propertyId.compareTo(b.propertyId));
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appBar = CustomAppBar(
      title: 'Saved Properties',
      showBackButton: false,
      // userLocation: ' ', // Or actual location if available -- Removed
      // actions: [], // No filter button was shown before, so keeping actions empty
    );

    return BaseScreen(
      showAppBar: true,
      appBar: appBar,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSavedProperties,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_savedProperties.isEmpty) {
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
                // You can use your navigation provider or context.go('/explore')
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

    // Use a simple ListView instead of more complex nesting
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Center(
              child: TextButton.icon(
                onPressed: _loadSavedProperties,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh', style: TextStyle(fontSize: 14)),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ),
          ),
          // Convert ListView.builder to direct list of widgets
          ..._savedProperties.map((property) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
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
                    title: property.name,
                    location: '${property.city}, ${property.address}',
                    details: property.description ?? '',
                    price: property.price.toString(),
                    rating: property.averageRating?.toString() ?? '4.8',
                    imageUrl: property.images.first.fileName,
                    review: 73,
                    rooms: 2,
                    area: 874,
                    onTap: () {
                      context.push('/property/${property.propertyId}');
                    },
                  ),
                ),
              )),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
