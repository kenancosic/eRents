import 'dart:typed_data';

class ImageModel {
  final int imageId;
  final String fileName;
  final String? imageUrl; // For display from API
  final String? thumbnailUrl; // For mobile optimization
  final Uint8List? imageData; // Raw image data when uploading
  final Uint8List? thumbnailData; // Thumbnail data for optimization
  final bool isCover;
  final DateTime? dateUploaded;
  final String? contentType; // MIME type
  final int? width; // For UI layout
  final int? height; // For UI layout
  final int? fileSizeBytes; // For optimization decisions

  ImageModel({
    required this.imageId,
    required this.fileName,
    this.imageUrl,
    this.thumbnailUrl,
    this.imageData,
    this.thumbnailData,
    this.isCover = false,
    this.dateUploaded,
    this.contentType,
    this.width,
    this.height,
    this.fileSizeBytes,
  });

  factory ImageModel.fromJson(Map<String, dynamic> json) {
    return ImageModel(
      imageId: json['imageId'] as int,
      fileName: json['fileName'] as String,
      imageUrl: json['imageUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      isCover: json['isCover'] as bool? ?? false,
      dateUploaded: json['dateUploaded'] != null
          ? DateTime.parse(json['dateUploaded'] as String)
          : null,
      contentType: json['contentType'] as String?,
      width: json['width'] as int?,
      height: json['height'] as int?,
      fileSizeBytes: json['fileSizeBytes'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imageId': imageId,
      'fileName': fileName,
      'imageUrl': imageUrl,
      'thumbnailUrl': thumbnailUrl,
      'isCover': isCover,
      'dateUploaded': dateUploaded?.toIso8601String(),
      'contentType': contentType,
      'width': width,
      'height': height,
      'fileSizeBytes': fileSizeBytes,
    };
  }

  // Helper method to get appropriate image URL
  String? getDisplayUrl({bool preferThumbnail = false}) {
    if (preferThumbnail && thumbnailUrl != null) {
      return thumbnailUrl;
    }
    return imageUrl ?? thumbnailUrl;
  }

  // Helper method to check if image has been uploaded
  bool get isUploaded => imageUrl != null;

  // Helper method to check if thumbnail is available
  bool get hasThumbnail => thumbnailUrl != null || thumbnailData != null;

  ImageModel copyWith({
    int? imageId,
    String? fileName,
    String? imageUrl,
    String? thumbnailUrl,
    Uint8List? imageData,
    Uint8List? thumbnailData,
    bool? isCover,
    DateTime? dateUploaded,
    String? contentType,
    int? width,
    int? height,
    int? fileSizeBytes,
  }) {
    return ImageModel(
      imageId: imageId ?? this.imageId,
      fileName: fileName ?? this.fileName,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      imageData: imageData ?? this.imageData,
      thumbnailData: thumbnailData ?? this.thumbnailData,
      isCover: isCover ?? this.isCover,
      dateUploaded: dateUploaded ?? this.dateUploaded,
      contentType: contentType ?? this.contentType,
      width: width ?? this.width,
      height: height ?? this.height,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
    );
  }
}
