import 'package:flutter/material.dart';

import 'package:e_rents_desktop/models/enums/booking_status.dart';

/// UI extensions for BookingStatus
extension BookingStatusUiX on BookingStatus {
  Color get color {
    switch (this) {
      case BookingStatus.upcoming:
        return Colors.blueGrey;
      case BookingStatus.active:
        return Colors.blue;
      case BookingStatus.completed:
        return Colors.green;
      case BookingStatus.cancelled:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case BookingStatus.upcoming:
        return Icons.schedule;
      case BookingStatus.active:
        return Icons.play_circle_fill;
      case BookingStatus.completed:
        return Icons.check_circle;
      case BookingStatus.cancelled:
        return Icons.cancel;
    }
  }
}
