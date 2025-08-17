import 'package:flutter/material.dart';

import 'package:e_rents_desktop/models/enums/rental_request_status.dart';

/// UI extensions for RentalRequestStatus
extension RentalRequestStatusUiX on RentalRequestStatus {
  Color get color {
    switch (this) {
      case RentalRequestStatus.pending:
        return Colors.orange;
      case RentalRequestStatus.approved:
        return Colors.green;
      case RentalRequestStatus.rejected:
        return Colors.red;
      case RentalRequestStatus.cancelled:
        return Colors.grey;
    }
  }

  IconData get icon {
    switch (this) {
      case RentalRequestStatus.pending:
        return Icons.hourglass_bottom;
      case RentalRequestStatus.approved:
        return Icons.thumb_up_alt;
      case RentalRequestStatus.rejected:
        return Icons.thumb_down_alt;
      case RentalRequestStatus.cancelled:
        return Icons.cancel;
    }
  }
}
