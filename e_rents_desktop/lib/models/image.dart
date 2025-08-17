import 'dart:convert';
import 'dart:typed_data';

class Image {
  final int imageId;
  final int? propertyId;
  final int? maintenanceIssueId;

  final String? fileName;
  final String? contentType;
  final bool isCover;
  final int? width;
  final int? height;

  // Binary payloads are sent/received as base64 by the backend. We store as bytes.
  final Uint8List? imageData;

  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String? updatedBy;

  const Image({
    required this.imageId,
    this.propertyId,
    this.maintenanceIssueId,
    this.fileName,
    this.contentType,
    this.isCover = false,
    this.width,
    this.height,
    this.imageData,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    this.updatedBy,
  });

  factory Image.fromJson(Map<String, dynamic> json) {
    Uint8List? _decode(String? b64) {
      if (b64 == null || b64.isEmpty) return null;
      try {
        return Uint8List.fromList(base64Decode(b64));
      } catch (_) {
        return null;
      }
    }

    return Image(
      imageId: json['imageId'] as int,
      propertyId: json['propertyId'] as int?,
      maintenanceIssueId: json['maintenanceIssueId'] as int?,
      fileName: json['fileName'] as String?,
      isCover: (json['isCover'] as bool?) ?? false,
      contentType: json['contentType'] as String?,
      width: json['width'] as int?,
      height: json['height'] as int?,
      imageData: _decode(json['imageData'] as String?),
      createdAt: DateTime.parse(json['createdAt'] as String),
      createdBy: (json['createdBy'] as String?) ?? '',
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      updatedBy: json['updatedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    String? _encode(Uint8List? bytes) => bytes == null ? null : base64Encode(bytes);
    return <String, dynamic>{
      'imageId': imageId,
      'propertyId': propertyId,
      'maintenanceIssueId': maintenanceIssueId,
      'fileName': fileName,
      'isCover': isCover,
      'contentType': contentType,
      'width': width,
      'height': height,
      'imageData': _encode(imageData),
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'updatedAt': updatedAt.toIso8601String(),
      'updatedBy': updatedBy,
    };
  }
}