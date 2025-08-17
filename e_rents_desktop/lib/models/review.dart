import 'package:e_rents_desktop/models/booking.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/user.dart';

enum ReviewType {
  propertyReview, // Tenant reviewing a property after stay
  tenantReview,   // Landlord reviewing a tenant after booking ends
  responseReview; // Response to a review (reply)

  static ReviewType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'propertyreview':
        return ReviewType.propertyReview;
      case 'tenantreview':
        return ReviewType.tenantReview;
      case 'responsereview':
        return ReviewType.responseReview;
      default:
        throw ArgumentError('Unknown review type: $type');
    }
  }

  String get displayName {
    switch (this) {
      case ReviewType.propertyReview:
        return 'Property Review';
      case ReviewType.tenantReview:
        return 'Tenant Review';
      case ReviewType.responseReview:
        return 'Response Review';
    }
  }

  String get typeName {
    switch (this) {
      case ReviewType.propertyReview:
        return 'PropertyReview';
      case ReviewType.tenantReview:
        return 'TenantReview';
      case ReviewType.responseReview:
        return 'ResponseReview';
    }
  }
}

class Review {
  final int reviewId;
  final ReviewType reviewType;
  
  // For Property Reviews: PropertyId is the property being reviewed
  // For Tenant Reviews: PropertyId can be null or the property where tenant stayed
  final int? propertyId;
  
  // For Property Reviews: RevieweeId is null (reviewing the property itself)
  // For Tenant Reviews: RevieweeId is the tenant being reviewed
  final int? revieweeId; // User being reviewed (for tenant reviews)
  
  final int? reviewerId; // User who wrote the review
  final String? description;
  final double? starRating; // 1-5 stars, optional (null for replies without rating)
  final int? bookingId; // Required for original reviews, optional for replies
  
  // Threading system for conversations (replies to reviews)
  final int? parentReviewId; // null for original reviews, points to parent for replies
  
  // BaseEntity fields
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? createdBy;
  final int? modifiedBy;
  
  // Navigation properties - excluded from JSON serialization
  final Property? property;
  final Booking? booking;
  final User? reviewer; // The user who wrote the review
  final User? reviewee; // The user being reviewed (for tenant reviews)
  
  // Self-referencing navigation for threaded conversations
  final Review? parentReview;
  final List<Review>? replies;

  const Review({
    required this.reviewId,
    required this.reviewType,
    this.propertyId,
    this.revieweeId,
    this.reviewerId,
    this.description,
    this.starRating,
    this.bookingId,
    this.parentReviewId,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.modifiedBy,
    this.property,
    this.booking,
    this.reviewer,
    this.reviewee,
    this.parentReview,
    this.replies,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    DateTime _reqDate(dynamic v) {
      final d = (v == null) ? null : (v is DateTime ? v : DateTime.tryParse(v.toString()));
      return d ?? DateTime.now();
    }
    double? _asDouble(dynamic v) => v == null ? null : (v is num ? v.toDouble() : double.tryParse(v.toString()));
    int? _asInt(dynamic v) => v == null ? null : (v is num ? v.toInt() : int.tryParse(v.toString()));
    String? _asString(dynamic v) => v == null ? null : v.toString();
    ReviewType _parseType(dynamic v) {
      if (v == null) return ReviewType.propertyReview;
      try { return ReviewType.fromString(v.toString()); } catch (_) { return ReviewType.propertyReview; }
    }
    return Review(
      reviewId: (json['reviewId'] as num).toInt(),
      reviewType: _parseType(json['reviewType'] ?? json['type']),
      propertyId: _asInt(json['propertyId']),
      revieweeId: _asInt(json['revieweeId']),
      reviewerId: _asInt(json['reviewerId']),
      description: _asString(json['description']),
      starRating: _asDouble(json['starRating']),
      bookingId: _asInt(json['bookingId']),
      parentReviewId: _asInt(json['parentReviewId']),
      createdAt: _reqDate(json['createdAt']),
      updatedAt: _reqDate(json['updatedAt'] ?? json['createdAt']),
      createdBy: _asInt(json['createdBy']),
      modifiedBy: _asInt(json['modifiedBy']),
      property: null,
      booking: null,
      reviewer: null,
      reviewee: null,
      parentReview: null,
      replies: null,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'reviewId': reviewId,
        'reviewType': reviewType.typeName,
        'propertyId': propertyId,
        'revieweeId': revieweeId,
        'reviewerId': reviewerId,
        'description': description,
        'starRating': starRating,
        'bookingId': bookingId,
        'parentReviewId': parentReviewId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'createdBy': createdBy,
        'modifiedBy': modifiedBy,
      };
}