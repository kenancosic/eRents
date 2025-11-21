import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/core/models/review.dart';
import 'package:e_rents_mobile/features/property_detail/providers/property_rental_provider.dart';
import 'package:e_rents_mobile/features/property_detail/providers/property_availability_provider.dart';
import 'package:e_rents_mobile/core/services/api_service.dart';
import 'package:e_rents_mobile/features/property_detail/utils/view_context.dart';
import 'package:e_rents_mobile/features/property_detail/widgets/property_description.dart';
import 'package:e_rents_mobile/features/property_detail/widgets/property_detail.dart';
import 'package:e_rents_mobile/features/property_detail/widgets/property_header.dart';
import 'package:e_rents_mobile/features/property_detail/widgets/property_image_slider.dart';
import 'package:e_rents_mobile/features/property_detail/widgets/property_price_footer.dart';
import 'package:e_rents_mobile/features/property_detail/widgets/property_action_sections/property_action_factory.dart';
import 'package:e_rents_mobile/features/property_detail/widgets/property_owner.dart';
import 'package:e_rents_mobile/features/property_detail/widgets/facilities.dart';
import 'package:e_rents_mobile/features/property_detail/widgets/property_reviews/property_review.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_mobile/core/models/booking_model.dart';

import 'package:e_rents_mobile/core/widgets/custom_app_bar.dart';
import 'package:e_rents_mobile/core/widgets/custom_button.dart';
import 'package:e_rents_mobile/core/widgets/custom_outlined_button.dart';
import 'package:e_rents_mobile/core/enums/booking_enums.dart';

import 'package:e_rents_mobile/features/saved/saved_provider.dart';
import 'package:e_rents_mobile/features/profile/providers/user_profile_provider.dart';
import 'package:e_rents_mobile/features/checkout/checkout_utils.dart';

class PropertyDetailScreen extends StatefulWidget {
  final int propertyId;
  final ViewContext viewContext;
  final int? bookingId;

  const PropertyDetailScreen({
    super.key,
    required this.propertyId,
    this.viewContext = ViewContext.browsing,
    this.bookingId,
  });

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    debugPrint(
        "PropertyDetailsScreen initState: ViewContext: ${widget.viewContext}, BookingID: ${widget.bookingId}");
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<PropertyRentalProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.fetchPropertyDetails(widget.propertyId);
      provider.fetchReviews(widget.propertyId);
      // Always fetch current user's bookings for this property to enable UI gating (e.g., reviews eligibility)
      provider.fetchBookings(widget.propertyId);
    });
  }

  Booking? _findBookingForProperty(PropertyRentalProvider bookingProvider, int propertyId) {
    if (bookingProvider.selectedBooking != null && bookingProvider.selectedBooking!.propertyId == propertyId) {
      return bookingProvider.selectedBooking;
    }
    
    if (bookingProvider.bookings.isNotEmpty) {
      try {
        return bookingProvider.bookings.firstWhere((b) => b.propertyId == propertyId);
      } catch (e) {
        // No booking found for this property
        return null;
      }
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final appBar = CustomAppBar(
      title: "Property Details",
      showBackButton: true,
      bottom: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF7265F0),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFF7265F0),
        tabs: const [
          Tab(icon: Icon(Icons.home_outlined), text: 'Overview'),
          Tab(icon: Icon(Icons.info_outline), text: 'Details'),
          Tab(icon: Icon(Icons.star_outline), text: 'Reviews'),
        ],
      ),
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SavedProvider>.value(
          value: context.read<SavedProvider>(),
        ),
        // Local provider for availability used by BookingAvailabilityWidget
        ChangeNotifierProvider<PropertyDetailAvailabilityProvider>(
          create: (context) => PropertyDetailAvailabilityProvider(
            context.read<ApiService>(),
          ),
        ),
      ],
      child: BaseScreen(
        appBar: appBar,
        body: Scaffold(
          body: Consumer<PropertyRentalProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading && provider.property == null) {
                return const Center(child: CircularProgressIndicator());
              }

              if (provider.hasError && provider.property == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        provider.errorMessage.isNotEmpty
                            ? provider.errorMessage
                            : 'Failed to load property',
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      CustomButton(
                        label: 'Retry',
                        onPressed: () => provider.fetchPropertyDetails(widget.propertyId),
                        width: ButtonWidth.content,
                        isLoading: provider.isLoading,
                      ),
                    ],
                  ),
                );
              }

              final property = provider.property;
              if (property == null) {
                return const Center(child: Text('Property not found'));
              }

              // Determine if current user is the owner (mobile-only UI guard)
              final userProvider = context.read<UserProfileProvider>();
              final currentUserId = userProvider.currentUser?.userId;
              final bool isOwner = currentUserId != null && currentUserId == property.ownerId;

              // Ensure owner details are fetched once property is loaded
              if (provider.owner == null || provider.owner?.userId != property.ownerId) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    context.read<PropertyRentalProvider>().fetchOwner(property.ownerId);
                  }
                });
              }

              // Ensure amenities are fetched for THIS property (not from a previous screen)
              if (property.amenityIds.isNotEmpty) {
                final currentIds = provider.amenities.map((a) => a.amenityId).toSet();
                final requiredIds = property.amenityIds.where((e) => e > 0).toSet();
                final bool needsFetch = currentIds.length != requiredIds.length ||
                    currentIds.difference(requiredIds).isNotEmpty ||
                    requiredIds.difference(currentIds).isNotEmpty;

                if (needsFetch) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      context.read<PropertyRentalProvider>().fetchAmenitiesByIds(property.amenityIds);
                    }
                  });
                }
              }

              final api = context.read<ApiService>();

              final uiReviews = provider.reviews;

              return Column(
                children: [
                  PropertyImageSlider(
                    property: property,
                    onPageChanged: (index) {},
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(property, provider, uiReviews),
                        _buildDetailsTab(property, provider, api),
                        _buildReviewsTab(property, provider, uiReviews, isOwner),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          bottomNavigationBar: Consumer<PropertyRentalProvider>(
            builder: (context, provider, child) {
              if (provider.property == null) return const SizedBox.shrink();
              final property = provider.property!;
              // Recompute owner status for clarity in this scope
              final userProvider = context.read<UserProfileProvider>();
              final currentUserId = userProvider.currentUser?.userId;
              final bool isOwner = currentUserId != null && currentUserId == property.ownerId;
              if (widget.viewContext == ViewContext.browsing) {
                if (isOwner) {
                  return const SizedBox.shrink();
                }
                return PropertyPriceFooter(
                  property: property,
                  onCheckoutPressed: () => checkoutPressed(provider),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  // Tab builder methods
  Widget _buildOverviewTab(dynamic property, PropertyRentalProvider provider, List<Review> reviews) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PropertyHeader(property: property),
          const SizedBox(height: 16),
          PropertyDetails(
            averageRating: calculateAverageRating(reviews),
            numberOfReviews: reviews.length,
            city: property.address?.city ?? 'Unknown City',
            address: property.address?.streetLine1,
            rooms: property.rooms,
            area: (property.area ?? 0) > 0
                ? '${(property.area!).toStringAsFixed(0)} m²'
                : 'N/A',
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFE0E0E0)),
          const SizedBox(height: 16),
          PropertyDescriptionSection(
            description: property.description ??
                'This beautiful property offers modern amenities and a convenient location.',
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFE0E0E0)),
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
              final currentBooking = _findBookingForProperty(provider, property.propertyId);
              return PropertyActionFactory.createActionSection(
                property: property,
                viewContext: widget.viewContext,
                booking: currentBooking,
              );
            },
          ),
          const SizedBox(height: 80), // Padding for bottom nav
        ],
      ),
    );
  }

  Widget _buildDetailsTab(dynamic property, PropertyRentalProvider provider, ApiService api) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PropertyOwnerSection(
            ownerId: property.ownerId,
            propertyId: property.propertyId,
            ownerName: provider.owner?.fullName ?? 'Property Owner',
            ownerEmail: provider.owner?.email,
            profileImageUrl: (provider.owner?.profileImageId != null)
                ? api.makeAbsoluteUrl('/api/Images/${provider.owner!.profileImageId}/content')
                : null,
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFE0E0E0)),
          const SizedBox(height: 16),
          FacilitiesSection(
            amenities: provider.getAmenitiesFor(property.amenityIds),
          ),
          const SizedBox(height: 80), // Padding for bottom nav
        ],
      ),
    );
  }

  Widget _buildReviewsTab(dynamic property, PropertyRentalProvider provider, List<Review> reviews, bool isOwner) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PropertyReviewsSection(
            reviews: reviews,
            averageRating: calculateAverageRating(reviews),
          ),
          const SizedBox(height: 16),
          // Consolidated review eligibility message
          _buildReviewEligibilitySection(property, provider, isOwner),
          if (reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'No reviews yet. Be the first to share your experience after your stay.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 80), // Padding for bottom nav
        ],
      ),
    );
  }

  Widget _buildReviewEligibilitySection(dynamic property, PropertyRentalProvider provider, bool isOwner) {
    final now = DateTime.now();
    final hasEligibleStay = provider.bookings.any((b) =>
        b.propertyId == property.propertyId &&
        (b.status == BookingStatus.completed ||
         (b.endDate != null && b.endDate!.isBefore(now)))
    );

    if (isOwner) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.amber[700], size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'As the owner, you can view reviews but cannot leave your own.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      );
    }

    if (hasEligibleStay) {
      return CustomButton(
        label: 'Leave a Review',
        icon: Icons.rate_review,
        isLoading: false,
        width: ButtonWidth.expanded,
        onPressed: () => _showAddReviewDialog(context, provider),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      child: Text(
        'Complete a stay at this property to leave a review.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.grey[700],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  double calculateAverageRating(List<Review> reviews) {
    if (reviews.isEmpty) return 0.0;
    double sum =
        reviews.fold(0.0, (prev, review) => prev + (review.starRating ?? 0.0));
    final avg = sum / reviews.length;
    // Round to 2 decimal places
    return double.parse(avg.toStringAsFixed(2));
  }

  void checkoutPressed(PropertyRentalProvider provider) {
    final property = provider.property;
    if (property == null) return;

    final payload = buildCheckoutPayload(property);

    context.push('/checkout', extra: payload);
  }

  void _showAddReviewDialog(
      BuildContext context, PropertyRentalProvider provider) {
    double rating = 5.0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Leave a Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Rating'),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating.floor()
                          ? Icons.star
                          : (index < rating
                              ? Icons.star_half
                              : Icons.star_border),
                      color: const Color(0xFFFFD700),
                    ),
                    onPressed: () {
                      setState(() {
                        rating = index + 1.0;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              const Text('Your Comment'),
              TextField(
                controller: commentController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Write your review here...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            CustomOutlinedButton.compact(
              label: 'Cancel',
              isLoading: false,
              onPressed: () => context.pop(),
            ),
            CustomButton.compact(
              label: 'Submit',
              isLoading: false,
              onPressed: () {
                if (commentController.text.isNotEmpty) {
                  provider.addReview(widget.propertyId, commentController.text, rating);
                  context.pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
