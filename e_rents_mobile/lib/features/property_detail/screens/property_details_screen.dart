import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/core/models/review.dart';
import 'package:e_rents_mobile/features/property_detail/providers/property_rental_provider.dart';
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

import 'package:e_rents_mobile/features/saved/saved_provider.dart';

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

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {

  @override
  void initState() {
    super.initState();
    debugPrint(
        "PropertyDetailsScreen initState: ViewContext: ${widget.viewContext}, BookingID: ${widget.bookingId}");
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<PropertyRentalProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.fetchPropertyDetails(widget.propertyId);
      provider.fetchReviews(widget.propertyId);
      if (widget.bookingId != null) {
        provider.fetchBookings(widget.propertyId);
      }
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
      title: "Detail",
      showBackButton: true,
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SavedProvider>.value(
          value: context.read<SavedProvider>(),
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

              final uiReviews = provider.reviews;

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
                          PropertyHeader(property: property),
                          const SizedBox(height: 16),
                          PropertyDetails(
                            averageRating: property.averageRating ?? 0.0,
                            numberOfReviews: uiReviews.length,
                            city: property.address?.city ?? 'Unknown City',
                            address: property.address?.streetLine1,
                            rooms: property.rooms,
                            area: (property.area ?? 0) > 0
                                ? '${(property.area!).toStringAsFixed(0)} m²'
                                : 'N/A',
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFFE0E0E0), height: 16),
                          const SizedBox(height: 16),
                          PropertyDescriptionSection(
                            description: property.description ??
                                'This beautiful property offers modern amenities and a convenient location. Perfect for families or professionals looking for comfort and style. Features include spacious rooms, updated appliances, and a welcoming atmosphere.',
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFFE0E0E0), height: 16),
                          const SizedBox(height: 16),
                          Builder(
                            builder: (context) {
                              final currentBooking = _findBookingForProperty(provider, property.propertyId);
                              return PropertyActionFactory.createActionSection(
                                property: property,
                                viewContext: widget.viewContext,
                                booking: currentBooking,
                              );
                            }
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFFE0E0E0), height: 16),
                          const SizedBox(height: 16),
                          PropertyOwnerSection(
                            propertyId: property.propertyId,
                            ownerName: 'Property Owner',
                            ownerEmail: null,
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFFE0E0E0), height: 16),
                          const SizedBox(height: 16),
                          const FacilitiesSection(),
                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFFE0E0E0), height: 16),
                          const SizedBox(height: 16),
                          PropertyReviewsSection(
                            reviews: uiReviews,
                            averageRating: calculateAverageRating(uiReviews),
                          ),
                          const SizedBox(height: 16),
                          CustomButton(
                            label: 'Leave a Review',
                            icon: Icons.rate_review,
                            isLoading: false,
                            width: ButtonWidth.expanded,
                            onPressed: () {
                              _showAddReviewDialog(context, provider);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          bottomNavigationBar: Consumer<PropertyRentalProvider>(
            builder: (context, provider, child) {
              if (provider.property == null) return const SizedBox.shrink();
              final property = provider.property!;
              if (widget.viewContext == ViewContext.browsing) {
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

  double calculateAverageRating(List<Review> reviews) {
    if (reviews.isEmpty) return 0.0;
    double sum =
        reviews.fold(0.0, (prev, review) => prev + (review.starRating ?? 0.0));
    return sum / reviews.length;
  }

  void checkoutPressed(PropertyRentalProvider provider) {
    final property = provider.property;
    if (property == null) return;

    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day + 1);
    final endDate = DateTime(now.year, now.month, now.day + 6);
    final isDailyRental = true;

    final duration = endDate.difference(startDate).inDays;
    final basePrice = property.price * duration;
    final totalPrice = basePrice * 1.1;

    context.push('/checkout', extra: {
      'property': property,
      'startDate': startDate,
      'endDate': endDate,
      'isDailyRental': isDailyRental,
      'totalPrice': totalPrice,
    });
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
