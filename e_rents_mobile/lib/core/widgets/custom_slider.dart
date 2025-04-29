import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class CustomSlider extends StatefulWidget {
  final List<Widget> items;
  final Function(int)? onPageChanged;
  final bool useNumbering;

  const CustomSlider({
    super.key,
    required this.items,
    this.onPageChanged,
    this.useNumbering = false,
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
        Stack(
          children: [
            CarouselSlider(
              items: widget.items.map((item) {
                return Builder(
                  builder: (BuildContext context) {
                    return SizedBox(
                      width: MediaQuery.of(context).size.width,
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
                  widget.onPageChanged?.call(index);
                },
              ),
            ),
            if (widget.useNumbering)
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.items.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (!widget.useNumbering)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AnimatedSmoothIndicator(
                  activeIndex: _currentIndex,
                  count: widget.items.length,
                  effect: const WormEffect(
                    dotHeight: 8.0,
                    dotWidth: 8.0,
                    activeDotColor: Colors.indigo,
                    dotColor: Colors.grey,
                  ),
                  onDotClicked: (index) {
                    _controller.animateToPage(index);
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}
