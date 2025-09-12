import 'package:e_rents_mobile/core/enums/property_enums.dart';
import 'package:e_rents_mobile/core/models/property_detail.dart';

/// Builds the navigation payload for the checkout route, unifying
/// how start/end dates and total price are computed for both
/// daily and monthly rentals.
Map<String, dynamic> buildCheckoutPayload(
  PropertyDetail property, {
  DateTime? startDate,
  DateTime? endDate,
  int? months,
}) {
  final now = DateTime.now();
  final s = startDate ?? DateTime(now.year, now.month, now.day + 1);
  final isDaily = property.rentalType == PropertyRentalType.daily;

  late DateTime e;
  late double total;

  if (isDaily) {
    e = endDate ?? s.add(const Duration(days: 7));
    final nights = e.difference(s).inDays;
    final unitPrice = property.dailyRate ?? property.price;
    total = (nights > 0 ? nights : 0) * unitPrice;
  } else {
    final minimumStayDays = property.minimumStayDays ?? 30;
    final minMonths = (minimumStayDays / 30).ceil();
    final m = (months != null && months >= minMonths) ? months : minMonths;
    e = endDate ?? s.add(Duration(days: 30 * m));
    // Align with backend subscription model: charge only first month now.
    total = property.price;
  }

  return {
    'property': property,
    'startDate': s,
    'endDate': e,
    'isDailyRental': isDaily,
    'totalPrice': total,
  };
}
