/// Rental status covering both short-term stays and long-term lease requests.
///
/// This unified enum is **frontend-only**.  It does **not** affect the backend
/// payload; it is simply a type-safe replacement for the mixed string status
/// values ("active", "Pending", …) previously used in the UI.
///
/// Naming convention:
/// – stay*    → short-term booking (daily stay)
/// – request* → long-term lease request  (awaiting approval)
/// – contract*→ approved lease that has started
///
/// When adding new values remember to update [displayName].
///
/// Example usage:
/// ```dart
/// final s = RentalStatusExtension.fromLegacyString('active');
/// print(s.displayName); // → "Active"
/// ```
///
/// Author: eRents Desktop refactor (Dual rental unification) 2025-06-12
///
/// NOTE:  We intentionally keep the legacy <String status> field in
/// [RentalDisplayItem] to avoid a large mechanical refactor right now.  New
/// code should prefer the strongly-typed [RentalStatus] API.
///
/// See also: docs/eRents_Dual_Rental_Status.md

// ... existing code ...
enum RentalStatus {
  // ===== Short-term stays (Booking) =====
  stayUpcoming,
  stayActive,
  stayConfirmed,
  stayCompleted,
  stayCancelled,

  // ===== Long-term lease requests (RentalRequest) =====
  requestPending,
  requestApproved,
  requestRejected,
  requestWithdrawn,

  // ===== Active contracts (after approval) =====
  contractActive,
  contractExpiring,
  contractExpired,
}

extension RentalStatusExtension on RentalStatus {
  /// Human-readable label shown in the table/status chip.
  String get displayName {
    switch (this) {
      // ==== Stay ====
      case RentalStatus.stayUpcoming:
        return 'Upcoming';
      case RentalStatus.stayActive:
        return 'Active';
      case RentalStatus.stayConfirmed:
        return 'Confirmed';
      case RentalStatus.stayCompleted:
        return 'Completed';
      case RentalStatus.stayCancelled:
        return 'Cancelled';

      // ==== Lease request ====
      case RentalStatus.requestPending:
        return 'Pending';
      case RentalStatus.requestApproved:
        return 'Approved';
      case RentalStatus.requestRejected:
        return 'Rejected';
      case RentalStatus.requestWithdrawn:
        return 'Withdrawn';

      // ==== Contract ====
      case RentalStatus.contractActive:
        return 'Active Contract';
      case RentalStatus.contractExpiring:
        return 'Expiring Contract';
      case RentalStatus.contractExpired:
        return 'Expired Contract';
    }
  }

  /// Maps legacy backend/UI string statuses to [RentalStatus].  The mapping is
  /// **lossy** in the sense that unknown input returns *null*.
  static RentalStatus? fromLegacyString(String value) {
    switch (value.toLowerCase()) {
      // ==== Stay ====
      case 'upcoming':
        return RentalStatus.stayUpcoming;
      case 'active':
        return RentalStatus.stayActive;
      case 'confirmed':
        return RentalStatus.stayConfirmed;
      case 'completed':
        return RentalStatus.stayCompleted;
      case 'cancelled':
        return RentalStatus.stayCancelled;

      // ==== Lease request ====
      case 'pending':
        return RentalStatus.requestPending;
      case 'approved':
        return RentalStatus.requestApproved;
      case 'rejected':
        return RentalStatus.requestRejected;
      case 'withdrawn':
        return RentalStatus.requestWithdrawn;

      // ==== Contract ====
      case 'contractactive':
      case 'activecontract':
        return RentalStatus.contractActive;
      case 'contractexpiring':
      case 'expiringcontract':
        return RentalStatus.contractExpiring;
      case 'contractexpired':
      case 'expiredcontract':
        return RentalStatus.contractExpired;

      default:
        return null; // Unknown / future statuses
    }
  }
}
