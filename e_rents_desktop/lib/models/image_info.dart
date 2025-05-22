class ImageInfo {
  final String id;
  final String url;
  final String? fileName;
  final int? width;
  final int? height;
  final int? sizeBytes;
  final DateTime? uploadedAt;

  ImageInfo({
    required this.id,
    required this.url,
    this.fileName,
    this.width,
    this.height,
    this.sizeBytes,
    this.uploadedAt,
  });

  factory ImageInfo.fromJson(Map<String, dynamic> json) => ImageInfo(
    id: json['id'] as String,
    url: json['url'] as String,
    fileName: json['fileName'] as String?,
    width: json['width'] as int?,
    height: json['height'] as int?,
    sizeBytes: json['sizeBytes'] as int?,
    uploadedAt:
        json['uploadedAt'] != null ? DateTime.parse(json['uploadedAt']) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'url': url,
    if (fileName != null) 'fileName': fileName,
    if (width != null) 'width': width,
    if (height != null) 'height': height,
    if (sizeBytes != null) 'sizeBytes': sizeBytes,
    if (uploadedAt != null) 'uploadedAt': uploadedAt!.toIso8601String(),
  };
}
