class Booking {
  int id;
  int propertyId;
  int userId;
  DateTime startDate;
  DateTime endDate;
  double totalPrice;
  DateTime bookingDate;

  Booking({
    required this.id,
    required this.propertyId,
    required this.userId,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.bookingDate,
  });
}
