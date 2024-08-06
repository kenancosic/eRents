import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class ImageCarousel extends StatelessWidget {
  final List<String> images;

  const ImageCarousel({Key? key, required this.images}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CarouselSlider(
      options: CarouselOptions(height: 250.0, autoPlay: true),
      items: images.map((imageUrl) {
        return Builder(
          builder: (BuildContext context) {
            return Image.network(imageUrl, fit: BoxFit.cover, width: 1000);
          },
        );
      }).toList(),
    );
  }
}
