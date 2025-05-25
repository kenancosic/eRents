import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:e_rents_mobile/core/models/property.dart';

class PropertyCard extends StatelessWidget {
  final String title;
  final String location;
  final String details; // You can decide how to use this if needed.
  final String price;
  final String rating;
  final String imageUrl;
  final int review;
  final int rooms;
  final int area;
  final VoidCallback? onTap;
  final bool isCompact; // New parameter for compact layout
  final PropertyRentalType? rentalType; // New parameter for rental type
  final bool? isBookmarked; // New parameter for bookmark status
  final VoidCallback? onBookmarkTap; // New parameter for bookmark callback

  const PropertyCard({
    super.key,
    required this.title,
    required this.location,
    required this.details,
    required this.price,
    required this.rating,
    required this.imageUrl,
    this.review = 0,
    this.rooms = 0,
    this.area = 0,
    this.onTap,
    this.isCompact = false, // Default to full size
    this.rentalType,
    this.isBookmarked,
    this.onBookmarkTap,
  });

  @override
  Widget build(BuildContext context) {
    // Use different heights based on compact mode
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
                  imageUrl: imageUrl,
                  rentalType: rentalType,
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
                  rating: rating, review: review, isCompact: true),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onBookmarkTap != null)
                  BookmarkButton(
                    isBookmarked: isBookmarked ?? false,
                    onTap: onBookmarkTap!,
                    isCompact: true,
                  ),
                PropertyPrice(price: price, isCompact: true),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Title with smaller max lines
        Flexible(
          child: PropertyTitle(title: title, isCompact: true),
        ),
        const SizedBox(height: 2),
        // Location
        PropertyLocation(location: location, isCompact: true),
        const Spacer(),
        // Amenities at bottom
        PropertyAmenities(rooms: rooms, area: area, isCompact: true),
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
              child: PropertyRating(rating: rating, review: review),
            ),
            if (onBookmarkTap != null)
              BookmarkButton(
                isBookmarked: isBookmarked ?? false,
                onTap: onBookmarkTap!,
                isCompact: false,
              ),
          ],
        ),
        PropertyTitle(title: title),
        PropertyLocation(location: location),
        PropertyAmenities(rooms: rooms, area: area),
        PropertyPrice(price: price),
      ],
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
            color: Colors.black.withOpacity(0.2),
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
      case PropertyRentalType.both:
        return Colors.purple[600]!;
    }
  }

  String _getBadgeText() {
    switch (rentalType) {
      case PropertyRentalType.daily:
        return 'Daily';
      case PropertyRentalType.monthly:
        return 'Monthly';
      case PropertyRentalType.both:
        return 'Both';
    }
  }
}

class BookmarkButton extends StatelessWidget {
  final bool isBookmarked;
  final VoidCallback onTap;
  final bool isCompact;

  const BookmarkButton({
    super.key,
    required this.isBookmarked,
    required this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = isCompact ? 16.0 : 20.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        child: Icon(
          isBookmarked ? Icons.favorite : Icons.favorite_border,
          size: iconSize,
          color: isBookmarked ? Colors.red[700] : Colors.grey[600],
        ),
      ),
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
