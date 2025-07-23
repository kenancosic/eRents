import 'package:e_rents_desktop/features/properties/providers/properties_provider.dart';
import 'package:e_rents_desktop/features/properties/widgets/booking_list.dart';
import 'package:e_rents_desktop/features/properties/widgets/property_financial_summary.dart';
import 'package:e_rents_desktop/features/properties/widgets/property_images_grid.dart';
import 'package:e_rents_desktop/features/properties/widgets/property_info_display.dart';
import 'package:e_rents_desktop/features/properties/widgets/reviews_list.dart';
import 'package:e_rents_desktop/features/properties/widgets/tenant_info.dart';
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
    // We might still want to load stats here if they aren't loaded yet.
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
      await propertiesProvider.loadPropertyStats(
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
            const SizedBox(height: 24),
            const SectionHeader(title: 'Financial Summary'),
            const SizedBox(height: 16),
            if (propertiesProvider.isStatsLoading)
              const Center(child: CircularProgressIndicator())
            else
              PropertyFinancialSummary(stats: propertiesProvider.statsData),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Current Tenant'),
            const SizedBox(height: 16),
            if (propertiesProvider.isStatsLoading)
              const Center(child: CircularProgressIndicator())
            else
              TenantInfo(
                property: property,
                currentTenant: propertiesProvider.currentBookings.isNotEmpty ? propertiesProvider.currentBookings.first : null,
              ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Upcoming Bookings'),
            const SizedBox(height: 16),
            if (propertiesProvider.isStatsLoading)
              const Center(child: CircularProgressIndicator())
            else
              BookingList(
                title: '',
                bookings: propertiesProvider.upcomingBookings,
                isEmpty: propertiesProvider.upcomingBookings.isEmpty,
                emptyMessage: 'No upcoming bookings.',
              ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Recent Reviews'),
            const SizedBox(height: 16),
            ReviewsList(
              reviews: propertiesProvider.reviews,
              isLoading: propertiesProvider.areReviewsLoading,
              error: propertiesProvider.reviewsError,
              onReplySubmitted: (reviewId, replyText) async {
                await propertiesProvider.submitReply(reviewId.toString(), replyText);

                if (propertiesProvider.error != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(propertiesProvider.error ??
                          'Failed to submit reply. Please try again.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reply submitted successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              onLoadMore: () {
                propertiesProvider.loadMoreReviews();
              },
              hasMoreReviews: propertiesProvider.hasMoreReviews,
              totalCount: propertiesProvider.totalReviewCount,
              canReply: propertiesProvider.canReplyToReviews,
            ),
          ],
        ),
      ),
    );
  }
}
