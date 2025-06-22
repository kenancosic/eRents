import 'package:e_rents_desktop/base/detail_provider.dart';
import 'package:e_rents_desktop/models/booking.dart';
import 'package:e_rents_desktop/repositories/booking_repository.dart';

class BookingDetailProvider extends DetailProvider<Booking> {
  BookingDetailProvider(super.repository);

  BookingRepository get bookingRepository => repository as BookingRepository;

  Booking? get booking => item;

  bool get isActive => booking?.isActive ?? false;

  bool get isCanceled => booking?.isCancelled ?? false;

  bool get isCompleted => booking?.isCompleted ?? false;

  bool get isUpcoming => booking?.isUpcoming ?? false;
}
