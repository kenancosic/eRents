import 'package:e_rents_desktop/features/properties/providers/property_detail_provider.dart';
import 'package:e_rents_desktop/features/properties/providers/property_stats_provider.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData(initialLoad: true);
    });
  }

  Future<void> _refreshData({bool initialLoad = false}) async {
    final detailProvider = context.read<PropertyDetailProvider>();
    final statsProvider = context.read<PropertyStatsProvider>();
    if (initialLoad ||
        detailProvider.property?.propertyId.toString() != widget.propertyId) {
      await detailProvider.loadPropertyById(int.parse(widget.propertyId));
    } else {
      await detailProvider.forceReloadProperty();
    }

    if (initialLoad || !statsProvider.isStatsFor(widget.propertyId)) {
      await statsProvider.loadPropertyStats(widget.propertyId);
    } else {
      await statsProvider.refreshStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PropertyDetailProvider, PropertyStatsProvider>(
      builder: (context, detailProvider, statsProvider, child) {
        final property = detailProvider.property;
        final isInitialLoading = detailProvider.isLoading && property == null;
        final isRefreshing = detailProvider.isLoading && property != null;

        return Scaffold(
          appBar: AppBar(
            title: Text(property?.name ?? 'Property Details'),
            actions: [
              if (property != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed:
                      () => context.push(
                        '/properties/${property.propertyId}/edit',
                      ),
                ),
              IconButton(
                icon:
                    isRefreshing
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.refresh),
                onPressed: isRefreshing ? null : _refreshData,
              ),
            ],
          ),
          body: LoadingOrErrorWidget(
            isLoading: isInitialLoading,
            error: detailProvider.error?.message,
            onRetry: _refreshData,
            child:
                property == null
                    ? const Center(child: Text('Property not found.'))
                    : Stack(
                      children: [
                        _buildContent(context, property, statsProvider),
                        if (isRefreshing)
                          Container(
                            color: Colors.black.withOpacity(0.1),
                            child: const Center(
                              child: Card(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(height: 8),
                                      Text('Refreshing data...'),
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
    PropertyStatsProvider statsProvider,
  ) {
    return RefreshIndicator(
      onRefresh: _refreshData,
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
            if (statsProvider.isLoading)
              const Center(child: CircularProgressIndicator())
            else
              PropertyFinancialSummary(stats: statsProvider.stats),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Current Tenant'),
            const SizedBox(height: 16),
            if (statsProvider.isLoading)
              const Center(child: CircularProgressIndicator())
            else
              TenantInfo(
                property: property,
                currentTenant: statsProvider.currentTenant,
              ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Upcoming Bookings'),
            const SizedBox(height: 16),
            if (statsProvider.isLoading)
              const Center(child: CircularProgressIndicator())
            else
              BookingList(
                title: '',
                bookings: statsProvider.upcomingBookings,
                isEmpty: statsProvider.upcomingBookings.isEmpty,
                emptyMessage: 'No upcoming bookings.',
              ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Recent Reviews'),
            const SizedBox(height: 16),
            ReviewsList(
              reviews: context.watch<PropertyDetailProvider>().reviews,
              isLoading:
                  context.watch<PropertyDetailProvider>().areReviewsLoading,
              error:
                  context.watch<PropertyDetailProvider>().reviewsError?.message,
              onReplySubmitted: (reviewId, replyText) async {
                final provider = context.read<PropertyDetailProvider>();
                final success = await provider.submitReply(reviewId, replyText);

                if (!success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Failed to submit reply. Please try again.',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reply submitted successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              onLoadMore: () {
                context.read<PropertyDetailProvider>().loadMoreReviews();
              },
              hasMoreReviews:
                  context.watch<PropertyDetailProvider>().hasMoreReviews,
              totalCount:
                  context.watch<PropertyDetailProvider>().totalReviewCount,
              canReply:
                  context.watch<PropertyDetailProvider>().canReplyToReviews,
            ),
          ],
        ),
      ),
    );
  }
}
