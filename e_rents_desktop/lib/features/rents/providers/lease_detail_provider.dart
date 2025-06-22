import 'package:e_rents_desktop/base/detail_provider.dart';
import 'package:e_rents_desktop/models/rental_request.dart';
import 'package:e_rents_desktop/repositories/rental_request_repository.dart';

class LeaseDetailProvider extends DetailProvider<RentalRequest> {
  LeaseDetailProvider(super.repository);

  RentalRequestRepository get rentalRequestRepository =>
      repository as RentalRequestRepository;

  RentalRequest? get lease => item;

  bool get isPending => lease?.isPending ?? false;
  bool get isApproved => lease?.isApproved ?? false;
  bool get isRejected => lease?.isRejected ?? false;
}
