class ImageInfo {
  final int? id;
  final String? url;
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
    id: (json['imageId'] ?? json['id']) as int?,
    url: json['url'] as String? ?? '',
    fileName: json['fileName'] as String?,
    width: json['width'] as int?,
    height: json['height'] as int?,
    sizeBytes: json['fileSizeBytes'] as int? ?? json['sizeBytes'] as int?,
    uploadedAt:
        json['dateUploaded'] != null
            ? DateTime.tryParse(json['dateUploaded'] as String)
            : json['uploadedAt'] != null
            ? DateTime.tryParse(json['uploadedAt'] as String)
            : null,
  );

  Map<String, dynamic> toJson() => {
    'imageId': id,
    'url': url,
    if (fileName != null) 'fileName': fileName,
    if (width != null) 'width': width,
    if (height != null) 'height': height,
    if (sizeBytes != null) 'fileSizeBytes': sizeBytes,
    if (uploadedAt != null) 'dateUploaded': uploadedAt!.toIso8601String(),
  };
}
