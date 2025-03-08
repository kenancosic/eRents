import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 16, 16),
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 200,
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
              // Left side: the image
              Flexible(
                flex: 1,
                child: PropertyImage(imageUrl: imageUrl),
              ),
              // Right side: property details
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      PropertyRating(rating: rating, review: review),
                      PropertyTitle(title: title),
                      PropertyLocation(location: location),
                      PropertyAmenities(rooms: rooms, area: area),
                      PropertyPrice(price: price),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PropertyImage extends StatelessWidget {
  final String imageUrl;
  const PropertyImage({super.key, required this.imageUrl});

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
    );
  }
}

class PropertyRating extends StatelessWidget {
  final String rating;
  final int review;
  const PropertyRating({super.key, required this.rating, required this.review});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 12,
          height: 12,
          child: SvgPicture.asset(
            'assets/icons/star.svg',
            width: 12,
            height: 12,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          rating,
          style: const TextStyle(
            color: Color(0xFF1A1E25),
            fontSize: 12,
            fontFamily: 'Hind',
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          ' ($review)',
          style: const TextStyle(
            color: Color(0xFF7D7F88),
            fontSize: 12,
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
  const PropertyTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF1A1E25),
        fontSize: 16,
        fontFamily: 'Hind',
        fontWeight: FontWeight.w400,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class PropertyLocation extends StatelessWidget {
  final String location;
  const PropertyLocation({super.key, required this.location});

  @override
  Widget build(BuildContext context) {
    return Text(
      location,
      style: const TextStyle(
        color: Color(0xFF7D7F88),
        fontSize: 13,
        fontFamily: 'Hind',
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

class PropertyAmenities extends StatelessWidget {
  final int rooms;
  final int area;
  const PropertyAmenities({super.key, required this.rooms, required this.area});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      direction: Axis.horizontal,
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: [
        Wrap(
          direction: Axis.horizontal,
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Icon(Icons.bed, size: 14, color: Color(0xFF7D7F88)),
            const SizedBox(width: 6),
            Baseline(
              baseline: 13,
              baselineType: TextBaseline.alphabetic,
              child: Text(
                '$rooms rooms',
                style: const TextStyle(
                  color: Color(0xFF7D7F88),
                  fontSize: 13,
                  fontFamily: 'Hind',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        Wrap(
          direction: Axis.horizontal,
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Icon(Icons.square_foot, size: 14, color: Color(0xFF7D7F88)),
            const SizedBox(width: 6),
            Baseline(
              baseline: 14,
              baselineType: TextBaseline.alphabetic,
              child: Text(
                '$area m2',
                style: const TextStyle(
                  color: Color(0xFF7D7F88),
                fontSize: 13,
                fontFamily: 'Hind',
                fontWeight: FontWeight.w400,
                ),
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
  const PropertyPrice({super.key, required this.price});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: price,
            style: const TextStyle(
              color: Color(0xFF1A1E25),
              fontSize: 18,
              fontFamily: 'Hind',
              fontWeight: FontWeight.w700,
            ),
          ),
          const TextSpan(
            text: ' / month',
            style: TextStyle(
              color: Color(0xFF7D7F88),
              fontSize: 12,
              fontFamily: 'Hind',
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
