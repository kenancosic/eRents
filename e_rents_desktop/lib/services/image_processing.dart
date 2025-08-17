import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// ImageProcessing provides client-side downscaling and compression
/// to keep upload sizes small and consistent.
class ImageProcessing {
  /// Downscale keeping aspect ratio so that the longer side is <= maxSidePx
  /// and encode to JPEG with [quality] (1-100).
  static Uint8List downscaleToJpeg(
    Uint8List inputBytes, {
    int maxSidePx = 1600,
    int quality = 85,
  }) {
    final decoded = img.decodeImage(inputBytes);
    if (decoded == null) return inputBytes; // fallback

    // Compute target size preserving aspect ratio
    final w = decoded.width;
    final h = decoded.height;
    final maxSide = w > h ? w : h;
    img.Image resized = decoded;
    if (maxSide > maxSidePx) {
      final scale = maxSidePx / maxSide;
      final targetW = (w * scale).round();
      final targetH = (h * scale).round();
      resized = img.copyResize(
        decoded,
        width: targetW,
        height: targetH,
        interpolation: img.Interpolation.average,
      );
    }

    final jpg = img.encodeJpg(resized, quality: quality);
    return Uint8List.fromList(jpg);
  }

  /// Build a small thumbnail suitable for grids/lists.
  static Uint8List buildThumbnail(
    Uint8List inputBytes, {
    int maxSidePx = 400,
    int quality = 70,
  }) {
    final decoded = img.decodeImage(inputBytes);
    if (decoded == null) return Uint8List(0);

    final w = decoded.width;
    final h = decoded.height;
    final maxSide = w > h ? w : h;
    final scale = maxSidePx / maxSide;
    final targetW = (w * scale).round();
    final targetH = (h * scale).round();

    final resized = img.copyResize(
      decoded,
      width: targetW,
      height: targetH,
      interpolation: img.Interpolation.average,
    );

    final jpg = img.encodeJpg(resized, quality: quality);
    return Uint8List.fromList(jpg);
  }
}
