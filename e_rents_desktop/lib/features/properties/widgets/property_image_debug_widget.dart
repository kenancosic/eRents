import 'package:flutter/material.dart';
import 'package:e_rents_desktop/utils/image_utils.dart';

/// Debug widget to help diagnose image loading issues
class PropertyImageDebugWidget extends StatefulWidget {
  final String? imageUrl;
  final double? width;
  final double? height;

  const PropertyImageDebugWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
  });

  @override
  State<PropertyImageDebugWidget> createState() =>
      _PropertyImageDebugWidgetState();
}

class _PropertyImageDebugWidgetState extends State<PropertyImageDebugWidget> {
  bool _showDebugInfo = false;
  bool? _imageTestResult;

  @override
  void initState() {
    super.initState();
    _testImageUrl();
  }

  Future<void> _testImageUrl() async {
    if (widget.imageUrl != null) {
      final result = await ImageUtils.testImageUrl(widget.imageUrl);
      if (mounted) {
        setState(() {
          _imageTestResult = result;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main image
        ImageUtils.buildImage(
          widget.imageUrl,
          width: widget.width,
          height: widget.height,
          fit: BoxFit.cover,
        ),

        // Debug overlay (toggle with tap)
        if (_showDebugInfo)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Debug Info:',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Original URL: ${widget.imageUrl ?? "null"}',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  if (widget.imageUrl != null) ...[
                    Text(
                      'Absolute URL: ${ImageUtils.makeAbsoluteUrl(widget.imageUrl!)}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    Text(
                      'Is Asset: ${ImageUtils.isAssetPath(widget.imageUrl!)}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    Text(
                      'Is Network: ${ImageUtils.isNetworkUrl(widget.imageUrl!)}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    if (_imageTestResult != null)
                      Text(
                        'URL Test: ${_imageTestResult! ? "✅ PASS" : "❌ FAIL"}',
                        style: TextStyle(
                          color: _imageTestResult! ? Colors.green : Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),

        // Debug toggle button
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _showDebugInfo = !_showDebugInfo;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                _showDebugInfo ? Icons.visibility_off : Icons.bug_report,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
