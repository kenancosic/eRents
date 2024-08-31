import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PropertyCard extends StatelessWidget {
  final String title;
  final String location;
  final String details;
  final String price;
  final String rating;
  final String imageUrl;
  final int review;
  final int rooms;
  final int area;

  const PropertyCard({
    Key? key,
    required this.title,
    required this.location,
    required this.details,
    required this.price,
    required this.rating,
    required this.imageUrl,
    this.review = 0,
    this.rooms = 0,
    this.area = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0,0,16,16),
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
            Flexible(
              flex: 1,
              child: Container(
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
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          child: SvgPicture.asset('assets/icons/star.svg',
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
                    ),
                    const SizedBox(height: 8),
                    Flexible(  // Make the title flexible to avoid overflow
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF1A1E25),
                          fontSize: 16,
                          fontFamily: 'Hind',
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      location,
                      style: const TextStyle(
                        color: Color(0xFF7D7F88),
                        fontSize: 13,
                        fontFamily: 'Hind',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.bed, size: 14, color: Color(0xFF7D7F88)),
                            const SizedBox(width: 6),
                            Text(
                              '$rooms rooms',
                              style: const TextStyle(
                                color: Color(0xFF7D7F88),
                                fontSize: 13,
                                fontFamily: 'Hind',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Row(
                          children: [
                            const Icon(Icons.square_foot, size: 14, color: Color(0xFF7D7F88)),
                            const SizedBox(width: 6),
                            Text(
                              '$area m2',
                              style: const TextStyle(
                                color: Color(0xFF7D7F88),
                                fontSize: 13,
                                fontFamily: 'Hind',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text.rich(
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
}
