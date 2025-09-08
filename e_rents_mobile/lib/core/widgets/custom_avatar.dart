import 'package:flutter/material.dart';

/// A customizable avatar widget with optional camera icon overlay.
///
/// This widget displays a circular avatar with a gradient background and
/// an optional camera icon overlay, useful for profile images.
class CustomAvatar extends StatelessWidget {
  /// The image URL or asset path for the avatar
  final String imageUrl;

  /// The size of the avatar in pixels
  final double size;

  /// The width of the border around the avatar
  final double borderWidth;

  /// Callback function when the avatar is tapped
  final VoidCallback? onTap;

  /// Whether to show a camera icon overlay
  final bool showCameraIcon;

  /// The color of the camera icon background
  final Color? cameraIconColor;

  /// Creates a customizable avatar widget.
  ///
  /// The [imageUrl] parameter is required.
  const CustomAvatar({
    super.key,
    required this.imageUrl,
    this.size = 40.0,
    this.borderWidth = 1,
    this.onTap,
    this.showCameraIcon = false,
    this.cameraIconColor,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [
              Color(0xFF917AFD),
              Color(0xFF6246EA),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(borderWidth),
          child: CircleAvatar(
            backgroundImage: AssetImage(imageUrl),
            radius: size / 2 - borderWidth,
          ),
        ),
      ),
    );

    if (showCameraIcon && onTap != null) {
      return Stack(
        children: [
          avatar,
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: cameraIconColor ?? Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: size * 0.2,
              ),
            ),
          ),
        ],
      );
    }

    return avatar;
  }
}
