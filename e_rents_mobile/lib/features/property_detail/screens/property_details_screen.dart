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
import 'package:e_rents_mobile/core/widgets/property_card.dart';

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
  
  // Guard flags to prevent infinite rebuild loops
  bool _hasInitializedData = false;
  int? _lastFetchedOwnerId;
  Set<int>? _lastFetchedAmenityIds;
  
  // Booking context - determined from navigation or fetched booking
  ViewContext _effectiveViewContext = ViewContext.browsing;
  Booking? _navigationBooking;

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

  /// Helper to compare two sets for equality
  bool _setEquals<T>(Set<T> a, Set<T> b) {
    if (a.length != b.length) return false;
    for (final item in a) {
      if (!b.contains(item)) return false;
    }
    return true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only initialize data once to prevent infinite loops
    if (!_hasInitializedData) {
      _hasInitializedData = true;
      final provider = context.read<PropertyRentalProvider>();
      final userProvider = context.read<UserProfileProvider>();
      final currentUserId = userProvider.currentUser?.userId;
      
      // Initialize effective view context from widget
      _effectiveViewContext = widget.viewContext;
      
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        provider.fetchPropertyDetails(widget.propertyId);
        provider.fetchReviews(widget.propertyId);
        // Always fetch current user's bookings for this property to enable UI gating (e.g., reviews eligibility)
        provider.fetchBookings(widget.propertyId);
        // Fetch ML-based similar properties recommendations
        provider.fetchSimilarProperties(widget.propertyId);
        
        // If a bookingId was passed, fetch the booking and determine view context
        if (widget.bookingId != null) {
          final booking = await provider.getBookingDetails(widget.bookingId!);
          if (booking != null && mounted) {
            setState(() {
              _navigationBooking = booking;
              _effectiveViewContext = PropertyViewContextHelper.determineContext(booking);
            });
            provider.selectBooking(booking);
            // Fetch extension requests for subscription bookings
            if (booking.isSubscription) {
              provider.fetchExtensionRequests(booking.bookingId);
            }
            debugPrint('PropertyDetailsScreen: Loaded booking ${booking.bookingId}, context: $_effectiveViewContext');
          }
        } else if (currentUserId != null && widget.viewContext == ViewContext.browsing) {
          // Check active booking once during initialization (only when not navigating with booking)
          provider.checkUserActiveBooking(widget.propertyId, currentUserId);
        }
      });
    }
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
          body: Column(
            children: [
              Expanded(
                child: Consumer<PropertyRentalProvider>(
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

              // Ensure owner details are fetched once (guarded to prevent infinite loops)
              if (_lastFetchedOwnerId != property.ownerId) {
                _lastFetchedOwnerId = property.ownerId;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    context.read<PropertyRentalProvider>().fetchOwner(property.ownerId);
                  }
                });
              }

              // Ensure amenities are fetched for THIS property (guarded to prevent infinite loops)
              if (property.amenityIds.isNotEmpty) {
                final requiredIds = property.amenityIds.where((e) => e > 0).toSet();
                if (_lastFetchedAmenityIds == null || !_setEquals(_lastFetchedAmenityIds!, requiredIds)) {
                  _lastFetchedAmenityIds = requiredIds;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      context.read<PropertyRentalProvider>().fetchAmenitiesByIds(property.amenityIds);
                    }
                  });
                }
              }

              final api = context.read<ApiService>();

              final uiReviews = provider.reviews;

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(property, provider, uiReviews),
                  _buildDetailsTab(property, provider, api),
                  _buildReviewsTab(property, provider, uiReviews, isOwner),
                ],
              );
            },
                ),
              ),
            ],
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
                // Don't show booking button if:
                // 1. User is the owner of this property
                // 2. User is already residing in this property (has active booking)
                if (isOwner || provider.hasActiveBookingForProperty) {
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
    // Use navigation booking if available, otherwise find from provider
    final effectiveBooking = _navigationBooking ?? _findBookingForProperty(provider, property.propertyId);
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image slider scrolls with content
          PropertyImageSlider(
            property: property,
            onPageChanged: (index) {},
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Show booking info banner when navigating from Booking History
                if (_navigationBooking != null) ...[
                  _buildBookingInfoBanner(_navigationBooking!),
                  const SizedBox(height: 16),
                ],
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
                // Use effective view context and booking for action section
                PropertyActionFactory.createActionSection(
                  property: property,
                  viewContext: _effectiveViewContext,
                  booking: effectiveBooking,
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFFE0E0E0)),
                const SizedBox(height: 16),
                // Similar properties section (ML-based recommendations)
                _buildSimilarPropertiesSection(provider),
                const SizedBox(height: 80), // Padding for bottom nav
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab(dynamic property, PropertyRentalProvider provider, ApiService api) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PropertyImageSlider(
            property: property,
            onPageChanged: (index) {},
          ),
          Padding(
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
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab(dynamic property, PropertyRentalProvider provider, List<Review> reviews, bool isOwner) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PropertyImageSlider(
            property: property,
            onPageChanged: (index) {},
          ),
          Padding(
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
          ),
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

  Widget _buildBookingInfoBanner(Booking booking) {
    final statusColor = _getStatusColor(booking.status);
    final statusLabel = _getStatusLabel(booking.status);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bookmark, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Your Booking',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildBookingDateInfo(
                  'Check-in',
                  booking.startDate,
                  Icons.login,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildBookingDateInfo(
                  'Check-out',
                  booking.endDate ?? booking.startDate.add(const Duration(days: 30)),
                  Icons.logout,
                ),
              ),
            ],
          ),
          if (booking.endDate != null) ...[
            const SizedBox(height: 8),
            Text(
              '${booking.endDate!.difference(booking.startDate).inDays} nights',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
          // Show pending extension request status for subscription bookings
          if (booking.isSubscription) ...[
            const SizedBox(height: 12),
            _buildExtensionRequestStatus(context),
          ],
        ],
      ),
    );
  }

  Widget _buildExtensionRequestStatus(BuildContext context) {
    return Consumer<PropertyRentalProvider>(
      builder: (context, provider, _) {
        final extensionRequests = provider.extensionRequests;
        
        // If still loading, show nothing
        if (provider.isFetchingExtensions) {
          return const SizedBox.shrink();
        }
        
        // If no extension requests at all, show nothing
        if (extensionRequests.isEmpty) {
          return const SizedBox.shrink();
        }
        
        // Show the most recent request status
        final latestRequest = extensionRequests.first;
        
        Color statusColor;
        IconData statusIcon;
        String statusText;
        
        if (latestRequest.isPending) {
          statusColor = Colors.orange;
          statusIcon = Icons.hourglass_top;
          statusText = 'Extension request pending approval';
        } else if (latestRequest.isApproved) {
          statusColor = Colors.green;
          statusIcon = Icons.check_circle;
          statusText = 'Extension approved';
        } else {
          statusColor = Colors.red;
          statusIcon = Icons.cancel;
          statusText = 'Extension request declined';
        }
        
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (latestRequest.extendByMonths != null)
                      Text(
                        'Requested: ${latestRequest.extendByMonths} month(s) extension',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    if (latestRequest.isRejected && latestRequest.reason != null)
                      Text(
                        'Reason: ${latestRequest.reason}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBookingDateInfo(String label, DateTime date, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              '${date.day}/${date.month}/${date.year}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.upcoming:
        return Colors.blue;
      case BookingStatus.active:
        return Colors.green;
      case BookingStatus.completed:
        return Colors.grey;
      case BookingStatus.cancelled:
        return Colors.red;
      case BookingStatus.pending:
        return Colors.amber;
    }
  }

  String _getStatusLabel(BookingStatus status) {
    switch (status) {
      case BookingStatus.upcoming:
        return 'Upcoming';
      case BookingStatus.active:
        return 'Active';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.pending:
        return 'Pending Approval';
    }
  }

  void checkoutPressed(PropertyRentalProvider provider) {
    final property = provider.property;
    if (property == null) return;

    // Read dates from provider (set by BookingAvailabilityWidget)
    final startDate = provider.startDate;
    final endDate = provider.endDate;

    // Build payload with the selected dates
    final payload = buildCheckoutPayload(
      property,
      startDate: startDate,
      endDate: endDate,
    );

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

  /// Build the similar properties section using ML-based recommendations
  Widget _buildSimilarPropertiesSection(PropertyRentalProvider provider) {
    // Don't show section if loading or empty
    if (provider.isFetchingSimilar) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Similar Properties',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (provider.similarProperties.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Similar Properties',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Based on your preferences',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: provider.similarProperties.length,
            itemBuilder: (context, index) {
              final card = provider.similarProperties[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < provider.similarProperties.length - 1 ? 12 : 0,
                ),
                child: SizedBox(
                  width: 180,
                  child: PropertyCard(
                    layout: PropertyCardLayout.vertical,
                    property: card,
                    onTap: () {
                      context.push('/property/${card.propertyId}');
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
