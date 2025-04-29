import 'dart:typed_data';

class ImageResponse {
  final int imageId;
  final String fileName;
  final ByteData imageData ;
  final DateTime dateUploaded;

  ImageResponse({
    required this.imageId,
    required this.fileName,
    required this.imageData,
    required this.dateUploaded,
  });

  factory ImageResponse.fromJson(Map<String, dynamic> json) {
    return ImageResponse(
      imageId: json['imageId'],
      fileName: json['fileName'],
      imageData: json['imageData'],
      dateUploaded: DateTime.parse(json['dateUploaded']),
    );
  }
}