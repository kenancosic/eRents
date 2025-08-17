/// Rental request status enum mirroring backend RentalRequestStatusEnum
enum RentalRequestStatus {
  pending(0, 'Pending'),
  approved(1, 'Approved'),
  rejected(2, 'Rejected'),
  cancelled(3, 'Cancelled');

  const RentalRequestStatus(this.value, this.name);

  final int value;
  final String name;

  static RentalRequestStatus fromValue(int value) {
    return RentalRequestStatus.values.firstWhere((e) => e.value == value);
  }

  static RentalRequestStatus fromString(String name) {
    return RentalRequestStatus.values.firstWhere((e) => e.name == name);
  }

  @override
  String toString() => name;
}