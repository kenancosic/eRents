import 'package:e_rents_mobile/core/base/base_repository.dart';
import 'package:e_rents_mobile/core/models/booking_model.dart';
import 'package:e_rents_mobile/core/services/booking_service.dart';
import 'package:e_rents_mobile/core/services/cache_manager.dart';

/// Concrete repository for Booking entities
/// Implements BaseRepository pattern with Booking-specific logic and full CRUD operations
class BookingRepository extends BaseRepository<Booking, BookingService> {
  BookingRepository({
    required BookingService service,
    required CacheManager cacheManager,
  }) : super(service: service, cacheManager: cacheManager);

  @override
  String get resourceName => 'bookings';

  @override
  Duration get cacheTtl =>
      const Duration(minutes: 20); // Bookings don't change frequently

  @override
  Future<Booking?> fetchFromService(String id) async {
    final bookingId = int.tryParse(id);
    if (bookingId == null) {
      throw ArgumentError('Invalid booking ID: $id');
    }

    return await service.getBookingDetails(bookingId);
  }

  @override
  Future<List<Booking>> fetchAllFromService(
      [Map<String, dynamic>? params]) async {
    // For now, BookingService only supports getUserBookings
    // In the future, this could support filtering by different parameters
    return await service.getUserBookings();
  }

  @override
  Future<Booking> createInService(Booking item) async {
    // Extract data for the service call
    return await service.createBooking(
      propertyId: item.propertyId,
      startDate: item.startDate,
      endDate: item.endDate,
      totalPrice: item.totalPrice,
      numberOfGuests: item.numberOfGuests,
      specialRequests: item.specialRequests,
      paymentMethod: item.paymentMethod ?? 'PayPal',
    );
  }

  @override
  Future<Booking> updateInService(String id, Booking item) async {
    // BookingService doesn't have update method yet
    // TODO: Implement when BookingService supports update
    throw UnimplementedError(
        'BookingService.updateBooking not yet implemented');
  }

  @override
  Future<bool> deleteInService(String id) async {
    final bookingId = int.tryParse(id);
    if (bookingId == null) {
      throw ArgumentError('Invalid booking ID: $id');
    }

    return await service.cancelBooking(bookingId);
  }

  @override
  Map<String, dynamic> toJson(Booking item) {
    return item.toJson();
  }

  @override
  Booking fromJson(Map<String, dynamic> json) {
    return Booking.fromJson(json);
  }

  @override
  String getItemId(Booking item) {
    return item.bookingId.toString();
  }

  // Booking-specific methods

  /// Get current user's bookings
  Future<List<Booking>> getUserBookings({bool forceRefresh = false}) async {
    return await getAll(null, forceRefresh);
  }

  /// Create a new booking with simplified parameters
  Future<Booking> createBooking({
    required int propertyId,
    required DateTime startDate,
    DateTime? endDate,
    required double totalPrice,
    required int numberOfGuests,
    String? specialRequests,
    String paymentMethod = 'PayPal',
  }) async {
    // Create a temporary booking object for the repository pattern
    final booking = Booking(
      bookingId: 0, // Will be assigned by backend
      propertyId: propertyId,
      userId: 0, // Will be determined by backend from auth token
      propertyName: '', // Will be populated by backend
      startDate: startDate,
      endDate: endDate,
      totalPrice: totalPrice,
      dailyRate: totalPrice / (endDate?.difference(startDate).inDays ?? 1),
      status: BookingStatus.upcoming,
      numberOfGuests: numberOfGuests,
      specialRequests: specialRequests,
      paymentMethod: paymentMethod,
    );

    return await create(booking);
  }

  /// Cancel booking (delete)
  Future<bool> cancelBooking(String bookingId) async {
    return await delete(bookingId);
  }

  /// Get booking details by ID
  Future<Booking?> getBookingDetails(String bookingId,
      {bool forceRefresh = false}) async {
    return await getById(bookingId, forceRefresh: forceRefresh);
  }

  /// Search bookings with filters compatible with backend universal filtering
  Future<List<Booking>> searchBookings({
    int? propertyId,
    int? userId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? paymentMethod,
    String? paymentStatus,
    int? bookingStatusId,
  }) async {
    final searchParams = <String, dynamic>{};

    // Add non-null parameters for backend universal filtering
    if (propertyId != null) searchParams['propertyId'] = propertyId;
    if (userId != null) searchParams['userId'] = userId;
    if (status != null) searchParams['status'] = status;
    if (startDate != null)
      searchParams['startDate'] = startDate.toIso8601String();
    if (endDate != null) searchParams['endDate'] = endDate.toIso8601String();
    if (paymentMethod != null) searchParams['paymentMethod'] = paymentMethod;
    if (paymentStatus != null) searchParams['paymentStatus'] = paymentStatus;
    if (bookingStatusId != null)
      searchParams['bookingStatusId'] = bookingStatusId;

    return await getAll(searchParams);
  }

  /// Get bookings by property
  Future<List<Booking>> getBookingsByProperty(int propertyId) async {
    return await searchBookings(propertyId: propertyId);
  }

  /// Get bookings by status
  Future<List<Booking>> getBookingsByStatus(String status) async {
    return await searchBookings(status: status);
  }

  /// Get upcoming bookings
  Future<List<Booking>> getUpcomingBookings() async {
    final now = DateTime.now();
    return await searchBookings(startDate: now);
  }

  /// Get current active bookings
  Future<List<Booking>> getCurrentBookings() async {
    return await searchBookings(status: 'confirmed');
  }
}
