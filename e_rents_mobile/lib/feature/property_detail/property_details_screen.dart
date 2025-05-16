import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/core/mock/mock_properties.dart';
import 'package:e_rents_mobile/feature/property_detail/models/review_ui_model.dart';
import 'package:e_rents_mobile/feature/property_detail/property_details_provider.dart';
import 'package:e_rents_mobile/feature/property_detail/widgets/facilities.dart';
import 'package:e_rents_mobile/feature/property_detail/widgets/property_availability/property_availability.dart';
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

class PropertyDetailScreen extends StatefulWidget {
  final int propertyId;

  const PropertyDetailScreen({super.key, required this.propertyId});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final mockProperty = MockProperties.getSingleProperty(widget.propertyId);

    return ChangeNotifierProvider<PropertyDetailProvider>(
      create: (_) {
        final provider = PropertyDetailProvider();
        provider.property = mockProperty;
        return provider;
      },
      child: Scaffold(
        body: BaseScreen(
          showAppBar: false,
          body: Consumer<PropertyDetailProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (provider.errorMessage != null) {
                return Center(child: Text(provider.errorMessage!));
              }

              final property = provider.property;
              if (property == null) {
                return const Center(child: Text('Property not found'));
              }

              // Replace this section:
              final List<ReviewUIModel> uiReviews = [
                ReviewUIModel.mock(
                  userName: 'John Doe',
                  userImage: 'assets/images/user-image.png',
                  rating: 4.5,
                  comment:
                      'Great property! Very clean and comfortable. The location is perfect and the host was very responsive.',
                  date: 'Oct 15, 2023',
                ),
                ReviewUIModel.mock(
                  userName: 'Jane Smith',
                  userImage: 'assets/images/user-image.png',
                  rating: 5.0,
                  comment:
                      'Absolutely loved my stay here. The amenities were top-notch and everything was as described.',
                  date: 'Sep 28, 2023',
                ),
                ReviewUIModel.mock(
                  userName: 'Mike Johnson',
                  rating: 4.0,
                  comment:
                      'Good value for money. The property is well-maintained and in a nice neighborhood.',
                  date: 'Aug 12, 2023',
                ),
              ];

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Property Image Slider
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
                          // Property Title and Favorite Button
                          PropertyHeader(property: property),

                          const SizedBox(height: 16),

                          // Rating, Location, Rooms, and Area
                          PropertyDetails(
                            averageRating: property.averageRating,
                            numberOfReviews: 12,
                            city: property.city,
                            address: property.address,
                            rooms: '2 rooms',
                            area: '874 m²',
                          ),

                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFFE0E0E0), height: 16),
                          const SizedBox(height: 16),

                          // Property Description Section
                          PropertyDescriptionSection(
                            description: property.description ??
                                'This beautiful property offers modern amenities and a convenient location. Perfect for families or professionals looking for comfort and style. Features include spacious rooms, updated appliances, and a welcoming atmosphere.',
                          ),

                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFFE0E0E0), height: 16),
                          const SizedBox(height: 16),

                          // Property Availability Section
                          PropertyAvailabilitySection(property: property),

                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFFE0E0E0), height: 16),
                          const SizedBox(height: 16),

                          // Property Owner Section
                          const PropertyOwnerSection(),

                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFFE0E0E0), height: 16),
                          const SizedBox(height: 16),

                          // Facilities Section
                          const FacilitiesSection(),

                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFFE0E0E0), height: 16),
                          const SizedBox(height: 16),

                          // Reviews Section
                          PropertyReviewsSection(
                            reviews: uiReviews,
                            averageRating: calculateAverageRating(uiReviews),
                          ),

                          // Add a "Leave a Review" button
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              _showAddReviewDialog(context, provider);
                            },
                            icon: const Icon(Icons.rate_review),
                            label: const Text('Leave a Review'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7065F0),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        bottomNavigationBar: Consumer<PropertyDetailProvider>(
          builder: (context, provider, child) {
            final property = provider.property;
            if (property == null) return const SizedBox.shrink();

            return PropertyPriceFooter(
              property: property,
              onCheckoutPressed: () => checkoutPressed(provider),
            );
          },
        ),
      ),
    );
  }

  double calculateAverageRating(List<ReviewUIModel> reviews) {
    if (reviews.isEmpty) return 0.0;
    double sum = reviews.fold(0.0, (prev, review) => prev + review.rating);
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
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (commentController.text.isNotEmpty) {
                  provider.addReview(ReviewUIModel(
                    userName: 'Current User',
                    userImage: 'assets/images/user-image.png',
                    rating: rating,
                    comment: commentController.text,
                    date: DateTime.now().toIso8601String(),
                  ));
                  context.pop();
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
