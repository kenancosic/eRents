import 'package:e_rents_desktop/features/properties/providers/properties_provider.dart';
import 'package:e_rents_desktop/features/properties/widgets/property_images_grid.dart';
import 'package:e_rents_desktop/features/properties/widgets/property_info_display.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/widgets/common/section_header.dart';
import 'package:e_rents_desktop/widgets/loading_or_error_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class PropertyDetailsScreen extends StatefulWidget {
  final String propertyId;

  const PropertyDetailsScreen({super.key, required this.propertyId});

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // Initial data load is handled by the router.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData(initialLoad: true);
    });
  }

  Future<void> _refreshData({bool initialLoad = false}) async {
    final propertiesProvider = context.read<PropertiesProvider>();

    // The router handles the initial load for property details.
    // We only need to force a refresh on user action.
    if (!initialLoad) {
      await propertiesProvider.getPropertyById(
        widget.propertyId,
        forceRefresh: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PropertiesProvider>(
      builder: (context, propertiesProvider, child) {
        final property = propertiesProvider.selectedProperty;
        final isInitialLoading = propertiesProvider.isLoading && property == null;
        final isRefreshing = propertiesProvider.isLoading && property != null;

        return Scaffold(
          appBar: AppBar(
            title: Text(property?.name ?? 'Property Details'),
            actions: [
              if (property != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () =>
                      context.push('/properties/${property.propertyId}/edit'),
                ),
              IconButton(
                icon: isRefreshing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                onPressed: isRefreshing ? null : () => _refreshData(),
              ),
            ],
          ),
          body: LoadingOrErrorWidget(
            isLoading: isInitialLoading,
            error: propertiesProvider.error,
            onRetry: () => _refreshData(),
            child: property == null
                ? const Center(child: Text('Property not found.'))
                : Stack(
                    children: [
                      _buildContent(context, property, propertiesProvider),
                      if (isRefreshing)
                        Container(
                          color: Colors.black.withAlpha(26),
                          child: const Center(
                            child: Card(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Text('Refreshing...'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    Property property,
    PropertiesProvider propertiesProvider,
  ) {
    return RefreshIndicator(
      onRefresh: () => _refreshData(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PropertyImagesGrid(images: property.imageIds),
            const SizedBox(height: 16),
            PropertyInfoDisplay(property: property, showStatus: true),
          ],
        ),
      ),
    );
  }
}
