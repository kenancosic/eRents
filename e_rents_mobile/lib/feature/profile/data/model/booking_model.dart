enum BookingStatus { Upcoming, Completed, Cancelled }

class Booking {
  final String id;
  final String propertyName;
  final String propertyImageUrl;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;
  final BookingStatus status;
  final int numberOfGuests; // Optional: if you track this

  Booking({
    required this.id,
    required this.propertyName,
    required this.propertyImageUrl,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.status,
    this.numberOfGuests = 1, // Default or make it required
  });

  // Helper to get a string representation of status for display
  String get statusDisplay {
    switch (status) {
      case BookingStatus.Upcoming:
        return 'Upcoming';
      case BookingStatus.Completed:
        return 'Completed';
      case BookingStatus.Cancelled:
        return 'Cancelled';
      default:
        return '';
    }
  }

  // Helper to get a color for status chip
  // You might want to move color definitions to your theme or constants file
  // For now, keeping it simple here. Import 'package:flutter/material.dart'; if used in UI
  // This model shouldn't directly depend on Flutter UI elements for better separation.
  // Consider passing colors or using a theming approach in the widget.

  // factory Booking.fromJson(Map<String, dynamic> json) {
  //   return Booking(
  //     id: json['id'],
  //     propertyName: json['propertyName'],
  //     propertyImageUrl: json['propertyImageUrl'],
  //     startDate: DateTime.parse(json['startDate']),
  //     endDate: DateTime.parse(json['endDate']),
  //     totalPrice: (json['totalPrice'] as num).toDouble(),
  //     status: BookingStatus.values.firstWhere(
  //       (e) => e.toString() == 'BookingStatus.${json['status']}',
  //       orElse: () => BookingStatus.Upcoming, // Default or error handling
  //     ),
  //     numberOfGuests: json['numberOfGuests'] ?? 1,
  //   );
  // }

  // Map<String, dynamic> toJson() {
  //   return {
  //     'id': id,
  //     'propertyName': propertyName,
  //     'propertyImageUrl': propertyImageUrl,
  //     'startDate': startDate.toIso8601String(),
  //     'endDate': endDate.toIso8601String(),
  //     'totalPrice': totalPrice,
  //     'status': status.toString().split('.').last,
  //     'numberOfGuests': numberOfGuests,
  //   };
  // }
}
