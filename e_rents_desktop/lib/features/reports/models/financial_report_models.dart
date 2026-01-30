enum FinancialReportGroupBy {
  none(0),
  property(1),
  month(2),
  rentalType(3),
  day(4);

  const FinancialReportGroupBy(this.value);
  final int value;

  String get displayName {
    switch (this) {
      case FinancialReportGroupBy.none:
        return 'No Grouping';
      case FinancialReportGroupBy.property:
        return 'By Property';
      case FinancialReportGroupBy.month:
        return 'By Month';
      case FinancialReportGroupBy.rentalType:
        return 'By Rental Type';
      case FinancialReportGroupBy.day:
        return 'By Day';
    }
  }
}

enum FinancialReportSortBy {
  propertyName(0),
  tenantName(1),
  startDate(2),
  endDate(3),
  totalPrice(4),
  rentalType(5);

  const FinancialReportSortBy(this.value);
  final int value;

  String get displayName {
    switch (this) {
      case FinancialReportSortBy.propertyName:
        return 'Property Name';
      case FinancialReportSortBy.tenantName:
        return 'Tenant Name';
      case FinancialReportSortBy.startDate:
        return 'Start Date';
      case FinancialReportSortBy.endDate:
        return 'End Date';
      case FinancialReportSortBy.totalPrice:
        return 'Total Price';
      case FinancialReportSortBy.rentalType:
        return 'Rental Type';
    }
  }
}

enum RentalType {
  daily(1),
  monthly(2);

  const RentalType(this.value);
  final int value;

  String get displayName {
    switch (this) {
      case RentalType.daily:
        return 'Daily';
      case RentalType.monthly:
        return 'Monthly';
    }
  }
}

class FinancialReportRequest {
  final DateTime startDate;
  final DateTime endDate;
  final FinancialReportGroupBy? groupBy;
  final FinancialReportSortBy? sortBy;
  final bool sortDescending;
  final int? propertyId;
  final RentalType? rentalType;
  final int page;
  final int pageSize;

  FinancialReportRequest({
    required this.startDate,
    required this.endDate,
    this.groupBy,
    this.sortBy,
    this.sortDescending = false,
    this.propertyId,
    this.rentalType,
    this.page = 1,
    this.pageSize = 50,
  });

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'page': page,
      'pageSize': pageSize,
      'sortDescending': sortDescending,
    };

    if (groupBy != null && groupBy != FinancialReportGroupBy.none) {
      params['groupBy'] = groupBy!.value;
    }
    if (sortBy != null) {
      params['sortBy'] = sortBy!.value;
    }
    if (propertyId != null) {
      params['propertyId'] = propertyId;
    }
    if (rentalType != null) {
      params['rentalType'] = rentalType!.value;
    }

    return params;
  }
}

enum BookingStatus {
  upcoming(1, 'Upcoming'),
  completed(2, 'Completed'),
  cancelled(3, 'Cancelled'),
  active(4, 'Active'),
  pending(5, 'Pending'),
  approved(6, 'Approved');

  const BookingStatus(this.value, this.displayName);
  final int value;
  final String displayName;

  /// Parse from JSON - handles both string names and integer values
  static BookingStatus fromJson(dynamic json) {
    if (json == null) return BookingStatus.completed;
    
    // Handle string value (e.g., "Cancelled", "Completed")
    if (json is String) {
      return BookingStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == json.toLowerCase() || 
               e.displayName.toLowerCase() == json.toLowerCase(),
        orElse: () => BookingStatus.completed,
      );
    }
    
    // Handle integer value
    if (json is int) {
      return BookingStatus.values.firstWhere(
        (e) => e.value == json,
        orElse: () => BookingStatus.completed,
      );
    }
    
    return BookingStatus.completed;
  }
}

class FinancialReportResponse {
  final int bookingId;
  final String propertyName;
  final String tenantName;
  final DateTime startDate;
  final DateTime? endDate;
  final RentalType rentalType;
  final double totalPrice;
  final String currency;
  final BookingStatus status;
  final double refundAmount;
  final String? groupKey;
  final String? groupLabel;
  final double? groupTotal;
  final int? groupCount;

  FinancialReportResponse({
    required this.bookingId,
    required this.propertyName,
    required this.tenantName,
    required this.startDate,
    this.endDate,
    required this.rentalType,
    required this.totalPrice,
    required this.currency,
    this.status = BookingStatus.completed,
    this.refundAmount = 0,
    this.groupKey,
    this.groupLabel,
    this.groupTotal,
    this.groupCount,
  });

  bool get wasRefunded => refundAmount > 0;
  double get netRevenue => totalPrice - refundAmount;
  bool get isCancelled => status == BookingStatus.cancelled;

  factory FinancialReportResponse.fromJson(Map<String, dynamic> json) {
    return FinancialReportResponse(
      bookingId: json['bookingId'] ?? 0,
      propertyName: json['propertyName'] ?? '',
      tenantName: json['tenantName'] ?? '',
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      rentalType: RentalType.values.firstWhere(
        (e) => e.value == (json['rentalType'] ?? 1),
        orElse: () => RentalType.daily,
      ),
      totalPrice: (json['totalPrice'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'USD',
      status: BookingStatus.fromJson(json['status']),
      refundAmount: (json['refundAmount'] ?? 0.0).toDouble(),
      groupKey: json['groupKey'],
      groupLabel: json['groupLabel'],
      groupTotal: json['groupTotal']?.toDouble(),
      groupCount: json['groupCount'],
    );
  }
}

class FinancialReportSummary {
  final List<FinancialReportResponse> reports;
  final double totalRevenue;
  final int totalBookings;
  final double averageBookingValue;
  final Map<String, double> groupTotals;
  final int totalPages;
  final int currentPage;
  final int pageSize;
  final int totalCancellations;
  final double totalRefunds;
  final double netRevenue;

  FinancialReportSummary({
    required this.reports,
    required this.totalRevenue,
    required this.totalBookings,
    required this.averageBookingValue,
    required this.groupTotals,
    required this.totalPages,
    required this.currentPage,
    required this.pageSize,
    this.totalCancellations = 0,
    this.totalRefunds = 0,
    this.netRevenue = 0,
  });

  factory FinancialReportSummary.fromJson(Map<String, dynamic> json) {
    return FinancialReportSummary(
      reports: (json['reports'] as List<dynamic>?)
          ?.map((e) => FinancialReportResponse.fromJson(e))
          .toList() ?? [],
      totalRevenue: (json['totalRevenue'] ?? 0.0).toDouble(),
      totalBookings: json['totalBookings'] ?? 0,
      averageBookingValue: (json['averageBookingValue'] ?? 0.0).toDouble(),
      groupTotals: Map<String, double>.from(
        (json['groupTotals'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, (value ?? 0.0).toDouble()),
        ) ?? {},
      ),
      totalPages: json['totalPages'] ?? 1,
      currentPage: json['currentPage'] ?? 1,
      pageSize: json['pageSize'] ?? 50,
      totalCancellations: json['totalCancellations'] ?? 0,
      totalRefunds: (json['totalRefunds'] ?? 0.0).toDouble(),
      netRevenue: (json['netRevenue'] ?? 0.0).toDouble(),
    );
  }
}
