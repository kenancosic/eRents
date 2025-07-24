import 'package:e_rents_mobile/feature/saved/saved_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_mobile/core/models/property.dart';

enum PropertyCardLayout {
  horizontal, // Original horizontal layout
  compactHorizontal, // Compact horizontal layout
  vertical, // New vertical layout similar to UpcomingStayCard
}

class PropertyCard extends StatelessWidget {
  final Property property;
  final VoidCallback? onTap;
  final PropertyCardLayout layout;

  const PropertyCard({
    super.key,
    required this.property,
    this.onTap,
    this.layout = PropertyCardLayout.horizontal, // Default to full horizontal
  });

  // Legacy constructor for backward compatibility
  const PropertyCard.compact({
    super.key,
    required this.property,
    this.onTap,
  }) : layout = PropertyCardLayout.compactHorizontal;

  // New constructor for vertical layout
  const PropertyCard.vertical({
    super.key,
    required this.property,
    this.onTap,
  }) : layout = PropertyCardLayout.vertical;

  @override
  Widget build(BuildContext context) {
    switch (layout) {
      case PropertyCardLayout.vertical:
        return _buildVerticalCard(context);
      case PropertyCardLayout.compactHorizontal:
        return _buildHorizontalCard(context, isCompact: true);
      case PropertyCardLayout.horizontal:
        return _buildHorizontalCard(context, isCompact: false);
    }
  }

  Widget _buildVerticalCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            SizedBox(
              height: 120,
              width: double.infinity,
              child: Stack(
                children: [
                  PropertyImageVertical(
                    imageUrl: _getImageUrl(),
                    rentalType: property.rentalType,
                  ),
                  // Bookmark button positioned on image
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: BookmarkButton(
                        property: property,
                        isCompact: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PropertyTitle(title: property.name, isCompact: true),
                        const SizedBox(height: 4),
                        PropertyLocation(
                            location: _getLocationString(), isCompact: true),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: PropertyRating(
                            rating: _getRatingString(),
                            review: _getReviewCount(),
                            isCompact: true,
                          ),
                        ),
                        PropertyPrice(
                            price: _getPriceString(), isCompact: true),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalCard(BuildContext context, {required bool isCompact}) {
    final cardHeight = isCompact ? 120.0 : 160.0;
    final padding = isCompact ? 8.0 : 12.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 16, 16),
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: cardHeight,
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            shadows: const [
              BoxShadow(
                color: Color(0x26424242),
                blurRadius: 10,
                offset: Offset(5, 5),
                spreadRadius: 1,
              )
            ],
          ),
          child: Row(
            children: [
              // Left side: the image with rental type badge
              Flexible(
                flex: 1,
                child: PropertyImage(
                  imageUrl: _getImageUrl(),
                  rentalType: property.rentalType,
                  isCompact: isCompact,
                ),
              ),
              // Right side: property details
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: isCompact ? _buildCompactLayout() : _buildFullLayout(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getImageUrl() {
    if (property.imageIds.isNotEmpty) {
      // In production, this would fetch from ImageController: '/Image/${property.imageIds.first}'
      // For now, using fallback image since we don't have full image service integration
      return 'assets/images/house.jpg';
    }
    // Fallback image
    return 'assets/images/house.jpg';
  }

  String _getLocationString() {
    if (property.address != null) {
      final address = property.address!;
      final street = address.streetLine1 ?? '';
      final city = address.city ?? '';
      return street.isNotEmpty ? '$street, $city' : city;
    }
    return 'Location not available';
  }

  String _getPriceString() {
    if (property.rentalType == PropertyRentalType.daily &&
        property.dailyRate != null) {
      return '\$${property.dailyRate!.toStringAsFixed(0)}';
    }
    return '\$${property.price.toStringAsFixed(0)}';
  }

  String _getRatingString() {
    return property.averageRating?.toStringAsFixed(1) ?? '0.0';
  }

  int _getReviewCount() {
    // This would typically come from a separate reviews count field
    // For now, using a mock value or could be calculated from related data
    return 12; // Mock value - in real app this should come from the property or be passed separately
  }

  int _getRoomCount() {
    // This would typically be parsed from facilities or be a separate field
    // For now, using a mock value
    return 2; // Mock value - in real app this should come from property facilities or separate field
  }

  int _getAreaValue() {
    // This would typically be a separate field in the property model
    // For now, using a mock value
    return 874; // Mock value - in real app this should come from property
  }

  Widget _buildCompactLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rating, bookmark, and price in same row for space efficiency
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: PropertyRating(
                  rating: _getRatingString(),
                  review: _getReviewCount(),
                  isCompact: true),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                BookmarkButton(
                  property: property,
                  isCompact: true,
                ),
                PropertyPrice(price: _getPriceString(), isCompact: true),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Title with smaller max lines
        Flexible(
          child: PropertyTitle(title: property.name, isCompact: true),
        ),
        const SizedBox(height: 2),
        // Location
        PropertyLocation(location: _getLocationString(), isCompact: true),
        const Spacer(),
        // Amenities at bottom
        PropertyAmenities(
            rooms: _getRoomCount(), area: _getAreaValue(), isCompact: true),
      ],
    );
  }

  Widget _buildFullLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: PropertyRating(
                  rating: _getRatingString(), review: _getReviewCount()),
            ),
            BookmarkButton(
              property: property,
              isCompact: false,
            ),
          ],
        ),
        PropertyTitle(title: property.name),
        PropertyLocation(location: _getLocationString()),
        PropertyAmenities(rooms: _getRoomCount(), area: _getAreaValue()),
        PropertyPrice(price: _getPriceString()),
      ],
    );
  }
}

class PropertyImageVertical extends StatelessWidget {
  final String imageUrl;
  final PropertyRentalType? rentalType;

  const PropertyImageVertical({
    super.key,
    required this.imageUrl,
    this.rentalType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(imageUrl),
          fit: BoxFit.cover,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: rentalType != null
          ? Stack(
              children: [
                // Rental type badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: RentalTypeBadge(
                    rentalType: rentalType!,
                    isCompact: true,
                  ),
                ),
              ],
            )
          : null,
    );
  }
}

class PropertyImage extends StatelessWidget {
  final String imageUrl;
  final PropertyRentalType? rentalType;
  final bool isCompact;

  const PropertyImage({
    super.key,
    required this.imageUrl,
    this.rentalType,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(imageUrl),
          fit: BoxFit.cover,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          bottomLeft: Radius.circular(10),
        ),
      ),
      child: rentalType != null
          ? Stack(
              children: [
                // Rental type badge
                Positioned(
                  top: isCompact ? 6 : 8,
                  left: isCompact ? 6 : 8,
                  child: RentalTypeBadge(
                    rentalType: rentalType!,
                    isCompact: isCompact,
                  ),
                ),
              ],
            )
          : null,
    );
  }
}

class RentalTypeBadge extends StatelessWidget {
  final PropertyRentalType rentalType;
  final bool isCompact;

  const RentalTypeBadge({
    super.key,
    required this.rentalType,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = _getBadgeColor();
    final badgeText = _getBadgeText();
    final fontSize = isCompact ? 8.0 : 10.0;
    final padding = isCompact
        ? const EdgeInsets.symmetric(horizontal: 4, vertical: 2)
        : const EdgeInsets.symmetric(horizontal: 6, vertical: 3);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(isCompact ? 8 : 10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        badgeText,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getBadgeColor() {
    switch (rentalType) {
      case PropertyRentalType.daily:
        return Colors.blue[600]!;
      case PropertyRentalType.monthly:
        return Colors.green[600]!;
    }
  }

  String _getBadgeText() {
    switch (rentalType) {
      case PropertyRentalType.daily:
        return 'Daily';
      case PropertyRentalType.monthly:
        return 'Monthly';
    }
  }
}

class BookmarkButton extends StatelessWidget {
  final Property property;
  final bool isCompact;

  const BookmarkButton({
    super.key,
    required this.property,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = isCompact ? 16.0 : 20.0;

    return Consumer<SavedProvider>(
      builder: (context, savedProvider, child) {
        final isBookmarked = savedProvider.isPropertySaved(property.propertyId);
        final isLoading = savedProvider.isLoading;

        return GestureDetector(
          onTap: isLoading
              ? null
              : () async {
                  await savedProvider.toggleSavedStatus(property);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isBookmarked
                              ? 'Property removed from saved'
                              : 'Property saved successfully',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
          child: Container(
            padding: const EdgeInsets.all(4),
            child: isLoading
                ? SizedBox(
                    width: iconSize,
                    height: iconSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.grey[600],
                    ),
                  )
                : Icon(
                    isBookmarked ? Icons.favorite : Icons.favorite_border,
                    size: iconSize,
                    color: isBookmarked ? Colors.red[700] : Colors.grey[600],
                  ),
          ),
        );
      },
    );
  }
}

class PropertyRating extends StatelessWidget {
  final String rating;
  final int review;
  final bool isCompact;
  const PropertyRating({
    super.key,
    required this.rating,
    required this.review,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = isCompact ? 10.0 : 11.0;
    final iconSize = isCompact ? 8.0 : 10.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: iconSize,
          height: iconSize,
          child: SvgPicture.asset(
            'assets/icons/star.svg',
            width: iconSize,
            height: iconSize,
          ),
        ),
        SizedBox(width: isCompact ? 2 : 4),
        Text(
          rating,
          style: TextStyle(
            color: const Color(0xFF1A1E25),
            fontSize: fontSize,
            fontFamily: 'Hind',
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          ' ($review)',
          style: TextStyle(
            color: const Color(0xFF7D7F88),
            fontSize: fontSize,
            fontFamily: 'Hind',
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class PropertyTitle extends StatelessWidget {
  final String title;
  final bool isCompact;
  const PropertyTitle({
    super.key,
    required this.title,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = isCompact ? 13.0 : 14.0;
    final maxLines = isCompact ? 1 : 2;

    return Text(
      title,
      style: TextStyle(
        color: const Color(0xFF1A1E25),
        fontSize: fontSize,
        fontFamily: 'Hind',
        fontWeight: FontWeight.w400,
      ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class PropertyLocation extends StatelessWidget {
  final String location;
  final bool isCompact;
  const PropertyLocation({
    super.key,
    required this.location,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = isCompact ? 11.0 : 12.0;

    return Text(
      location,
      style: TextStyle(
        color: const Color(0xFF7D7F88),
        fontSize: fontSize,
        fontFamily: 'Hind',
        fontWeight: FontWeight.w400,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class PropertyAmenities extends StatelessWidget {
  final int rooms;
  final int area;
  final bool isCompact;
  const PropertyAmenities({
    super.key,
    required this.rooms,
    required this.area,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = isCompact ? 10.0 : 12.0;
    final iconSize = isCompact ? 10.0 : 12.0;
    final spacing = isCompact ? 4.0 : 8.0;

    return Wrap(
      direction: Axis.horizontal,
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Wrap(
          direction: Axis.horizontal,
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(Icons.bed, size: iconSize, color: const Color(0xFF7D7F88)),
            SizedBox(width: isCompact ? 2 : 4),
            Text(
              '$rooms rooms',
              style: TextStyle(
                color: const Color(0xFF7D7F88),
                fontSize: fontSize,
                fontFamily: 'Hind',
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        SizedBox(width: spacing),
        Wrap(
          direction: Axis.horizontal,
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(Icons.square_foot,
                size: iconSize, color: const Color(0xFF7D7F88)),
            SizedBox(width: isCompact ? 2 : 4),
            Text(
              '$area m2',
              style: TextStyle(
                color: const Color(0xFF7D7F88),
                fontSize: fontSize,
                fontFamily: 'Hind',
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class PropertyPrice extends StatelessWidget {
  final String price;
  final bool isCompact;
  const PropertyPrice({
    super.key,
    required this.price,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final priceSize = isCompact ? 14.0 : 16.0;
    final suffixSize = isCompact ? 10.0 : 11.0;

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: price,
            style: TextStyle(
              color: const Color(0xFF1A1E25),
              fontSize: priceSize,
              fontFamily: 'Hind',
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(
            text: isCompact ? '/mo' : ' / month',
            style: TextStyle(
              color: const Color(0xFF7D7F88),
              fontSize: suffixSize,
              fontFamily: 'Hind',
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
