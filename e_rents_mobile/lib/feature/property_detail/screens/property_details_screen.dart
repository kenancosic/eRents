import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/core/models/review.dart';
import 'package:e_rents_mobile/core/services/service_locator.dart';
import 'package:e_rents_mobile/feature/property_detail/property_details_provider.dart';
import 'package:e_rents_mobile/feature/property_detail/utils/view_context.dart';
import 'package:e_rents_mobile/feature/property_detail/widgets/facilities.dart';
import 'package:e_rents_mobile/feature/property_detail/widgets/property_action_sections/property_action_factory.dart';
import 'package:e_rents_mobile/feature/property_detail/widgets/property_description.dart';
import 'package:e_rents_mobile/feature/property_detail/widgets/property_detail.dart';
import 'package:e_rents_mobile/feature/property_detail/widgets/property_header.dart';
import 'package:e_rents_mobile/feature/property_detail/widgets/property_image_slider.dart';
import 'package:e_rents_mobile/feature/property_detail/widgets/property_owner.dart';
import 'package:e_rents_mobile/feature/property_detail/widgets/property_price_footer.dart';
import 'package:e_rents_mobile/feature/property_detail/widgets/property_reviews/property_review.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_mobile/core/models/booking_model.dart';
import 'package:e_rents_mobile/feature/profile/providers/booking_collection_provider.dart';
import 'package:e_rents_mobile/core/widgets/custom_app_bar.dart';
import 'package:e_rents_mobile/core/widgets/custom_button.dart';
import 'package:e_rents_mobile/core/widgets/custom_outlined_button.dart';

import 'package:e_rents_mobile/feature/saved/saved_collection_provider.dart';

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
  int _currentImageIndex = 0;
  Booking? _currentBooking;

  @override
  void initState() {
    super.initState();
    print(
        "PropertyDetailsScreen initState: ViewContext: ${widget.viewContext}, BookingID: ${widget.bookingId}");
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.bookingId != null) {
      _currentBooking = context
          .read<BookingCollectionProvider>()
          .findById(widget.bookingId!.toString());
      if (_currentBooking == null) {
        print(
            "Booking with ID ${widget.bookingId} not found during didChangeDependencies.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Booking? displayedBooking = widget.bookingId != null
        ? context
            .watch<BookingCollectionProvider>()
            .findById(widget.bookingId!.toString())
        : null;

    final appBar = CustomAppBar(
      title: "Detail",
      showBackButton: true,
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<PropertyDetailProvider>(
          create: (_) {
            final provider = ServiceLocator.get<PropertyDetailProvider>();
            provider.loadItem(widget.propertyId.toString());
            return provider;
          },
        ),
        ChangeNotifierProvider<SavedCollectionProvider>.value(
          value: context.read<SavedCollectionProvider>(),
        ),
      ],
      child: BaseScreen(
        appBar: appBar,
        body: Scaffold(
          appBar: null,
          body: Consumer<PropertyDetailProvider>(
            builder: (context, propertyProvider, child) {
              if (propertyProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (propertyProvider.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        propertyProvider.errorMessage ??
                            'Failed to load property',
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      CustomButton(
                        label: 'Retry',
                        onPressed: () => propertyProvider.refreshItem(),
                        width: ButtonWidth.content,
                        isLoading: false,
                      ),
                    ],
                  ),
                );
              }

              final property = propertyProvider.property;
              if (property == null) {
                return const Center(child: Text('Property not found'));
              }

              final List<Review> uiReviews = [
                Review(
                  reviewId: 1,
                  reviewType: ReviewType.propertyReview,
                  propertyId: property.propertyId,
                  revieweeId: property.ownerId,
                  reviewerId: 123,
                  description:
                      'Great property! Very clean and comfortable. The location is perfect and the host was very responsive.',
                  starRating: 4.5,
                  dateCreated: DateTime(2023, 10, 15),
                ),
                Review(
                  reviewId: 2,
                  reviewType: ReviewType.propertyReview,
                  propertyId: property.propertyId,
                  revieweeId: property.ownerId,
                  reviewerId: 124,
                  description:
                      'Absolutely loved my stay here. The amenities were top-notch and everything was as described.',
                  starRating: 5.0,
                  dateCreated: DateTime(2023, 9, 28),
                ),
                Review(
                  reviewId: 3,
                  reviewType: ReviewType.propertyReview,
                  propertyId: property.propertyId,
                  revieweeId: property.ownerId,
                  reviewerId: 125,
                  description:
                      'Good value for money. The property is well-maintained and in a nice neighborhood.',
                  starRating: 4.0,
                  dateCreated: DateTime(2023, 8, 12),
                ),
              ];

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PropertyImageSlider(
                      property: property,
                      onPageChanged: (index) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PropertyHeader(property: property),
                          const SizedBox(height: 16),
                          PropertyDetails(
                            averageRating:
                                propertyProvider.averageRating ?? 0.0,
                            numberOfReviews: 12,
                            city: propertyProvider.city ?? 'Unknown City',
                            address: property.address?.streetLine1,
                            rooms:
                                propertyProvider.specificationsDisplay ?? 'N/A',
                            area: (propertyProvider.area ?? 0) > 0
                                ? '${(propertyProvider.area ?? 0).toStringAsFixed(0)} m²'
                                : 'N/A',
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFFE0E0E0), height: 16),
                          const SizedBox(height: 16),
                          PropertyDescriptionSection(
                            description: propertyProvider.description.isNotEmpty
                                ? propertyProvider.description
                                : 'This beautiful property offers modern amenities and a convenient location. Perfect for families or professionals looking for comfort and style. Features include spacious rooms, updated appliances, and a welcoming atmosphere.',
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFFE0E0E0), height: 16),
                          const SizedBox(height: 16),
                          PropertyActionFactory.createActionSection(
                            property: property,
                            viewContext: widget.viewContext,
                            booking: displayedBooking,
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFFE0E0E0), height: 16),
                          const SizedBox(height: 16),
                          const PropertyOwnerSection(),
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
                              _showAddReviewDialog(context, propertyProvider);
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
          bottomNavigationBar: Consumer<PropertyDetailProvider>(
            builder: (context, propertyProvider, child) {
              final property = propertyProvider.property;

              if (widget.viewContext == ViewContext.browsing &&
                  property != null) {
                return PropertyPriceFooter(
                  property: property,
                  onCheckoutPressed: () => checkoutPressed(propertyProvider),
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

  void checkoutPressed(PropertyDetailProvider provider) {
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
      BuildContext context, PropertyDetailProvider provider) {
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
                  provider.addReview(Review(
                    reviewId: DateTime.now().millisecondsSinceEpoch,
                    reviewType: ReviewType.propertyReview,
                    propertyId: provider.property?.propertyId ?? 0,
                    revieweeId: provider.property?.ownerId ?? 0,
                    reviewerId: 123, // Current user ID - would come from auth
                    description: commentController.text,
                    starRating: rating,
                    dateCreated: DateTime.now(),
                  ));
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
