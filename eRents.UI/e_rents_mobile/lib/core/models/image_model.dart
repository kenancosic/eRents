class ImageModel {
  final int imageId;
  final int? reviewId;
  final int? propertyId;
  final String? fileName;
  final String imageData;
  final DateTime? dateUploaded;

  ImageModel({
    required this.imageId,
    this.reviewId,
    this.propertyId,
    this.fileName,
    required this.imageData,
    this.dateUploaded,
  });

  factory ImageModel.fromJson(Map<String, dynamic> json) {
    return ImageModel(
      imageId: json['imageId'],
      reviewId: json['reviewId'],
      propertyId: json['propertyId'],
      fileName: json['fileName'],
      imageData: json['imageData'],
      dateUploaded: json['dateUploaded'] != null ? DateTime.parse(json['dateUploaded']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imageId': imageId,
      'reviewId': reviewId,
      'propertyId': propertyId,
      'fileName': fileName,
      'imageData': imageData,
      'dateUploaded': dateUploaded?.toIso8601String(),
    };
  }
}
