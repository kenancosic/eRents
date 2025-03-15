import 'package:flutter/material.dart';

class PriceDistributionSlider extends StatefulWidget {
  final List<int> priceDistribution;
  final RangeValues initialRange;
  final double min;
  final double max;
  final ValueChanged<RangeValues> onChanged;

  const PriceDistributionSlider({
    Key? key,
    required this.priceDistribution,
    required this.initialRange,
    required this.min,
    required this.max,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<PriceDistributionSlider> createState() =>
      _PriceDistributionSliderState();
}

class _PriceDistributionSliderState extends State<PriceDistributionSlider> {
  late RangeValues _currentRange;

  @override
  void initState() {
    super.initState();
    _currentRange = widget.initialRange;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 80,
          child: Stack(
            children: [
              // Distribution visualization
              Positioned.fill(
                child: CustomPaint(
                  painter: DistributionPainter(
                    distribution: widget.priceDistribution,
                    min: widget.min,
                    max: widget.max,
                    selectedRange: _currentRange,
                    primaryColor: Colors.purple[400]!,
                    secondaryColor: Colors.purple[100]!,
                  ),
                ),
              ),

              // Actual slider with improved accessibility
              Positioned.fill(
                child: RangeSlider(
                  values: _currentRange,
                  min: widget.min,
                  max: widget.max,
                  divisions: 50,
                  activeColor: Colors.purple[400],
                  inactiveColor: Colors.grey[300]?.withOpacity(0.5),
                  labels: RangeLabels(
                    '\$${_currentRange.start.toInt()}',
                    '\$${_currentRange.end.toInt()}+',
                  ),
                  semanticFormatterCallback: (double value) {
                    return '\$${value.round()}';
                  },
                  onChanged: (values) {
                    setState(() {
                      _currentRange = values;
                    });
                    widget.onChanged(values);
                  },
                ),
              ),
            ],
          ),
        ),

        // Price tick marks
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${widget.min.toInt()}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                '\$${((widget.max - widget.min) / 2 + widget.min).toInt()}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                '\$${widget.max.toInt()}+',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DistributionPainter extends CustomPainter {
  final List<int> distribution;
  final double min;
  final double max;
  final RangeValues selectedRange;
  final Color primaryColor;
  final Color secondaryColor;

  DistributionPainter({
    required this.distribution,
    required this.min,
    required this.max,
    required this.selectedRange,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final path = Path();

    // Find the maximum value in the distribution for scaling
    final maxValue = distribution
        .reduce((curr, next) => curr > next ? curr : next)
        .toDouble();
    final barWidth = size.width / distribution.length;

    // Start at the bottom-left
    path.moveTo(0, size.height);

    // Draw the distribution curve with improved control points
    for (int i = 0; i < distribution.length; i++) {
      final x = i * barWidth;
      final normalizedHeight = distribution[i] / maxValue;
      final y = size.height * (1 - normalizedHeight * 0.7);

      if (i == 0) {
        path.lineTo(x, y);
      } else {
        // Improved Bezier curve calculation
        final prevX = (i - 1) * barWidth;
        final prevY =
            size.height * (1 - (distribution[i - 1] / maxValue) * 0.7);
        final controlX = (prevX + x) / 2;
        final controlY = (prevY + y) / 2;
        path.quadraticBezierTo(controlX, controlY, x, y);
      }
    }

    // Complete the path
    path.lineTo(size.width, size.height);
    path.close();

    // Determine which part of the distribution is selected
    final startPct = (selectedRange.start - min) / (max - min);
    final endPct = (selectedRange.end - min) / (max - min);

    // Improved gradient with more precise stops
    final gradient = LinearGradient(
      colors: [
        secondaryColor.withOpacity(0.5),
        primaryColor.withOpacity(0.7),
        primaryColor.withOpacity(0.7),
        secondaryColor.withOpacity(0.5),
      ],
      stops: [0.0, startPct, endPct, 1.0],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    paint.shader =
        gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
