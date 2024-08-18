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
