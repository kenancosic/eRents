import 'package:e_rents_desktop/models/booking.dart';
import 'package:e_rents_desktop/models/paged_result.dart';
import 'package:e_rents_desktop/models/rental_request.dart';
import 'package:e_rents_desktop/models/rental_display_item.dart';
import 'package:e_rents_desktop/models/rental_statistics.dart';
import 'package:e_rents_desktop/repositories/booking_repository.dart';
import 'package:e_rents_desktop/repositories/rental_request_repository.dart';
import 'package:e_rents_desktop/base/app_error.dart';
import 'package:e_rents_desktop/widgets/table/core/table_query.dart'
    hide PagedResult;
import 'package:e_rents_desktop/models/rental_status.dart';

/// Central service that orchestrates both booking and rental request data sources
/// This is the key component that unifies the dual rental system in the frontend
class RentalManagementService {
  final BookingRepository _bookingRepository;
  final RentalRequestRepository _rentalRequestRepository;

  RentalManagementService(
    this._bookingRepository,
    this._rentalRequestRepository,
  );

  // ===================================================================
  // PAGINATED DATA FETCHING FOR TABLES
  // ===================================================================

  Future<PagedResult<Booking>> getPaginatedStays(
    Map<String, dynamic> params,
  ) async {
    try {
      return await _bookingRepository.fetchPagedFromService(params);
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  Future<PagedResult<RentalRequest>> getPaginatedLeases(
    Map<String, dynamic> params,
  ) async {
    try {
      return await _rentalRequestRepository.fetchPagedFromService(params);
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  // ===================================================================
  // COMBINED DATA FETCHING
  // ===================================================================

  /// Get all rentals without pagination (for exports, reports, etc.)
  Future<List<RentalDisplayItem>> getAllCombinedRentals([
    Map<String, dynamic>? filters,
  ]) async {
    try {
      // Use noPaging=true for complete datasets
      final params = <String, dynamic>{'noPaging': 'true', ...?filters};

      // Fetch from both services in parallel
      final results = await Future.wait([
        _bookingRepository.fetchAllFromService(params),
        _rentalRequestRepository.fetchAllFromService(params),
      ]);

      final List<Booking> bookings =
          (results[0] as List<dynamic>).cast<Booking>();
      final List<RentalRequest> requests =
          (results[1] as List<dynamic>).cast<RentalRequest>();

      // Convert to unified display model
      final List<RentalDisplayItem> unifiedItems = [];
      for (final b in bookings) {
        unifiedItems.add(RentalDisplayItem.fromBooking(b));
      }
      for (final r in requests) {
        unifiedItems.add(RentalDisplayItem.fromRentalRequest(r));
      }

      // Apply unified sorting and filtering
      return _applyUnifiedFilters(unifiedItems, filters);
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  // ===================================================================
  // TYPE-SPECIFIC ACTIONS (Route to Correct Services)
  // ===================================================================

  /// Cancel a stay (booking)
  Future<void> cancelStay(
    String id,
    String reason, {
    bool requestRefund = true,
  }) async {
    try {
      await _bookingRepository.cancelBooking(
        int.parse(id),
        reason,
        requestRefund,
      );
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Approve a lease request
  Future<void> approveLeaseRequest(String id, String response) async {
    try {
      await _rentalRequestRepository.approveRentalRequest(
        int.parse(id),
        true,
        response,
      );
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Reject a lease request
  Future<void> rejectLeaseRequest(String id, String reason) async {
    try {
      await _rentalRequestRepository.approveRentalRequest(
        int.parse(id),
        false,
        reason,
      );
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Withdraw a lease request
  Future<void> withdrawLeaseRequest(String id) async {
    try {
      await _rentalRequestRepository.withdrawRentalRequest(int.parse(id));
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  // ===================================================================
  // SPECIALIZED QUERIES
  // ===================================================================

  /// Get active stays only
  Future<List<RentalDisplayItem>> getActiveStays([int? propertyId]) async {
    try {
      final bookings = await _bookingRepository.getCurrentStays(propertyId);
      return bookings.map((b) => RentalDisplayItem.fromBooking(b)).toList();
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Get pending lease requests only
  Future<List<RentalDisplayItem>> getPendingLeaseRequests() async {
    try {
      final requests = await _rentalRequestRepository.getPendingRequests();
      return requests
          .map((r) => RentalDisplayItem.fromRentalRequest(r))
          .toList();
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Get upcoming stays only
  Future<List<RentalDisplayItem>> getUpcomingStays([int? propertyId]) async {
    try {
      final bookings = await _bookingRepository.getUpcomingStays(propertyId);
      return bookings.map((b) => RentalDisplayItem.fromBooking(b)).toList();
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Get expiring lease contracts
  Future<List<RentalDisplayItem>> getExpiringLeases({int? daysAhead}) async {
    try {
      final requests = await _rentalRequestRepository.getExpiringContracts(
        daysAhead: daysAhead,
      );
      return requests
          .map((r) => RentalDisplayItem.fromRentalRequest(r))
          .toList();
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  // ===================================================================
  // UNIFIED STATISTICS
  // ===================================================================

  /// Get combined rental statistics
  Future<RentalStatistics> getUnifiedStatistics() async {
    try {
      // Fetch statistics from both repositories in parallel
      final results = await Future.wait([
        _getBookingStatistics(),
        _rentalRequestRepository.getRentalRequestStatistics(),
      ]);

      final bookingStats = results[0];
      final rentalRequestStats = results[1];

      return RentalStatistics.combine(bookingStats, rentalRequestStats);
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  /// Get booking statistics (helper method)
  Future<Map<String, dynamic>> _getBookingStatistics() async {
    try {
      // Since BookingRepository doesn't have a statistics method yet,
      // we'll calculate basic statistics from the data
      final allBookings = await _bookingRepository.getAll();

      final totalBookings = allBookings.length;
      final activeBookings =
          allBookings.where((b) => b.status == BookingStatus.active).length;
      final upcomingBookings =
          allBookings.where((b) => b.status == BookingStatus.upcoming).length;
      final completedBookings =
          allBookings.where((b) => b.status == BookingStatus.completed).length;
      final cancelledBookings =
          allBookings.where((b) => b.status == BookingStatus.cancelled).length;
      final totalRevenue = allBookings.fold<double>(
        0,
        (sum, booking) => sum + booking.totalPrice,
      );

      return {
        'totalBookings': totalBookings,
        'activeBookings': activeBookings,
        'upcomingBookings': upcomingBookings,
        'completedBookings': completedBookings,
        'cancelledBookings': cancelledBookings,
        'totalRevenue': totalRevenue,
      };
    } catch (e, stackTrace) {
      throw AppError.fromException(e, stackTrace);
    }
  }

  // ===================================================================
  // CACHE MANAGEMENT
  // ===================================================================

  /// Clear all caches for both data sources
  Future<void> clearAllCaches() async {
    await Future.wait([
      _bookingRepository.clearCache(),
      _rentalRequestRepository.clearCache(),
    ]);
  }

  /// Refresh all data from both sources
  Future<void> refreshAllData() async {
    await clearAllCaches();
  }

  // ===================================================================
  // PRIVATE HELPER METHODS
  // ===================================================================

  /// Apply unified filters across both rental types
  List<RentalDisplayItem> _applyUnifiedFilters(
    List<RentalDisplayItem> items,
    Map<String, dynamic>? filters,
  ) {
    if (filters == null || filters.isEmpty) {
      return items;
    }

    return items.where((item) {
      // Filter by rental type (stay vs lease)
      if (filters.containsKey('rentalType')) {
        final filterType = filters['rentalType'] as String?;
        if (filterType != null && filterType.isNotEmpty) {
          final matchesType = switch (filterType) {
            'stay' => item.isStay,
            'lease' => item.isLease,
            _ => true, // Show all if unrecognized type
          };
          if (!matchesType) return false;
        }
      }

      // Filter by status
      if (filters.containsKey('status')) {
        final filterStatus = filters['status'] as String?;
        if (filterStatus != null && filterStatus.isNotEmpty) {
          final statusString = item.rentalStatus.displayName.toLowerCase();
          if (!statusString.contains(filterStatus.toLowerCase())) {
            return false;
          }
        }
      }

      // Filter by property name
      if (filters.containsKey('propertyName')) {
        final filterProperty = filters['propertyName'] as String?;
        if (filterProperty != null && filterProperty.isNotEmpty) {
          final propertyName = item.propertyName?.toLowerCase() ?? '';
          if (!propertyName.contains(filterProperty.toLowerCase())) {
            return false;
          }
        }
      }

      // Filter by user name
      if (filters.containsKey('userName')) {
        final filterUser = filters['userName'] as String?;
        if (filterUser != null && filterUser.isNotEmpty) {
          final userName = item.userName?.toLowerCase() ?? '';
          if (!userName.contains(filterUser.toLowerCase())) {
            return false;
          }
        }
      }

      return true;
    }).toList();
  }

  /// Apply unified sorting across both rental types
  List<RentalDisplayItem> _applyUnifiedSorting(
    List<RentalDisplayItem> items,
    String? sortBy,
    bool sortDesc,
  ) {
    if (sortBy == null || sortBy.isEmpty) {
      // Default sort by start date descending (newest first)
      items.sort((a, b) => b.startDate.compareTo(a.startDate));
      return items;
    }

    items.sort((a, b) {
      int comparison = 0;

      switch (sortBy.toLowerCase()) {
        case 'startdate':
          comparison = a.startDate.compareTo(b.startDate);
          break;
        case 'enddate':
          final aEnd = a.endDate ?? DateTime.now();
          final bEnd = b.endDate ?? DateTime.now();
          comparison = aEnd.compareTo(bEnd);
          break;
        case 'amount':
          comparison = a.amount.compareTo(b.amount);
          break;
        case 'status':
          comparison = a.status.compareTo(b.status);
          break;
        case 'category':
          comparison = a.category.displayName.compareTo(b.category.displayName);
          break;
        case 'propertyname':
          final aProp = a.propertyName ?? '';
          final bProp = b.propertyName ?? '';
          comparison = aProp.compareTo(bProp);
          break;
        case 'username':
          final aUser = a.userName ?? '';
          final bUser = b.userName ?? '';
          comparison = aUser.compareTo(bUser);
          break;
        default:
          // Default to start date
          comparison = a.startDate.compareTo(b.startDate);
      }

      return sortDesc ? -comparison : comparison;
    });

    return items;
  }
}
