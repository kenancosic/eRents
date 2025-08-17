// Domain enum: no Flutter imports
enum BookingStatus {
  upcoming,
  active,
  completed,
  cancelled,
}

extension BookingStatusX on BookingStatus {
  String get displayName {
    switch (this) {
      case BookingStatus.upcoming:
        return 'Upcoming';
      case BookingStatus.active:
        return 'Active';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get wireValue => name.toLowerCase();

  static BookingStatus parse(Object? input, {BookingStatus fallback = BookingStatus.upcoming}) {
    if (input == null) return fallback;
    final s = input.toString().trim();
    if (s.isEmpty) return fallback;
    switch (s.toLowerCase()) {
      case 'upcoming':
        return BookingStatus.upcoming;
      case 'active':
        return BookingStatus.active;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      default:
        return fallback;
    }
  }
}
