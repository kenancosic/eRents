// DEPRECATED: This should be part of the unified notification system
// Use the unified Notification model instead

/*
class BookingNotificationMessage {
  final int bookingId;
  final String? message;

  BookingNotificationMessage({required this.bookingId, this.message});

  factory BookingNotificationMessage.fromJson(Map<String, dynamic> json) {
    return BookingNotificationMessage(
      bookingId: json['bookingId'],
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'message': message,
    };
  }
}
*/
