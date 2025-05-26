import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/models/tenant_preference.dart';
import 'package:e_rents_desktop/models/review.dart';
import 'package:e_rents_desktop/models/reports/financial_report_item.dart';
import 'package:e_rents_desktop/models/reports/tenant_report_item.dart';
import 'package:e_rents_desktop/models/renting_type.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/statistics/financial_statistics.dart'
    as ui_model;
import 'package:e_rents_desktop/models/address_detail.dart';
import 'package:e_rents_desktop/services/statistics_service.dart'
    show
        DashboardStatistics,
        PopularProperty,
        FinancialStatistics,
        MonthlyRevenue;

import 'package:e_rents_desktop/models/image_info.dart' as erents;

class MockDataService {
  static final Map<String, IconData> _amenityIcons = {
    'Pool': Icons.pool,
    'Gym': Icons.fitness_center,
    'Parking': Icons.local_parking,
    'Garage': Icons.garage,
    'Balcony': Icons.balcony,
    'Patio': Icons.deck,
    'Garden': Icons.yard,
    'In-Unit Laundry': Icons.local_laundry_service,
    'Air Conditioning': Icons.ac_unit,
    'Heating': Icons.thermostat,
    'Dishwasher': Icons.kitchen,
    'Furnished': Icons.chair,
    'Pet Friendly': Icons.pets,
    'Elevator': Icons.elevator,
    'Security System': Icons.security,
    'High-Speed Internet': Icons.wifi,
    'Wheelchair Accessible': Icons.accessible,
    'Storage': Icons.inventory_2_outlined,
    'Concierge': Icons.room_service,
    'City View': Icons.location_city,
    'Water View': Icons.water,
    'Fireplace': Icons.fireplace,
  };

  static Map<String, IconData> getMockAmenitiesWithIcons() {
    return Map.unmodifiable(_amenityIcons);
  }

  static List<User> getMockUsers() {
    return [
      // Admin and Manager
      User(
        id: '1',
        email: 'admin@erents.com',
        username: 'admin',
        firstName: 'Admin',
        lastName: 'User',
        role: UserType.admin,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      ),
      User(
        id: '2',
        email: 'manager@erents.com',
        username: 'manager',
        firstName: 'Property',
        lastName: 'Manager',
        role: UserType.landlord,
        phone: '+1234567890',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now(),
      ),
      // Current Tenants
      User(
        id: '3',
        email: 'john.doe@example.com',
        username: 'johndoe',
        firstName: 'John',
        lastName: 'Doe',
        role: UserType.landlord,
        phone: '+1987654321',
        addressDetail: AddressDetail(
          addressDetailId: 301,
          geoRegionId: 1001,
          streetLine1: '123 Main St',
          streetLine2: 'New York, NY',
          latitude: 40.7128,
          longitude: -74.0060,
        ),
        profileImage: erents.ImageInfo(
          id: '3',
          url: 'https://i.pravatar.cc/150?img=3',
        ),
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
        updatedAt: DateTime.now(),
      ),
      User(
        id: '4',
        email: 'jane.smith@example.com',
        username: 'janesmith',
        firstName: 'Jane',
        lastName: 'Smith',
        role: UserType.landlord,
        phone: '+1234567890',
        addressDetail: AddressDetail(
          addressDetailId: 302,
          geoRegionId: 1002,
          streetLine1: '456 Ocean Blvd',
          streetLine2: 'Los Angeles, CA',
          latitude: 34.0522,
          longitude: -118.2437,
        ),
        profileImage: erents.ImageInfo(
          id: '4',
          url: 'https://i.pravatar.cc/150?img=4',
        ),
        createdAt: DateTime.now().subtract(const Duration(days: 180)),
        updatedAt: DateTime.now(),
      ),
      User(
        id: '5',
        email: 'mike.wilson@example.com',
        username: 'mikewilson',
        firstName: 'Mike',
        lastName: 'Wilson',
        role: UserType.landlord,
        phone: '+1122334455',
        addressDetail: AddressDetail(
          addressDetailId: 303,
          geoRegionId: 1003,
          streetLine1: '789 Lake St',
          streetLine2: 'Chicago, IL',
          latitude: 41.8781,
          longitude: -87.6298,
        ),
        profileImage: erents.ImageInfo(
          id: '5',
          url: 'https://i.pravatar.cc/150?img=5',
        ),
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        updatedAt: DateTime.now(),
      ),
      // Searching Tenants
      User(
        id: '6',
        email: 'sarah.johnson@example.com',
        username: 'sarahjohnson',
        firstName: 'Sarah',
        lastName: 'Johnson',
        role: UserType.landlord,
        phone: '+1555666777',
        addressDetail: AddressDetail(
          addressDetailId: 304,
          geoRegionId: 1004,
          streetLine1: '101 Beacon St',
          streetLine2: 'Boston, MA',
          latitude: 42.3601,
          longitude: -71.0589,
        ),
        profileImage: erents.ImageInfo(
          id: '6',
          url: 'https://i.pravatar.cc/150?img=6',
        ),
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      ),
      User(
        id: '7',
        email: 'david.brown@example.com',
        username: 'davidbrown',
        firstName: 'David',
        lastName: 'Brown',
        role: UserType.landlord,
        phone: '+1888999000',
        addressDetail: AddressDetail(
          addressDetailId: 305,
          geoRegionId: 1005,
          streetLine1: '222 Pine Ave',
          streetLine2: 'Seattle, WA',
          latitude: 47.6062,
          longitude: -122.3321,
        ),
        profileImage: erents.ImageInfo(
          id: '7',
          url: 'https://i.pravatar.cc/150?img=7',
        ),
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  static List<TenantPreference> getMockTenantPreferences() {
    return [
      TenantPreference(
        id: '1',
        userId: '6',
        searchStartDate: DateTime.now(),
        searchEndDate: DateTime.now().add(const Duration(days: 30)),
        minPrice: 1500,
        maxPrice: 2500,
        city: 'Boston',
        amenities: ['Parking', 'Gym', 'Laundry', 'AC'],
        description: 'Looking for a modern 2-bedroom apartment near downtown',
      ),
      TenantPreference(
        id: '2',
        userId: '7',
        searchStartDate: DateTime.now(),
        minPrice: 2000,
        maxPrice: 3000,
        city: 'Seattle',
        amenities: ['Parking', 'Balcony', 'AC', 'Washer/Dryer'],
        description: 'Seeking a pet-friendly apartment with good natural light',
      ),
      TenantPreference(
        id: '3',
        userId: '8',
        searchStartDate: DateTime.now(),
        minPrice: 1200,
        maxPrice: 1800,
        city: 'Portland',
        amenities: ['Bike Storage', 'Garden', 'High-Speed Internet'],
        description:
            'Interested in eco-friendly living spaces with community areas',
      ),
    ];
  }

  // DEPRECATED: TenantFeedback has been replaced with the unified Review system
  // This method is kept for backward compatibility but returns empty list
  static List<Review> getMockTenantFeedbacks() {
    return [];
  }

  static List<MaintenanceIssue> getMockMaintenanceIssues() {
    return [
      MaintenanceIssue(
        id: '1',
        propertyId: '1',
        title: 'Leaking Faucet',
        description: 'Kitchen faucet is leaking and needs repair',
        priority: IssuePriority.high,
        status: IssueStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        reportedBy: 'John Doe',
        category: 'Plumbing',
        isTenantComplaint: true,
        images: [erents.ImageInfo(id: 'leak1', url: 'assets/images/leak1.jpg')],
      ),
      MaintenanceIssue(
        id: '2',
        propertyId: '1',
        title: 'Broken Window',
        description: 'Living room window is cracked and needs replacement',
        priority: IssuePriority.medium,
        status: IssueStatus.inProgress,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        reportedBy: 'Jane Smith',
        category: 'Structural',
        isTenantComplaint: false,
        images: [
          erents.ImageInfo(id: 'window1', url: 'assets/images/window1.jpg'),
        ],
      ),
      MaintenanceIssue(
        id: '3',
        propertyId: '2',
        title: 'Electrical Outlet Not Working',
        description: 'Bedroom outlet is not providing power',
        priority: IssuePriority.high,
        status: IssueStatus.completed,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        resolvedAt: DateTime.now().subtract(const Duration(days: 8)),
        reportedBy: 'Mike Johnson',
        category: 'Electrical',
        isTenantComplaint: true,
        images: [
          erents.ImageInfo(id: 'outlet1', url: 'assets/images/outlet1.jpg'),
        ],
      ),
      MaintenanceIssue(
        id: '4',
        propertyId: '3',
        title: 'HVAC System Malfunction',
        description:
            'Air conditioning not cooling properly. Temperature remains high despite settings.',
        priority: IssuePriority.high,
        status: IssueStatus.inProgress,
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        assignedTo: 'HVAC Specialist',
        reportedBy: 'Sarah Wilson',
        category: 'HVAC',
        isTenantComplaint: true,
        requiresInspection: true,
      ),
      MaintenanceIssue(
        id: '5',
        propertyId: '2',
        title: 'Pest Control Required',
        description:
            'Tenant reported signs of rodent activity in the kitchen area.',
        priority: IssuePriority.medium,
        status: IssueStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        reportedBy: 'Robert Brown',
        category: 'Pest Control',
        isTenantComplaint: true,
      ),
      MaintenanceIssue(
        id: '6',
        propertyId: '1',
        title: 'Regular Maintenance Check',
        description:
            'Quarterly maintenance check for all systems and appliances.',
        priority: IssuePriority.low,
        status: IssueStatus.completed,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        resolvedAt: DateTime.now().subtract(const Duration(days: 4)),
        cost: 200.0,
        assignedTo: 'Maintenance Team',
        reportedBy: 'System',
        category: 'Routine',
        isTenantComplaint: false,
        resolutionNotes:
            'All systems checked and functioning properly. Minor adjustments made to HVAC.',
      ),
      MaintenanceIssue(
        id: '7',
        propertyId: '3',
        title: 'Emergency Water Leak',
        description:
            'Major water leak in the bathroom. Water is spreading to adjacent rooms.',
        priority: IssuePriority.emergency,
        status: IssueStatus.inProgress,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        assignedTo: 'Emergency Plumber',
        reportedBy: 'Lisa Anderson',
        category: 'Plumbing',
        isTenantComplaint: true,
        requiresInspection: true,
      ),
    ];
  }

  static List<Property> getMockProperties() {
    final maintenanceIssues = getMockMaintenanceIssues();

    return [
      Property(
        id: '1',
        ownerId: 'owner1',
        title: 'Luxury Apartment',
        description: 'Modern apartment in downtown area',
        type: PropertyType.apartment,
        price: 2500.0,
        rentingType: RentingType.monthly,
        status: PropertyStatus.available,
        images: [
          erents.ImageInfo(
            id: 'apartment1',
            url: 'assets/images/apartment1.jpg',
          ),
        ],
        addressDetail: AddressDetail(
          addressDetailId: 101,
          geoRegionId: 201,
          streetLine1: '123 Main St',
          streetLine2: 'City',
          latitude: 40.7128,
          longitude: -74.0060,
        ),
        bedrooms: 2,
        bathrooms: 2,
        area: 1200.0,
        maintenanceIssues:
            maintenanceIssues
                .where((issue) => issue.propertyId == '1')
                .toList(),
        // yearBuilt: 2015, // Removed - field deprecated
        amenities: ['Pool', 'Gym', 'Parking'],
        dateAdded: DateTime.now().subtract(const Duration(days: 100)),
      ),
      Property(
        id: '2',
        ownerId: 'owner1',
        title: 'Family House',
        description: 'Spacious house in suburban area',
        type: PropertyType.house,
        price: 3500.0,
        rentingType: RentingType.monthly,
        status: PropertyStatus.rented,
        images: [
          erents.ImageInfo(id: 'house1', url: 'assets/images/house1.jpg'),
        ],
        addressDetail: AddressDetail(
          addressDetailId: 102,
          geoRegionId: 202,
          streetLine1: '456 Oak St',
          streetLine2: 'Suburb',
          latitude: 34.0522,
          longitude: -118.2437,
        ),
        bedrooms: 4,
        bathrooms: 3,
        area: 2500.0,
        maintenanceIssues:
            maintenanceIssues
                .where((issue) => issue.propertyId == '2')
                .toList(),
        // yearBuilt: 2010, // Removed - field deprecated
        amenities: ['Garden', 'Garage', 'Basement'],
        dateAdded: DateTime.now().subtract(const Duration(days: 150)),
      ),
      Property(
        id: '3',
        ownerId: 'owner2',
        title: 'Studio Loft',
        description:
            'Cozy studio with modern amenities, perfect for young professionals',
        type: PropertyType.studio,
        price: 1800.0,
        rentingType: RentingType.monthly,
        status: PropertyStatus.rented,
        images: [
          erents.ImageInfo(
            id: 'lukavac_villa',
            url: 'assets/images/lukavac_villa.jpg',
          ),
        ],
        addressDetail: AddressDetail(
          addressDetailId: 103,
          geoRegionId: 203,
          streetLine1: '789 Pine St',
          streetLine2: 'Arts District',
          latitude: 41.8781,
          longitude: -87.6298,
        ),
        bedrooms: 1,
        bathrooms: 1,
        area: 800,
        // yearBuilt: 2020, // Removed - field deprecated
        amenities: ['High-Speed Internet', 'Laundry', 'Bike Storage'],
        maintenanceIssues:
            maintenanceIssues
                .where((issue) => issue.propertyId == '3')
                .toList(),
        lastInspectionDate: DateTime.now().subtract(const Duration(days: 15)),
        nextInspectionDate: DateTime.now().add(const Duration(days: 75)),
        dateAdded: DateTime.now().subtract(const Duration(days: 200)),
      ),
      Property(
        id: '4',
        ownerId: 'owner3',
        title: 'Luxury Penthouse Suite',
        description:
            'Exclusive penthouse with panoramic city views and premium finishes',
        type: PropertyType.apartment,
        price: 5000.0,
        rentingType: RentingType.monthly,
        status: PropertyStatus.available,
        images: [
          erents.ImageInfo(id: 'penthouse', url: 'assets/images/penthouse.jpg'),
        ],
        addressDetail: AddressDetail(
          addressDetailId: 104,
          geoRegionId: 204,
          streetLine1: '101 Sky Tower',
          streetLine2: 'Downtown',
          latitude: 42.3601,
          longitude: -71.0589,
        ),
        bedrooms: 3,
        bathrooms: 3,
        area: 2000,
        // yearBuilt: 2022, // Removed - field deprecated
        amenities: [
          'Private Elevator',
          'Rooftop Terrace',
          'Smart Home System',
          'Concierge',
        ],
        maintenanceIssues: [],
        lastInspectionDate: DateTime.now().subtract(const Duration(days: 10)),
        nextInspectionDate: DateTime.now().add(const Duration(days: 80)),
        dateAdded: DateTime.now().subtract(const Duration(days: 50)),
      ),
      Property(
        id: '5',
        ownerId: 'owner2',
        title: 'Garden Villa',
        description:
            'Charming villa with private garden and modern interior design',
        type: PropertyType.house,
        price: 4300.0,
        rentingType: RentingType.monthly,
        status: PropertyStatus.rented,
        images: [erents.ImageInfo(id: 'villa', url: 'assets/images/villa.jpg')],
        addressDetail: AddressDetail(
          addressDetailId: 105,
          geoRegionId: 205,
          streetLine1: '234 Garden Lane',
          streetLine2: 'Green Valley',
          latitude: 47.6062,
          longitude: -122.3321,
        ),
        bedrooms: 3,
        bathrooms: 2,
        area: 1800,
        // yearBuilt: 2019, // Removed - field deprecated
        amenities: [
          'Private Garden',
          'Patio',
          'Storage Shed',
          'Security System',
        ],
        maintenanceIssues: [],
        lastInspectionDate: DateTime.now().subtract(const Duration(days: 20)),
        nextInspectionDate: DateTime.now().add(const Duration(days: 70)),
        dateAdded: DateTime.now().subtract(const Duration(days: 180)),
      ),
    ];
  }

  static List<FinancialReportItem> getMockFinancialReportData(
    DateTime startDate,
    DateTime endDate,
  ) {
    debugPrint(
      'MockDataService.getMockFinancialReportData: startDate=$startDate, endDate=$endDate',
    );

    final DateFormat formatter = DateFormat('dd/MM/yyyy');

    final List<FinancialReportItem> allData = [
      FinancialReportItem(
        dateFrom: '01/06/2023',
        dateTo: '30/06/2023',
        property: 'Greenview Apartments',
        totalRent: 10500.00,
        maintenanceCosts: 1250.00,
        total: 9250.00,
      ),
      FinancialReportItem(
        dateFrom: '01/07/2023',
        dateTo: '31/07/2023',
        property: 'Sunnydale Complex',
        totalRent: 12000.00,
        maintenanceCosts: 1800.00,
        total: 10200.00,
      ),
      FinancialReportItem(
        dateFrom: '01/08/2023',
        dateTo: '31/08/2023',
        property: 'Riverfront Towers',
        totalRent: 15000.00,
        maintenanceCosts: 2200.00,
        total: 12800.00,
      ),
      FinancialReportItem(
        dateFrom: '01/04/2024',
        dateTo: '30/04/2024',
        property: 'Greenview Apartments',
        totalRent: 11000.00,
        maintenanceCosts: 1350.00,
        total: 9650.00,
      ),
      FinancialReportItem(
        dateFrom: '01/05/2024',
        dateTo: '31/05/2024',
        property: 'Sunnydale Complex',
        totalRent: 12500.00,
        maintenanceCosts: 1950.00,
        total: 10550.00,
      ),
      FinancialReportItem(
        dateFrom: '01/06/2024',
        dateTo: '30/06/2024',
        property: 'Riverfront Towers',
        totalRent: 15500.00,
        maintenanceCosts: 2300.00,
        total: 13200.00,
      ),
      FinancialReportItem(
        dateFrom: '01/01/2025',
        dateTo: '31/01/2025',
        property: 'Mountain View Residences',
        totalRent: 18000.00,
        maintenanceCosts: 2500.00,
        total: 15500.00,
      ),
    ];

    try {
      final filteredData =
          allData.where((item) {
            final itemStartDate = formatter.parse(item.dateFrom);
            final itemEndDate = formatter.parse(item.dateTo);
            final hasOverlap =
                (itemStartDate.isBefore(endDate) ||
                    itemStartDate.isAtSameMomentAs(endDate)) &&
                (itemEndDate.isAfter(startDate) ||
                    itemEndDate.isAtSameMomentAs(startDate));
            return hasOverlap;
          }).toList();
      debugPrint('Filtered financial data: ${filteredData.length} items');
      return filteredData;
    } catch (e) {
      debugPrint('Error filtering financial data: $e');
      return allData;
    }
  }

  static List<TenantReportItem> getMockTenantReportData() {
    return [
      TenantReportItem(
        tenantName: 'John Smith',
        propertyName: 'Greenview Apartments A101',
        dateFrom: '01/01/2023',
        dateTo: '31/12/2023',
        costOfRent: 1200.00,
        totalPaidRent: 14400.00,
      ),
      TenantReportItem(
        tenantName: 'Jane Doe',
        propertyName: 'Sunnydale Complex B205',
        dateFrom: '15/03/2023',
        dateTo: '14/03/2024',
        costOfRent: 950.00,
        totalPaidRent: 11400.00,
      ),
      TenantReportItem(
        tenantName: 'Robert Johnson',
        propertyName: 'Riverfront Towers C310',
        dateFrom: '01/11/2022',
        dateTo: '31/10/2023',
        costOfRent: 1350.00,
        totalPaidRent: 16200.00,
      ),
      TenantReportItem(
        tenantName: 'Mary Williams',
        propertyName: 'Greenview Apartments A102',
        dateFrom: '01/02/2023',
        dateTo: '31/01/2024',
        costOfRent: 1100.00,
        totalPaidRent: 13200.00,
      ),
      TenantReportItem(
        tenantName: 'David Brown',
        propertyName: 'Sunnydale Complex B208',
        dateFrom: '01/05/2023',
        dateTo: '31/07/2023',
        costOfRent: 1050.00,
        totalPaidRent: 3150.00,
      ),
    ];
  }

  static ui_model.FinancialStatistics getMockFinancialStatistics(
    DateTime startDate,
    DateTime endDate,
  ) {
    final reportItems = getMockFinancialReportData(startDate, endDate);

    if (reportItems.isEmpty) {
      return ui_model.FinancialStatistics(
        totalRent: 0,
        totalMaintenanceCosts: 0,
        netTotal: 0,
        startDate: startDate,
        endDate: endDate,
        monthlyBreakdown: [],
      );
    }

    double totalRent = 0;
    double totalMaintenance = 0;
    double netTotal = 0;

    for (var item in reportItems) {
      totalRent += item.totalRent;
      totalMaintenance += item.maintenanceCosts;
      netTotal += item.total;
    }

    return ui_model.FinancialStatistics(
      totalRent: totalRent,
      totalMaintenanceCosts: totalMaintenance,
      netTotal: netTotal,
      startDate: startDate,
      endDate: endDate,
      monthlyBreakdown: reportItems,
    );
  }

  static List<String> getReportTypes() {
    return ['Financial Report', 'Tenant Report'];
  }

  static List<String> getQuickDateRanges() {
    return [
      'Today',
      'Yesterday',
      'This Week',
      'Last Week',
      'This Month',
      'Last Month',
      'This Quarter',
      'Last Quarter',
      'This Year',
      'Last Year',
      'Custom',
    ];
  }

  static List<String> getQuickDateRangePresets() {
    return [
      'Last 7 Days',
      'Last 30 Days',
      'Last 90 Days',
      'This Year',
      'Last Year',
    ];
  }

  static List<String> getCurrentTenantFilterFields() {
    return ['Full Name', 'Email', 'Phone', 'City'];
  }

  static List<String> getSearchingTenantFilterFields() {
    return ['City', 'Price Range', 'Amenities', 'Description'];
  }

  static DashboardStatistics getMockDashboardStatistics() {
    final mockProperties = getMockProperties();
    final mockIssues = getMockMaintenanceIssues();
    return DashboardStatistics(
      totalProperties: mockProperties.length,
      occupiedProperties:
          mockProperties.where((p) => p.status == PropertyStatus.rented).length,
      occupancyRate:
          mockProperties.isEmpty
              ? 0.0
              : (mockProperties
                      .where((p) => p.status == PropertyStatus.rented)
                      .length /
                  mockProperties.length),
      averageRating: 4.5,
      topProperties: [
        PopularProperty(
          propertyId: 1,
          name: "Luxury Apartment",
          bookingCount: 10,
          totalRevenue: 25000,
          averageRating: 4.8,
        ),
        PopularProperty(
          propertyId: 2,
          name: "Family House",
          bookingCount: 8,
          totalRevenue: 28000,
          averageRating: 4.6,
        ),
      ],
      pendingMaintenanceIssues:
          mockIssues
              .where((issue) => issue.status == IssueStatus.pending)
              .length,
      monthlyRevenue: 53000,
      yearlyRevenue: 636000,
    );
  }

  static FinancialStatistics getMockApiFinancialStatistics(
    DateTime startDate,
    DateTime endDate,
  ) {
    List<MonthlyRevenue> history = [];
    DateTime currentDateLoop = DateTime(startDate.year, startDate.month);
    while (currentDateLoop.isBefore(endDate) ||
        currentDateLoop.isAtSameMomentAs(endDate)) {
      history.add(
        MonthlyRevenue(
          year: currentDateLoop.year,
          month: currentDateLoop.month,
          revenue:
              (currentDateLoop.month * 1500) +
              (currentDateLoop.year - 2022) * 5000 +
              10000,
        ),
      );
      currentDateLoop = DateTime(
        currentDateLoop.year,
        currentDateLoop.month + 1,
      );
    }
    if (history.isEmpty && (endDate.difference(startDate).inDays < 30)) {
      history.add(
        MonthlyRevenue(
          year: startDate.year,
          month: startDate.month,
          revenue: 12000,
        ),
      );
    }

    return FinancialStatistics(
      currentMonthRevenue: history.isNotEmpty ? history.last.revenue : 25000.0,
      previousMonthRevenue:
          history.length > 1 ? history[history.length - 2].revenue : 22000.0,
      projectedRevenue:
          (history.isNotEmpty ? history.last.revenue : 25000.0) * 1.1,
      revenueHistory: history,
      revenueByPropertyType: {
        "Apartment": history.fold(0.0, (sum, item) => sum + item.revenue * 0.6),
        "House": history.fold(0.0, (sum, item) => sum + item.revenue * 0.3),
        "Studio": history.fold(0.0, (sum, item) => sum + item.revenue * 0.1),
      },
    );
  }

  // DEPRECATED: RecentActivity has been replaced with the unified notification system
  // This method is kept for backward compatibility but returns empty list
  static List<dynamic> getMockRecentActivities() {
    return [];
  }
}
