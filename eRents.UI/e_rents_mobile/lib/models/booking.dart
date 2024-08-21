class Booking {
  final int bookingId;
  final int propertyId;
  final String propertyName;
  final int userId;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;
  final String status;

  Booking({
    required this.bookingId,
    required this.propertyId,
    required this.propertyName,
    required this.userId,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.status,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      bookingId: json['bookingId'],
      propertyId: json['propertyId'],
      propertyName: json['propertyName'],
      userId: json['userId'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      totalPrice: json['totalPrice'].toDouble(),
      status: json['status'],
    );
  }
}
enum BookingStatus { pending, confirmed, cancelled }
