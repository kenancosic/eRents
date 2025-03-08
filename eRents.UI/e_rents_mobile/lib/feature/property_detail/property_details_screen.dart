import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/core/widgets/custom_avatar.dart';
import 'package:e_rents_mobile/core/widgets/custom_button.dart';
import 'package:e_rents_mobile/feature/property_detail/property_details_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_mobile/core/mock/mock_properties.dart';
import 'package:e_rents_mobile/core/widgets/custom_slider.dart';
import 'package:e_rents_mobile/core/models/property.dart';

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
          title: 'Property Details',
          showAppBar: false,
          showFilterButton: false,
          showBottomNavBar: false,
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
                          
                          // Property Description Section (NEW)
                          PropertyDescriptionSection(
                            description: property.description ?? 'This beautiful property offers modern amenities and a convenient location. Perfect for families or professionals looking for comfort and style. Features include spacious rooms, updated appliances, and a welcoming atmosphere.',
                          ),
                          
                          const Divider(color: Color(0xFFE0E0E0), height: 16),
                          const SizedBox(height: 16),
                          
                          // Property Owner Section
                          PropertyOwnerSection(),
                          
                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFFE0E0E0), height: 16),
                          const SizedBox(height: 16),
                          
                          // Facilities Section
                          FacilitiesSection(),
                          
                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFFE0E0E0), height: 16),
                          const SizedBox(height: 16),
                          
                          // Reviews Section (NEW)
                          PropertyReviewsSection(
                            reviews: [
                              Review(
                                userName: 'John Doe',
                                userImage: 'assets/images/user-image.png',
                                rating: 4.5,
                                comment: 'Great property! Very clean and comfortable. The location is perfect and the host was very responsive.',
                                date: 'Oct 15, 2023',
                              ),
                              Review(
                                userName: 'Jane Smith',
                                userImage: 'assets/images/user-image.png',
                                rating: 5.0,
                                comment: 'Absolutely loved my stay here. The amenities were top-notch and everything was as described.',
                                date: 'Sep 28, 2023',
                              ),
                              Review(
                                userName: 'Mike Johnson',
                                rating: 4.0,
                                comment: 'Good value for money. The property is well-maintained and in a nice neighborhood.',
                                date: 'Aug 12, 2023',
                              ),
                            ],
                            averageRating: property.averageRating ?? 4.5,
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
            
            return PropertyPriceFooter(property: property);
          },
        ),
      ),
    );
  }
}

// Component for Property Image Slider
class PropertyImageSlider extends StatelessWidget {
  final Property property;
  final Function(int) onPageChanged;

  const PropertyImageSlider({
    super.key,
    required this.property,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomSlider(
          items: property.images
              .map((image) => Image.asset(
                    image.fileName,
                    width: double.infinity,
                    height: 350,
                    fit: BoxFit.cover,
                  ))
              .toList(),
          onPageChanged: onPageChanged,
          useNumbering: true,
        ),
        Positioned(
          top: 48,
          left: 16,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: Colors.black.withValues(alpha: 0.7),
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Component for Property Title and Favorite Button
class PropertyHeader extends StatelessWidget {
  final Property property;

  const PropertyHeader({
    super.key,
    required this.property,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            property.name,
            style: Theme.of(context).textTheme.headlineMedium,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
        const SizedBox(width: 16),
        IconButton(
          style: IconButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            minimumSize: Size.zero,
          ),
          onPressed: () {},
          icon: const Icon(Icons.favorite_border, size: 24)
        ),
      ],
    );
  }
}

// Component for Property Owner Section
class PropertyOwnerSection extends StatelessWidget {
  const PropertyOwnerSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CustomAvatar(
          imageUrl: 'assets/images/user-image.png',
          size: 40,
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Facility Owner',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                'Property Owner',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            // Handle message action
          },
          icon: SvgPicture.asset('assets/icons/message.svg'),
        ),
      ],
    );
  }
}

// Component for Facilities Section
class FacilitiesSection extends StatelessWidget {
  const FacilitiesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Home Facilities',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildFacilityItem(Icons.wifi, 'WiFi'),
            _buildFacilityItem(Icons.local_parking, 'Parking'),
            _buildFacilityItem(Icons.ac_unit, 'AC'),
            _buildFacilityItem(Icons.tv, 'TV'),
            _buildFacilityItem(Icons.kitchen, 'Kitchen'),
            _buildFacilityItem(Icons.pool, 'Pool'),
          ],
        ),
      ],
    );
  }

  Widget _buildFacilityItem(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

// Component for Price Footer
class PropertyPriceFooter extends StatelessWidget {
  final Property property;

  const PropertyPriceFooter({
    super.key,
    required this.property,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate button width based on available space
          final buttonWidth = constraints.maxWidth * 0.35; // 35% of available width
          
          return Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\$${property.price}/month',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  Text(
                    'All bills included',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: buttonWidth,
                child: CustomButton(
                  isLoading: false,
                  onPressed: () {},
                  label: Text('Rent Now', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),),
                  // borderRadius: 12,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Keep the existing PropertyDetails class
class PropertyDetails extends StatelessWidget {
  final double? averageRating;
  final String? city;
  final String? address;
  final String rooms;
  final String area;
  final int numberOfReviews;

  const PropertyDetails({
    super.key,
    this.averageRating,
    this.city,
    this.address,
    required this.rooms,
    required this.area,
    required this.numberOfReviews,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Wrap(
            spacing: 20,
            runSpacing: 10,
            alignment: WrapAlignment.start,
            runAlignment: WrapAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailItem(icon: Icons.star_rounded, text: '${averageRating ?? 'N/A'} ($numberOfReviews reviews)', color: Colors.amber),
                  _buildDetailItem(icon: Icons.location_on_rounded, text: '${city ?? ''}, ${address ?? ''}', color: const Color(0xFF7D7F88)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailItem(icon: Icons.bed, text: rooms, color: const Color(0xFF7D7F88)),
                  _buildDetailItem(icon: Icons.square_foot_rounded, text: area, color: const Color(0xFF7D7F88)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailItem({required IconData icon, required String text, required Color color}) {
    return Wrap(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          text, 
          style: const TextStyle(color: Colors.black), 
          maxLines: 2,
          textAlign: TextAlign.start, 
          overflow: TextOverflow.ellipsis
        ),
      ],
    );
  }
}

// Component for Property Description
class PropertyDescriptionSection extends StatefulWidget {
  final String description;

  const PropertyDescriptionSection({
    super.key,
    required this.description,
  });

  @override
  State<PropertyDescriptionSection> createState() => _PropertyDescriptionSectionState();
}

class _PropertyDescriptionSectionState extends State<PropertyDescriptionSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          widget.description,
          style: Theme.of(context).textTheme.bodyMedium,
          maxLines: _expanded ? null : 3,
          overflow: _expanded ? null : TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () {
            setState(() {
              _expanded = !_expanded;
            });
          },
          child: Text(
            _expanded ? 'Show Less' : 'Read More',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// Component for Reviews and Testimonials
class PropertyReviewsSection extends StatelessWidget {
  final List<Review> reviews;
  final double averageRating;

  const PropertyReviewsSection({
    super.key,
    required this.reviews,
    required this.averageRating,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reviews',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () {
                // Navigate to all reviews page
              },
              child: Text('See All (${reviews.length})'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Rating summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Column(
                children: [
                  Text(
                    averageRating.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < averageRating.floor() 
                            ? Icons.star 
                            : (index < averageRating 
                                ? Icons.star_half 
                                : Icons.star_border),
                        color: Colors.amber,
                        size: 16,
                      );
                    }),
                  ),
                  Text(
                    'Based on ${reviews.length} reviews',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _buildRatingBar(context, 5, _calculatePercentage(5)),
                    _buildRatingBar(context, 4, _calculatePercentage(4)),
                    _buildRatingBar(context, 3, _calculatePercentage(3)),
                    _buildRatingBar(context, 2, _calculatePercentage(2)),
                    _buildRatingBar(context, 1, _calculatePercentage(1)),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Review list
        ...reviews.take(3).map((review) => _buildReviewItem(context, review)),
        
        if (reviews.length > 3)
          Center(
            child: TextButton(
              onPressed: () {
                // Navigate to all reviews
              },
              child: Text('View All ${reviews.length} Reviews'),
            ),
          ),
      ],
    );
  }
  
  double _calculatePercentage(int rating) {
    if (reviews.isEmpty) return 0.0;
    int count = reviews.where((review) => review.rating == rating).length;
    return count / reviews.length;
  }
  
  Widget _buildRatingBar(BuildContext context, int rating, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$rating',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(width: 4),
          Icon(Icons.star, color: Colors.amber, size: 12),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                color: Colors.amber,
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(percentage * 100).toInt()}%',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
  
  Widget _buildReviewItem(BuildContext context, Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: review.userImage != null 
                    ? AssetImage(review.userImage!) 
                    : null,
                child: review.userImage == null 
                    ? Text(review.userName.substring(0, 1)) 
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      review.date,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Text(
                    review.rating.toString(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.comment,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

// Review model class
class Review {
  final String userName;
  final String? userImage;
  final double rating;
  final String comment;
  final String date;

  Review({
    required this.userName,
    this.userImage,
    required this.rating,
    required this.comment,
    required this.date,
  });
}
