import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/core/models/review_ui_model.dart';
import 'package:e_rents_mobile/feature/property_detail/property_details_provider.dart';
import 'package:e_rents_mobile/feature/property_detail/utils/view_context.dart';
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
import 'package:e_rents_mobile/core/models/booking_model.dart';
import 'package:e_rents_mobile/feature/profile/user_bookings_provider.dart';
import 'package:intl/intl.dart';
import 'package:e_rents_mobile/core/widgets/custom_app_bar.dart';
import 'package:e_rents_mobile/core/widgets/custom_button.dart';
import 'package:e_rents_mobile/core/widgets/custom_outlined_button.dart';
import 'package:e_rents_mobile/feature/property_detail/widgets/cancel_stay_dialog.dart';
import 'package:e_rents_mobile/feature/saved/saved_provider.dart';

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
          .read<UserBookingsProvider>()
          .getBookingById(widget.bookingId!);
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
            .watch<UserBookingsProvider>()
            .getBookingById(widget.bookingId!)
        : null;

    final appBar = CustomAppBar(
      title: "Detail",
      showBackButton: true,
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<PropertyDetailProvider>(
          create: (_) {
            final provider = PropertyDetailProvider();
            provider.fetchPropertyDetail(widget.propertyId);
            return provider;
          },
        ),
        ChangeNotifierProvider<SavedProvider>.value(
          value: context.read<SavedProvider>(),
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

              if (propertyProvider.errorMessage != null) {
                return Center(child: Text(propertyProvider.errorMessage!));
              }

              final property = propertyProvider.property;
              if (property == null) {
                return const Center(child: Text('Property not found'));
              }

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
                            averageRating: property.averageRating,
                            numberOfReviews: 12,
                            city: property.addressDetail?.geoRegion?.city,
                            address: property.addressDetail?.streetLine1,
                            rooms: '2 rooms',
                            area: '874 m²',
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
                          if (widget.viewContext == ViewContext.browsing ||
                              widget.viewContext == ViewContext.upcomingBooking)
                            PropertyAvailabilitySection(property: property),
                          if (widget.viewContext == ViewContext.browsing ||
                              widget.viewContext ==
                                  ViewContext.upcomingBooking) ...[
                            const SizedBox(height: 16),
                            const Divider(color: Color(0xFFE0E0E0), height: 16),
                            const SizedBox(height: 16),
                          ],
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
              if (property == null &&
                  widget.viewContext == ViewContext.browsing) {
                return const SizedBox.shrink();
              }

              Booking? bookingToDisplay = displayedBooking;

              if (widget.viewContext == ViewContext.activeLease) {
                if (widget.bookingId == null || bookingToDisplay == null) {
                  return _buildInfoFooter("Active lease details unavailable.");
                }
                String leaseInfo = "You are currently residing here";
                if (bookingToDisplay.endDate == null) {
                  leaseInfo += " (Open-ended lease).";
                  if (bookingToDisplay.minimumStayEndDate != null &&
                      bookingToDisplay.minimumStayEndDate!
                          .isAfter(DateTime.now())) {
                    leaseInfo +=
                        " Minimum stay until ${DateFormat.yMMMd().format(bookingToDisplay.minimumStayEndDate!)}.";
                  }
                } else {
                  leaseInfo +=
                      ". Lease ends ${DateFormat.yMMMd().format(bookingToDisplay.endDate!)}.";
                }
                return _buildActionFooter(
                  context: context,
                  infoText: leaseInfo,
                  actions: [
                    _footerButton(context, "Report Issue", Icons.report_problem,
                        () {
                      context.push(
                          '/property/${widget.propertyId}/report-issue',
                          extra: {
                            'propertyId': widget.propertyId,
                            'bookingId': widget.bookingId,
                          });
                    }),
                    if (bookingToDisplay.endDate == null)
                      _footerButton(context, "Manage Lease", Icons.settings,
                          () {
                        context.push(
                            '/property/${widget.propertyId}/manage-lease',
                            extra: {
                              'propertyId': widget.propertyId,
                              'bookingId': widget.bookingId,
                              'booking': bookingToDisplay,
                            });
                      })
                    else
                      _footerButton(context, "Extend Stay", Icons.add_alarm,
                          () {
                        context.push(
                            '/property/${widget.propertyId}/manage-lease',
                            extra: {
                              'propertyId': widget.propertyId,
                              'bookingId': widget.bookingId,
                              'booking': bookingToDisplay,
                            });
                      }),
                  ],
                );
              } else if (widget.viewContext == ViewContext.upcomingBooking) {
                if (widget.bookingId == null || bookingToDisplay == null) {
                  return _buildInfoFooter(
                      "Upcoming booking details unavailable.");
                }
                String bookingInfo;
                if (bookingToDisplay.endDate == null) {
                  bookingInfo =
                      "Upcoming open-ended stay starting ${DateFormat.yMMMd().format(bookingToDisplay.startDate)}.";
                  if (bookingToDisplay.minimumStayEndDate != null &&
                      bookingToDisplay.minimumStayEndDate!
                          .isAfter(DateTime.now())) {
                    bookingInfo +=
                        " Minimum stay until ${DateFormat.yMMMd().format(bookingToDisplay.minimumStayEndDate!)}.";
                  }
                } else {
                  bookingInfo =
                      "Upcoming stay: ${DateFormat.yMMMd().format(bookingToDisplay.startDate)} - ${DateFormat.yMMMd().format(bookingToDisplay.endDate!)}.";
                }
                return _buildActionFooter(
                  context: context,
                  infoText: bookingInfo,
                  actions: [
                    _footerButton(
                        context, "Manage Booking", Icons.event_available, () {
                      context.push(
                          '/property/${widget.propertyId}/manage-booking',
                          extra: {
                            'propertyId': widget.propertyId,
                            'bookingId': widget.bookingId,
                            'booking': bookingToDisplay,
                          });
                    }),
                    _footerButton(context, "Cancel Stay", Icons.cancel_outlined,
                        () {
                      showDialog(
                        context: context,
                        builder: (context) => CancelStayDialog(
                          booking: bookingToDisplay,
                          onCancellationConfirmed: () {
                            // Refresh the booking data or navigate away
                            context
                                .read<UserBookingsProvider>()
                                .fetchBookings();
                          },
                        ),
                      );
                    }),
                  ],
                );
              }

              if (property == null) return const SizedBox.shrink();

              return PropertyPriceFooter(
                property: property,
                onCheckoutPressed: () => checkoutPressed(propertyProvider),
              );
            },
          ),
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

  Widget _buildInfoFooter(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      color: Colors.grey[200],
      child: Text(text,
          textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
    );
  }

  Widget _buildActionFooter(
      {required BuildContext context,
      required String infoText,
      required List<Widget> actions}) {
    List<Widget> columnChildren = [];
    columnChildren.add(Text(infoText,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        textAlign: TextAlign.center));

    List<Widget> actualActionWidgets = [];
    if (actions.isNotEmpty) {
      if (actions.length == 1) {
        actualActionWidgets
            .add(SizedBox(width: double.infinity, child: actions.first));
      } else {
        // For multiple actions, put them in a Row
        actualActionWidgets.add(
          Row(
            children: actions
                .map((action) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: action,
                      ),
                    ))
                .toList(),
          ),
        );
      }
    }

    if (actualActionWidgets.isNotEmpty) {
      columnChildren.add(const SizedBox(height: 12));
      columnChildren.addAll(actualActionWidgets);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: columnChildren,
      ),
    );
  }

  Widget _footerButton(BuildContext context, String label, IconData icon,
      VoidCallback onPressed) {
    return CustomButton.compact(
      label: label,
      icon: icon,
      width: ButtonWidth.expanded,
      isLoading: false,
      onPressed: onPressed,
    );
  }
}
