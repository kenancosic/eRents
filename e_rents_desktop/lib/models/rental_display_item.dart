import 'package:e_rents_desktop/models/booking.dart';
import 'package:e_rents_desktop/models/rental_request.dart';
import 'rental_status.dart';

/// Enum for rental categories using the improved naming from the plan
enum RentalCategory {
  stay('Stay', 'Short-term rental'), // Daily bookings
  lease('Lease', 'Long-term rental'); // Annual rental requests

  const RentalCategory(this.displayName, this.description);
  final String displayName;
  final String description;
}

/// Unified display model for both bookings (stays) and rental requests (leases)
/// This is a frontend-only wrapper that doesn't modify backend entities
class RentalDisplayItem {
  // === COMMON FIELDS ===
  final String id; // bookingId or requestId
  final RentalCategory category; // stay | lease
  final int propertyId;
  final int userId;
  final DateTime startDate;
  final DateTime? endDate;
  final String? propertyName;
  final String? userName;
  final RentalStatus rentalStatus;
  final double amount; // totalPrice or proposedMonthlyRent

  // === TYPE-SPECIFIC FIELDS ===
  final int? numberOfGuests; // Booking only
  final int? leaseDurationMonths; // RentalRequest only
  final String? requestMessage; // RentalRequest only
  final String? landlordResponse; // RentalRequest only
  final DateTime? requestDate; // RentalRequest only

  const RentalDisplayItem({
    required this.id,
    required this.category,
    required this.propertyId,
    required this.userId,
    required this.startDate,
    this.endDate,
    this.propertyName,
    this.userName,
    required this.rentalStatus,
    required this.amount,
    this.numberOfGuests,
    this.leaseDurationMonths,
    this.requestMessage,
    this.landlordResponse,
    this.requestDate,
  });

  /// Factory for creating from Booking (Stay)
  factory RentalDisplayItem.fromBooking(Booking booking) {
    return RentalDisplayItem(
      id: booking.bookingId.toString(),
      category: RentalCategory.stay,
      propertyId: booking.propertyId ?? 0,
      userId: booking.userId ?? 0,
      startDate: booking.startDate,
      endDate: booking.endDate,
      propertyName: booking.propertyName,
      userName: booking.userName,
      rentalStatus: _mapBookingStatus(booking.status),
      amount: booking.totalPrice,
      numberOfGuests: booking.numberOfGuests,
      // Annual-specific fields remain null
    );
  }

  /// Factory for creating from RentalRequest (Lease)
  factory RentalDisplayItem.fromRentalRequest(RentalRequest request) {
    return RentalDisplayItem(
      id: request.requestId.toString(),
      category: RentalCategory.lease,
      propertyId: request.propertyId,
      userId: request.userId,
      startDate: request.proposedStartDate,
      endDate: request.proposedEndDate,
      propertyName: request.propertyName,
      userName: request.userName,
      rentalStatus: _mapRequestStatus(request.status),
      amount: request.proposedMonthlyRent,
      leaseDurationMonths: request.leaseDurationMonths,
      requestMessage: request.message,
      landlordResponse: request.landlordResponse,
      requestDate: request.requestDate,
    );
  }

  // === HELPER GETTERS ===

  bool get isStay => category == RentalCategory.stay;
  bool get isLease => category == RentalCategory.lease;

  String get formattedStartDate =>
      '${startDate.day}/${startDate.month}/${startDate.year}';

  String get formattedEndDate =>
      endDate != null
          ? '${endDate!.day}/${endDate!.month}/${endDate!.year}'
          : 'N/A';

  String get formattedAmount {
    if (isStay) {
      return '${amount.toStringAsFixed(2)} BAM';
    } else {
      return '${amount.toStringAsFixed(2)} BAM/month';
    }
  }

  String get dateRangeDisplay => '$formattedStartDate - $formattedEndDate';

  String get occupantRole => isStay ? 'Guest' : 'Tenant';

  /// Legacy string-based status used by existing UI widgets.  Prefer the
  /// strongly-typed [rentalStatus] moving forward.
  String get status => rentalStatus.displayName;

  String get displayPropertyName => propertyName ?? 'Property $propertyId';
  String get displayUserName => userName ?? 'User $userId';

  /// Check if this rental can be cancelled (for stays) or withdrawn (for leases)
  bool get canBeCancelled {
    if (isStay) {
      switch (rentalStatus) {
        case RentalStatus.stayActive:
        case RentalStatus.stayUpcoming:
        case RentalStatus.stayConfirmed:
          return true;
        default:
          return false;
      }
    } else {
      return rentalStatus == RentalStatus.requestPending;
    }
  }

  /// Check if this rental request can be approved/rejected (leases only)
  bool get canBeApproved =>
      isLease && rentalStatus == RentalStatus.requestPending;

  @override
  String toString() {
    return 'RentalDisplayItem(id: $id, category: ${category.displayName}, status: ${rentalStatus.displayName})';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RentalDisplayItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          category == other.category;

  @override
  int get hashCode => id.hashCode ^ category.hashCode;
}

// ============================================================
// PRIVATE HELPER FUNCTIONS
// ============================================================

RentalStatus _mapBookingStatus(BookingStatus bs) {
  switch (bs) {
    case BookingStatus.upcoming:
      return RentalStatus.stayUpcoming;
    case BookingStatus.active:
      return RentalStatus.stayActive;
    case BookingStatus.completed:
      return RentalStatus.stayCompleted;
    case BookingStatus.cancelled:
      return RentalStatus.stayCancelled;
  }
}

RentalStatus _mapRequestStatus(String status) {
  switch (status) {
    case 'Pending':
      return RentalStatus.requestPending;
    case 'Approved':
      return RentalStatus.requestApproved;
    case 'Rejected':
      return RentalStatus.requestRejected;
    case 'Withdrawn':
      return RentalStatus.requestWithdrawn;
    default:
      // Fallback so the UI continues to work even for unexpected values.
      return RentalStatus.requestPending;
  }
}
