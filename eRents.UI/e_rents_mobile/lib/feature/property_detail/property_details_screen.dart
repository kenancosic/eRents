import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/feature/property_detail/property_details_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_mobile/core/mock/mock_properties.dart';
import 'package:e_rents_mobile/core/widgets/custom_slider.dart';

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
      child: BaseScreen(
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
                  Stack(
                    children: [
                      CustomSlider(
                        items: property.images.map((image) => Image.asset(
                          image.fileName,
                          width: double.infinity,
                          height: 350,
                          fit: BoxFit.cover,
                        )).toList(),
                        onPageChanged: (index) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
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
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                property.name,
                                style: Theme.of(context).textTheme.headlineMedium,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.favorite_border),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Rating and location
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  SvgPicture.asset(
                                    'assets/icons/star.svg',
                                    width: 15,
                                    height: 15,
                                    colorFilter: const ColorFilter.mode(Colors.amber, BlendMode.srcIn),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${property.averageRating ?? 'N/A'}',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  SvgPicture.asset(
                                    'assets/icons/location.svg',
                                    width: 15,
                                    height: 15,
                                    // colorFilter: ColorFilter.mode(Colors.grey.shade600, BlendMode.srcIn),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${property.city ?? ''}, ${property.address ?? ''}',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Property features
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  SvgPicture.asset(
                                    'assets/icons/single-bed.svg',
                                    width: 15,
                                    height: 15,
                                    // colorFilter: ColorFilter.mode(Colors.black, BlendMode.srcIn),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '2 room',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  SvgPicture.asset(
                                    'assets/icons/house-surface.svg',
                                    width: 15,
                                    height: 15,
                                    colorFilter: ColorFilter.mode(Colors.grey.shade600, BlendMode.srcIn),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '874 m²',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const CircleAvatar(
                              backgroundImage: AssetImage('assets/images/user-image.png'),
                              radius: 25,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                property.ownerId.toString() ?? 'Facility Owner',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                // Handle message action
                              },
                              icon: const Icon(Icons.message),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Home Facilities',
                          style: Theme.of(context).textTheme.titleLarge,
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
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
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