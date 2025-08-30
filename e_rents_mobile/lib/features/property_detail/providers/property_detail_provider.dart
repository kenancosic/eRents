import 'dart:convert';
import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/base/app_error.dart';
import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/core/models/review.dart';
import 'package:e_rents_mobile/core/models/booking_model.dart';
import 'package:e_rents_mobile/core/models/maintenance_issue.dart';
import 'package:e_rents_mobile/core/models/lease_extension_request.dart';

/// Consolidated PropertyDetailProvider following the new single-provider pattern
/// Refactored to use new standardized BaseProvider without caching
/// Uses proper state management with loading, success, and error states
class PropertyDetailProvider extends BaseProvider {
  PropertyDetailProvider(super.api);

  // ─── Property State ─────────────────────────────────────────────
  Property? _property;
  Property? get property => _property;

  List<Property> _similarProperties = [];
  List<Property> get similarProperties => _similarProperties;

  List<Property> _ownerProperties = [];
  List<Property> get ownerProperties => _ownerProperties;

  List<Property> _propertyCollection = [];
  List<Property> get propertyCollection => _propertyCollection;

  // Collection search/filter state
  String _propertySearchQuery = '';
  String get propertySearchQuery => _propertySearchQuery;
  
  Map<String, dynamic> _propertyFilters = {};
  Map<String, dynamic> get propertyFilters => _propertyFilters;

  // ─── Reviews State ──────────────────────────────────────────────
  List<Review> _reviews = [];
  List<Review> get reviews => _reviews;

  List<Review> _allReviews = [];
  List<Review> get allReviews => _allReviews;

  String _reviewSearchQuery = '';
  String get reviewSearchQuery => _reviewSearchQuery;
  
  Map<String, dynamic> _reviewFilters = {};
  Map<String, dynamic> get reviewFilters => _reviewFilters;

  // ─── Maintenance State ──────────────────────────────────────────
  List<MaintenanceIssue> _maintenanceIssues = [];
  List<MaintenanceIssue> get maintenanceIssues => _maintenanceIssues;

  List<MaintenanceIssue> _allMaintenanceIssues = [];
  List<MaintenanceIssue> get allMaintenanceIssues => _allMaintenanceIssues;

  String _maintenanceSearchQuery = '';
  String get maintenanceSearchQuery => _maintenanceSearchQuery;
  
  Map<String, dynamic> _maintenanceFilters = {};
  Map<String, dynamic> get maintenanceFilters => _maintenanceFilters;

  // ─── Booking State ──────────────────────────────────────────────
  Booking? _booking;
  Booking? get booking => _booking;

  // ─── Lease State ────────────────────────────────────────────────
  List<LeaseExtensionRequest> _leaseExtensionRequests = [];
  List<LeaseExtensionRequest> get leaseExtensionRequests => _leaseExtensionRequests;

  // ─── Pricing State ──────────────────────────────────────────────
  Map<String, dynamic>? _currentPricing;
  Map<String, dynamic>? get currentPricing => _currentPricing;
  
  double? _currentPricingEstimate;
  double? get currentPricingEstimate => _currentPricingEstimate;

  // ─── Availability State ──────────────────────────────────────────
  Map<DateTime, bool> _propertyAvailability = {};
  Map<DateTime, bool> get propertyAvailability => _propertyAvailability;

  // ─── Main Property Operations ───────────────────────────────────

  /// Fetch property details and related data
  Future<void> fetchPropertyDetails(String propertyId, {String? bookingId, bool forceRefresh = false}) async {
    final property = await executeWithState(() async {
      final response = await api.get('/properties/$propertyId', authenticated: true);
      return Property.fromJson(jsonDecode(response.body));
    });

    if (property != null) {
      _property = property;
      
      // Fetch related data in parallel
      await Future.wait([
        fetchReviews(propertyId, forceRefresh: forceRefresh),
        fetchMaintenanceIssues(propertyId, forceRefresh: forceRefresh),
        fetchSimilarProperties(forceRefresh: forceRefresh),
        fetchOwnerProperties(forceRefresh: forceRefresh),
        if (bookingId != null) fetchBookingDetails(bookingId),
      ]);
    }
  }

  /// Fetch similar properties based on current property
  Future<void> fetchSimilarProperties({bool forceRefresh = false}) async {
    if (_property == null) return;
    
    final properties = await executeWithState(() async {
      final response = await api.get('/properties/search', customHeaders: {
        'propertyTypeId': _property!.propertyTypeId.toString(),
        'minPrice': (_property!.price * 0.8).toString(),
        'maxPrice': (_property!.price * 1.2).toString(),
        'exclude': _property!.propertyId.toString(),
      }, authenticated: true);
      final data = jsonDecode(response.body)['items'] as List;
      return data.map((p) => Property.fromJson(p)).toList();
    });

    if (properties != null) {
      _similarProperties = properties;
    }
  }

  /// Fetch properties by current property owner
  Future<void> fetchOwnerProperties({bool forceRefresh = false}) async {
    if (_property?.ownerId == null) return;
    
    final properties = await executeWithState(() async {
      final response = await api.get('/properties/search', customHeaders: {
        'ownerId': _property!.ownerId.toString(),
        'exclude': _property!.propertyId.toString(),
      }, authenticated: true);
      final data = jsonDecode(response.body)['items'] as List;
      return data.map((p) => Property.fromJson(p)).toList();
    });

    if (properties != null) {
      _ownerProperties = properties;
    }
  }

  /// Fetch booking details
  Future<void> fetchBookingDetails(String bookingId) async {
    final booking = await executeWithState(() async {
      final response = await api.get('/bookings/$bookingId', authenticated: true);
      return Booking.fromJson(jsonDecode(response.body));
    });

    if (booking != null) {
      _booking = booking;
    }
  }

  // ─── Property Collection Operations ──────────────────────────────

  /// Load property collection with optional filters
  Future<void> loadPropertyCollection({Map<String, dynamic>? filters, bool forceRefresh = false}) async {
    final properties = await executeWithState(() async {
      final response = await api.get('/properties/search', customHeaders: filters?.map((key, value) => MapEntry(key, value.toString())), authenticated: true);
      final data = jsonDecode(response.body)['items'] as List;
      return data.map((p) => Property.fromJson(p)).toList();
    });

    if (properties != null) {
      _propertyCollection = properties;
      _applyPropertySearchAndFilters();
    }
  }

  /// Search properties
  void searchProperties(String query) {
    _propertySearchQuery = query;
    _applyPropertySearchAndFilters();
  }

  /// Apply filters to property collection
  void applyPropertyFilters(Map<String, dynamic> filters) {
    _propertyFilters = Map.from(filters);
    _applyPropertySearchAndFilters();
  }

  /// Clear property search and filters
  void clearPropertySearchAndFilters() {
    _propertySearchQuery = '';
    _propertyFilters.clear();
    _applyPropertySearchAndFilters();
  }

  void _applyPropertySearchAndFilters() {
    // Property search and filtering logic is handled server-side via API
    // This method exists for consistency with other collection methods
    notifyListeners();
  }

  // ─── Review Operations ──────────────────────────────────────────

  /// Fetch reviews for a property
  Future<void> fetchReviews(String propertyId, {bool forceRefresh = false}) async {
    final reviews = await executeWithState(() async {
      final response = await api.get('/reviews/property/$propertyId', authenticated: true);
      final data = jsonDecode(response.body) as List;
      return data.map((r) => Review.fromJson(r)).toList();
    });

    if (reviews != null) {
      _allReviews = reviews;
      _reviews = List.from(_allReviews);
      _applyReviewSearchAndFilters();
    }
  }

  /// Add a new review
  Future<bool> addReview(String propertyId, String comment, double rating) async {
    final success = await executeWithStateForSuccess(() async {
      final response = await api.post('/reviews', {'propertyId': propertyId, 'comment': comment, 'rating': rating}, authenticated: true);
      final newReview = Review.fromJson(jsonDecode(response.body));
      _allReviews.insert(0, newReview);
      _applyReviewSearchAndFilters();
      
      // Optionally, refetch property to update average rating
      final propResponse = await api.get('/properties/$propertyId', authenticated: true);
      _property = Property.fromJson(jsonDecode(propResponse.body));
    }, errorMessage: 'Failed to add review');

    return success;
  }

  /// Search reviews
  void searchReviews(String query) {
    _reviewSearchQuery = query;
    _applyReviewSearchAndFilters();
  }

  /// Apply filters to reviews
  void applyReviewFilters(Map<String, dynamic> filters) {
    _reviewFilters = Map.from(filters);
    _applyReviewSearchAndFilters();
  }

  /// Clear review search and filters
  void clearReviewSearchAndFilters() {
    _reviewSearchQuery = '';
    _reviewFilters.clear();
    _reviews = List.from(_allReviews);
    notifyListeners();
  }

  void _applyReviewSearchAndFilters() {
    _reviews = _allReviews.where((review) {
      // Apply search filter
      if (_reviewSearchQuery.isNotEmpty) {
        final query = _reviewSearchQuery.toLowerCase();
        if (!(review.description?.toLowerCase().contains(query) ?? false) &&
            !review.reviewTypeDisplay.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Apply other filters
      return _matchesReviewFilters(review, _reviewFilters);
    }).toList();
    
    notifyListeners();
  }

  bool _matchesReviewFilters(Review review, Map<String, dynamic> filters) {
    // Rating range filters
    if (filters.containsKey('minRating')) {
      final minRating = filters['minRating'] as double?;
      if (minRating != null && (review.starRating == null || review.starRating! < minRating)) {
        return false;
      }
    }
    
    if (filters.containsKey('maxRating')) {
      final maxRating = filters['maxRating'] as double?;
      if (maxRating != null && (review.starRating == null || review.starRating! > maxRating)) {
        return false;
      }
    }

    // Review type filter
    if (filters.containsKey('reviewType')) {
      final reviewType = filters['reviewType'] as ReviewType?;
      if (reviewType != null && review.reviewType != reviewType) return false;
    }

    // Verified filter
    if (filters.containsKey('isVerified')) {
      final isVerified = filters['isVerified'] as bool?;
      if (isVerified != null && review.isVerified != isVerified) return false;
    }

    return true;
  }

  // ─── Maintenance Operations ─────────────────────────────────────

  /// Fetch maintenance issues for a property
  Future<void> fetchMaintenanceIssues(String propertyId, {bool forceRefresh = false}) async {
    final issues = await executeWithState(() async {
      final response = await api.get('/maintenance/property/$propertyId', authenticated: true);
      final data = jsonDecode(response.body) as List;
      return data.map((i) => MaintenanceIssue.fromJson(i)).toList();
    });

    if (issues != null) {
      _allMaintenanceIssues = issues;
      _maintenanceIssues = List.from(_allMaintenanceIssues);
      _applyMaintenanceSearchAndFilters();
    }
  }

  /// Report a new maintenance issue
  Future<bool> reportMaintenanceIssue(String propertyId, String title, String description) async {
    final success = await executeWithStateForSuccess(() async {
      final response = await api.post('/maintenance', {'propertyId': propertyId, 'title': title, 'description': description}, authenticated: true);
      final newIssue = MaintenanceIssue.fromJson(jsonDecode(response.body));
      _allMaintenanceIssues.insert(0, newIssue);
      _applyMaintenanceSearchAndFilters();
    }, errorMessage: 'Failed to report issue');

    return success;
  }

  /// Update maintenance issue status
  Future<bool> updateMaintenanceIssueStatus(String issueId, MaintenanceIssueStatus newStatus) async {
    final success = await executeWithStateForSuccess(() async {
      // Use existing API method to update the issue
      final response = await api.put('/maintenance/$issueId', {
        'status': newStatus.toString().split('.').last,
        'statusId': _getStatusId(newStatus),
      }, authenticated: true);
      final updatedIssue = MaintenanceIssue.fromJson(jsonDecode(response.body));
      final index = _allMaintenanceIssues.indexWhere((issue) => issue.maintenanceIssueId.toString() == issueId);
      if (index != -1) {
        _allMaintenanceIssues[index] = updatedIssue;
        _applyMaintenanceSearchAndFilters();
      }
    }, errorMessage: 'Failed to update maintenance issue');

    return success;
  }

  int _getStatusId(MaintenanceIssueStatus status) {
    switch (status) {
      case MaintenanceIssueStatus.pending:
        return 1;
      case MaintenanceIssueStatus.inProgress:
        return 2;
      case MaintenanceIssueStatus.completed:
        return 3;
      case MaintenanceIssueStatus.cancelled:
        return 4;
    }
  }

  /// Search maintenance issues
  void searchMaintenanceIssues(String query) {
    _maintenanceSearchQuery = query;
    _applyMaintenanceSearchAndFilters();
  }

  /// Apply filters to maintenance issues
  void applyMaintenanceFilters(Map<String, dynamic> filters) {
    _maintenanceFilters = Map.from(filters);
    _applyMaintenanceSearchAndFilters();
  }

  /// Clear maintenance search and filters
  void clearMaintenanceSearchAndFilters() {
    _maintenanceSearchQuery = '';
    _maintenanceFilters.clear();
    _maintenanceIssues = List.from(_allMaintenanceIssues);
    notifyListeners();
  }

  void _applyMaintenanceSearchAndFilters() {
    _maintenanceIssues = _allMaintenanceIssues.where((issue) {
      // Apply search filter
      if (_maintenanceSearchQuery.isNotEmpty) {
        final query = _maintenanceSearchQuery.toLowerCase();
        if (!issue.title.toLowerCase().contains(query) &&
            !issue.description.toLowerCase().contains(query) &&
            !(issue.category?.toLowerCase().contains(query) ?? false)) {
          return false;
        }
      }

      // Apply other filters
      return _matchesMaintenanceFilters(issue, _maintenanceFilters);
    }).toList();
    
    notifyListeners();
  }

  bool _matchesMaintenanceFilters(MaintenanceIssue issue, Map<String, dynamic> filters) {
    // Status filter
    if (filters.containsKey('status')) {
      final status = filters['status'] as MaintenanceIssueStatus?;
      if (status != null && issue.status != status) return false;
    }

    // Priority filter
    if (filters.containsKey('priority')) {
      final priority = filters['priority'] as MaintenanceIssuePriority?;
      if (priority != null && issue.priority != priority) return false;
    }

    // Category filter
    if (filters.containsKey('category')) {
      final category = filters['category'] as String?;
      if (category != null && issue.category != category) return false;
    }

    return true;
  }

  // ─── Lease Management Methods ───────────────────────────────────

  /// Submit a lease extension request
  Future<bool> requestLeaseExtension(LeaseExtensionRequest request) async {
    final success = await executeWithStateForSuccess(() async {
      final response = await api.post(
        '/lease-extensions',
        request.toJson(),
        authenticated: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Refresh lease extension requests after successful submission
        await getLeaseExtensionRequests(request.tenantId);
      } else {
        throw Exception('Failed to request extension: ${response.statusCode} ${response.body}');
      }
    }, errorMessage: 'Failed to request lease extension');

    return success;
  }

  /// Get lease extension requests for a tenant
  Future<void> getLeaseExtensionRequests(int tenantId) async {
    await executeWithState(() async {
      await Future.delayed(const Duration(milliseconds: 800));

      // Mock data - replace with real API call
      _leaseExtensionRequests = [
        LeaseExtensionRequest(
          requestId: 1,
          bookingId: 201,
          propertyId: _property?.propertyId ?? 101,
          tenantId: tenantId,
          newEndDate: null, // Request for indefinite extension
          newMinimumStayEndDate: DateTime.now().add(const Duration(days: 90)),
          reason: 'Would like to extend my stay for at least 3 more months',
          status: LeaseExtensionStatus.pending,
          dateRequested: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];
      
      /* Real API call:
      final response = await api.get(
        '/leases/extension-requests/tenant/$tenantId',
        authenticated: true,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _leaseExtensionRequests = data.map((json) => LeaseExtensionRequest.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load lease extension requests');
      }
      */
      
      notifyListeners();
    });
  }

  /// Cancel a booking
  Future<bool> cancelBooking(int bookingId, String reason) async {
    final success = await executeWithStateForSuccess(() async {
      await Future.delayed(const Duration(milliseconds: 1500));

      // In a real app, this would:
      // 1. Update booking status to cancelled
      // 2. Process any refunds according to cancellation policy
      // 3. Send notification to landlord

      /* Real API call:
      final response = await api.put(
        '/bookings/$bookingId/cancel',
        {'reason': reason},
        authenticated: true,
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to cancel booking');
      }
      */

      return; // Mock success
    }, errorMessage: 'Error cancelling booking');

    return success;
  }

  /// Get booking details with calendar information
  Future<Booking?> getBookingDetails(int bookingId) async {
    return await executeWithState<Booking?>(() async {
      await Future.delayed(const Duration(milliseconds: 500));

      // Mock implementation - would fetch from API
      return null;

      /* Real API call:
      final response = await api.get(
        '/bookings/$bookingId',
        authenticated: true,
      );
      
      if (response.statusCode == 200) {
        return Booking.fromJson(jsonDecode(response.body));
      }
      return null;
      */
    });
  }

  // ─── Pricing Methods ────────────────────────────────────────────

  /// Get pricing from backend for a date range with detailed breakdown
  Future<Map<String, dynamic>?> getPricing({
    required int propertyId,
    required DateTime startDate,
    required DateTime endDate,
    required int numberOfGuests,
    String? promoCode,
    bool? isDailyRental,
  }) async {
    final requestData = {
      'propertyId': propertyId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'numberOfGuests': numberOfGuests,
      if (promoCode != null) 'promoCode': promoCode,
      if (isDailyRental != null) 'isDailyRental': isDailyRental,
    };

    final pricing = await executeWithState(() async {
      final response = await api.post(
        '/pricing/calculate',
        requestData,
        authenticated: true,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get pricing: ${response.statusCode} ${response.body}');
      }
    });

    if (pricing != null) {
      _currentPricing = pricing;
      notifyListeners();
      return _currentPricing;
    }

    return null;
  }

  /// Validate pricing parameters before making backend call
  Future<Map<String, dynamic>?> getPricingWithValidation({
    required int propertyId,
    required DateTime startDate,
    required DateTime endDate,
    required int numberOfGuests,
    String? promoCode,
    bool? isDailyRental,
  }) async {
    // Client-side validation only
    final duration = endDate.difference(startDate).inDays;
    if (duration <= 0) {
      setError(ValidationError(message: 'Invalid date range - end date must be after start date'));
      return null;
    }

    if (numberOfGuests <= 0) {
      setError(ValidationError(message: 'Invalid guest count - must be greater than 0'));
      return null;
    }

    // Call backend for actual pricing calculation
    return await getPricing(
      propertyId: propertyId,
      startDate: startDate,
      endDate: endDate,
      numberOfGuests: numberOfGuests,
      promoCode: promoCode,
      isDailyRental: isDailyRental,
    );
  }

  /// Get pricing estimate (for quick UI updates, less detailed)
  Future<double?> getPricingEstimate({
    required int propertyId,
    required DateTime startDate,
    required DateTime endDate,
    required int numberOfGuests,
  }) async {
    final requestData = {
      'propertyId': propertyId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'numberOfGuests': numberOfGuests,
    };

    final estimate = await executeWithState(() async {
      final response = await api.post(
        '/pricing/estimate',
        requestData,
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['estimatedTotal'] as num?)?.toDouble();
      } else {
        throw Exception('Failed to get estimate: ${response.statusCode}');
      }
    });

    if (estimate != null) {
      _currentPricingEstimate = estimate;
      notifyListeners();
      return _currentPricingEstimate;
    }

    return null;
  }

  /// Format pricing for display (formatting only, no calculations)
  String formatPricingDisplay(Map<String, dynamic> pricing,
      [String currency = 'BAM']) {
    final total = pricing['total'] as double? ?? 0.0;
    final unitLabel = pricing['unitLabel'] as String? ?? 'units';
    final unitCount = pricing['unitCount'] as int? ?? 1;

    return '$currency ${total.toStringAsFixed(2)} for $unitCount $unitLabel';
  }

  /// Get pricing breakdown for UI display (formatting only)
  List<Map<String, dynamic>> getPricingBreakdown(Map<String, dynamic> pricing) {
    final breakdown = <Map<String, dynamic>>[];

    // Base cost
    final baseRate = pricing['baseRate'] as double? ?? 0.0;
    final unitCount = pricing['unitCount'] as int? ?? 1;
    final unitLabel = pricing['unitLabel'] as String? ?? 'units';
    final subtotal = pricing['subtotal'] as double? ?? 0.0;

    breakdown.add({
      'label': '$baseRate x $unitCount $unitLabel',
      'amount': subtotal,
      'type': 'base',
    });

    // Discount
    final discountAmount = pricing['discountAmount'] as double? ?? 0.0;
    if (discountAmount > 0) {
      breakdown.add({
        'label': pricing['discountLabel'] ?? 'Discount',
        'amount': -discountAmount,
        'type': 'discount',
      });
    }

    // Service fee
    final serviceFee = pricing['serviceFee'] as double? ?? 0.0;
    if (serviceFee > 0) {
      breakdown.add({
        'label': 'Service fee',
        'amount': serviceFee,
        'type': 'fee',
      });
    }

    // Additional fees from backend
    final additionalFees = pricing['additionalFees'] as List<dynamic>? ?? [];
    for (final fee in additionalFees) {
      if (fee is Map<String, dynamic>) {
        breakdown.add({
          'label': fee['label'] ?? 'Additional fee',
          'amount': (fee['amount'] as num?)?.toDouble() ?? 0.0,
          'type': 'fee',
        });
      }
    }

    return breakdown;
  }

  /// Format currency amount for display
  String formatCurrency(double amount, [String currency = 'BAM']) {
    return '$currency ${amount.toStringAsFixed(2)}';
  }

  /// Parse pricing response and extract key values for UI
  Map<String, dynamic> parsePricingForUI(Map<String, dynamic> backendPricing) {
    return {
      'total': (backendPricing['total'] as num?)?.toDouble() ?? 0.0,
      'subtotal': (backendPricing['subtotal'] as num?)?.toDouble() ?? 0.0,
      'discountAmount':
          (backendPricing['discountAmount'] as num?)?.toDouble() ?? 0.0,
      'serviceFee': (backendPricing['serviceFee'] as num?)?.toDouble() ?? 0.0,
      'unitLabel': backendPricing['unitLabel'] as String? ?? 'units',
      'unitCount': backendPricing['unitCount'] as int? ?? 1,
      'hasDiscount':
          (backendPricing['discountAmount'] as num?)?.toDouble() != null &&
              (backendPricing['discountAmount'] as num) > 0,
      'breakdown': getPricingBreakdown(backendPricing),
      'formattedTotal':
          formatCurrency((backendPricing['total'] as num?)?.toDouble() ?? 0.0),
    };
  }

  // ─── Property Availability Methods ──────────────────────────────

  /// Get property availability considering existing bookings
  Future<Map<DateTime, bool>> getPropertyAvailability(
    int propertyId, {
    DateTime? startDate,
    DateTime? endDate,
    List<Booking>? existingBookings,
  }) async {
    final availability = await executeWithState(() async {
      await Future.delayed(const Duration(milliseconds: 600));

      final start = startDate ?? DateTime.now();
      final end = endDate ?? DateTime.now().add(const Duration(days: 90));
      final Map<DateTime, bool> availabilityMap = {};

      // Initialize all dates as available
      for (var i = 0; i <= end.difference(start).inDays; i++) {
        final date = start.add(Duration(days: i));
        final normalizedDate = DateTime(date.year, date.month, date.day);

        // Mark past dates as unavailable
        if (normalizedDate.isBefore(DateTime.now())) {
          availabilityMap[normalizedDate] = false;
          continue;
        }

        availabilityMap[normalizedDate] = true;
      }

      // Block dates based on existing bookings
      if (existingBookings != null) {
        for (final booking in existingBookings) {
          if (booking.propertyId == propertyId &&
              booking.status != BookingStatus.cancelled) {
            _blockBookingDates(availabilityMap, booking);
          }
        }
      }

      // Add some mock maintenance/unavailable periods
      _addMaintenancePeriods(availabilityMap, start, end);

      return availabilityMap;

      /* Real API call would be:
      final response = await api.get(
        '/properties/$propertyId/availability?start=${start.toIso8601String()}&end=${end.toIso8601String()}',
        authenticated: true,
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data.map((key, value) => MapEntry(DateTime.parse(key), value as bool));
      } else {
        throw Exception('Failed to load property availability');
      }
      */
    });

    if (availability != null) {
      _propertyAvailability = availability;
      notifyListeners();
      return availability;
    }

    return <DateTime, bool>{};
  }

  /// Block dates for a specific booking
  void _blockBookingDates(Map<DateTime, bool> availability, Booking booking) {
    final startDate = DateTime(
      booking.startDate.year,
      booking.startDate.month,
      booking.startDate.day,
    );

    DateTime endDate;
    if (booking.endDate != null) {
      endDate = DateTime(
        booking.endDate!.year,
        booking.endDate!.month,
        booking.endDate!.day,
      );
    } else {
      // For indefinite bookings, block for a reasonable period
      endDate = startDate.add(const Duration(days: 365));
    }

    // Block all dates in the booking range
    for (var date = startDate;
        date.isBefore(endDate) || date.isAtSameMomentAs(endDate);
        date = date.add(const Duration(days: 1))) {
      availability[date] = false;
    }
  }

  /// Add mock maintenance periods
  void _addMaintenancePeriods(
      Map<DateTime, bool> availability, DateTime start, DateTime end) {
    // Mock: Block every 30th day for maintenance
    for (var i = 30; i <= end.difference(start).inDays; i += 30) {
      final maintenanceDate = start.add(Duration(days: i));
      final normalizedDate = DateTime(
        maintenanceDate.year,
        maintenanceDate.month,
        maintenanceDate.day,
      );
      availability[normalizedDate] = false;
    }
  }

  /// Check if a date range is available
  bool isDateRangeAvailable(
    Map<DateTime, bool> availability,
    DateTime startDate,
    DateTime endDate,
  ) {
    for (var date = startDate;
        date.isBefore(endDate) || date.isAtSameMomentAs(endDate);
        date = date.add(const Duration(days: 1))) {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      if (!(availability[normalizedDate] ?? false)) {
        return false;
      }
    }
    return true;
  }

  /// Get next available date from a given start date
  DateTime? getNextAvailableDate(
    Map<DateTime, bool> availability,
    DateTime fromDate,
  ) {
    for (var i = 0; i <= 365; i++) {
      final date = fromDate.add(Duration(days: i));
      final normalizedDate = DateTime(date.year, date.month, date.day);
      if (availability[normalizedDate] ?? false) {
        return normalizedDate;
      }
    }
    return null;
  }

  // ─── Convenience Getters ────────────────────────────────────────

  // Property getters
  bool get isAvailable => property?.status == PropertyStatus.available;
  String get title => property?.name ?? 'Unknown Property';
  double get price => property?.price ?? 0.0;
  String get fullAddress => property?.address?.getFullAddress() ?? 'No address';
  double get averageRating => property?.averageRating ?? 0.0;

  // Review getters
  List<Review> get positiveReviews => reviews.where((r) => r.isPositiveReview).toList();
  List<Review> get negativeReviews => reviews.where((r) => r.isNegativeReview).toList();
  double get reviewsAverageRating {
    if (reviews.isEmpty) return 0.0;
    final ratingsOnly = reviews.where((r) => r.starRating != null).map((r) => r.starRating!).toList();
    if (ratingsOnly.isEmpty) return 0.0;
    return ratingsOnly.reduce((a, b) => a + b) / ratingsOnly.length;
  }

  // Maintenance getters
  List<MaintenanceIssue> get pendingIssues => maintenanceIssues.where((i) => i.status == MaintenanceIssueStatus.pending).toList();
  List<MaintenanceIssue> get inProgressIssues => maintenanceIssues.where((i) => i.status == MaintenanceIssueStatus.inProgress).toList();
  List<MaintenanceIssue> get completedIssues => maintenanceIssues.where((i) => i.status == MaintenanceIssueStatus.completed).toList();
  List<MaintenanceIssue> get emergencyIssues => maintenanceIssues.where((i) => i.priority == MaintenanceIssuePriority.emergency).toList();

  /// Clear all data and reset state
  void clearAll() {
    _property = null;
    _similarProperties.clear();
    _ownerProperties.clear();
    _propertyCollection.clear();
    _reviews.clear();
    _allReviews.clear();
    _maintenanceIssues.clear();
    _allMaintenanceIssues.clear();
    _booking = null;
    _leaseExtensionRequests.clear();
    _currentPricing = null;
    _currentPricingEstimate = null;
    _propertyAvailability.clear();

    // Clear BaseProvider state
    clearError();
    notifyListeners();
  }
}
