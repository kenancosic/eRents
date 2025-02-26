import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class CustomSlider extends StatefulWidget {
  final List<Widget> items;

  const CustomSlider({
    super.key,
    required this.items,
  });

  @override
  _CustomSlider createState() => _CustomSlider();
}

class _CustomSlider extends State<CustomSlider> {
  int _currentIndex = 0;
  final CarouselSliderController _controller = CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CarouselSlider(
          items: widget.items.map((item) {
            return Builder(
              builder: (BuildContext context) {
                return SizedBox(
                  width: MediaQuery.of(context).size.width,
                  // margin: const EdgeInsets.only(right: 5.0),
                  child: item,
                );
              },
            );
          }).toList(),
          carouselController: _controller,
          options: CarouselOptions(
            viewportFraction: 1,
            height: 200.0,
            autoPlay: false,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ),
        const SizedBox(height: 10),
        AnimatedSmoothIndicator(
          activeIndex: _currentIndex,
          count: widget.items.length,
          effect: const WormEffect(
            dotHeight: 8.0,
            dotWidth: 8.0,
            activeDotColor: Colors.black,
            dotColor: Colors.grey,
          ),
          onDotClicked: (index) {
            _controller.animateToPage(index);
          },
        ),
      ],
    );
  }
}
