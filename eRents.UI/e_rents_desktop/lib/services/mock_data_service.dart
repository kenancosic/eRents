import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/models/tenant_preference.dart';
import 'package:e_rents_desktop/models/tenant_feedback.dart';
import 'package:e_rents_desktop/models/reports/financial_report_item.dart';
import 'package:e_rents_desktop/models/reports/tenant_report_item.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:e_rents_desktop/models/statistics/financial_statistics.dart';

class MockDataService {
  static List<User> getMockUsers() {
    return [
      // Admin and Manager
      User(
        id: '1',
        email: 'admin@erents.com',
        firstName: 'Admin',
        lastName: 'User',
        role: 'admin',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      ),
      User(
        id: '2',
        email: 'manager@erents.com',
        firstName: 'Property',
        lastName: 'Manager',
        role: 'manager',
        phone: '+1234567890',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now(),
      ),
      // Current Tenants
      User(
        id: '3',
        email: 'john.doe@example.com',
        firstName: 'John',
        lastName: 'Doe',
        role: 'tenant',
        phone: '+1987654321',
        city: 'New York',
        profileImage: 'https://i.pravatar.cc/150?img=3',
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
        updatedAt: DateTime.now(),
      ),
      User(
        id: '4',
        email: 'jane.smith@example.com',
        firstName: 'Jane',
        lastName: 'Smith',
        role: 'tenant',
        phone: '+1234567890',
        city: 'Los Angeles',
        profileImage: 'https://i.pravatar.cc/150?img=4',
        createdAt: DateTime.now().subtract(const Duration(days: 180)),
        updatedAt: DateTime.now(),
      ),
      User(
        id: '5',
        email: 'mike.wilson@example.com',
        firstName: 'Mike',
        lastName: 'Wilson',
        role: 'tenant',
        phone: '+1122334455',
        city: 'Chicago',
        profileImage: 'https://i.pravatar.cc/150?img=5',
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        updatedAt: DateTime.now(),
      ),
      // Searching Tenants
      User(
        id: '6',
        email: 'sarah.johnson@example.com',
        firstName: 'Sarah',
        lastName: 'Johnson',
        role: 'tenant',
        phone: '+1555666777',
        city: 'Boston',
        profileImage: 'https://i.pravatar.cc/150?img=6',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      ),
      User(
        id: '7',
        email: 'david.brown@example.com',
        firstName: 'David',
        lastName: 'Brown',
        role: 'tenant',
        phone: '+1888999000',
        city: 'Seattle',
        profileImage: 'https://i.pravatar.cc/150?img=7',
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

  static List<TenantFeedback> getMockTenantFeedbacks() {
    return [
      TenantFeedback(
        id: '1',
        tenantId: '3',
        landlordId: '2',
        propertyId: '1',
        rating: 5,
        comment:
            'Excellent tenant, always pays on time and maintains the property well. Very communicative and responsible.',
        feedbackDate: DateTime.now().subtract(const Duration(days: 30)),
        stayStartDate: DateTime.now().subtract(const Duration(days: 365)),
        stayEndDate: DateTime.now().subtract(const Duration(days: 30)),
      ),
      TenantFeedback(
        id: '2',
        tenantId: '4',
        landlordId: '2',
        propertyId: '2',
        rating: 4,
        comment:
            'Good tenant, maintains the property well. Occasionally late with rent but always communicates in advance.',
        feedbackDate: DateTime.now().subtract(const Duration(days: 15)),
        stayStartDate: DateTime.now().subtract(const Duration(days: 180)),
        stayEndDate: DateTime.now().subtract(const Duration(days: 15)),
      ),
      TenantFeedback(
        id: '3',
        tenantId: '5',
        landlordId: '2',
        propertyId: '3',
        rating: 5,
        comment:
            'Outstanding tenant. Takes great care of the property and has even made some improvements. Highly recommended.',
        feedbackDate: DateTime.now().subtract(const Duration(days: 7)),
        stayStartDate: DateTime.now().subtract(const Duration(days: 90)),
        stayEndDate: DateTime.now(),
      ),
    ];
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
        images: ['assets/images/leak1.jpg'],
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
        images: ['assets/images/window1.jpg'],
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
        images: ['assets/images/outlet1.jpg'],
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
        title: 'Luxury Apartment',
        description: 'Modern apartment in downtown area',
        type: 'Apartment',
        price: 2500.0,
        status: 'Available',
        images: ['assets/images/apartment1.jpg'],
        address: '123 Main St, City',
        bedrooms: 2,
        bathrooms: 2,
        area: 1200.0,
        maintenanceIssues:
            maintenanceIssues
                .where((issue) => issue.propertyId == '1')
                .toList(),
        yearBuilt: 2015,
        amenities: ['Pool', 'Gym', 'Parking'],
      ),
      Property(
        id: '2',
        title: 'Family House',
        description: 'Spacious house in suburban area',
        type: 'House',
        price: 3500.0,
        status: 'Occupied',
        images: ['assets/images/house1.jpg'],
        address: '456 Oak St, Suburb',
        bedrooms: 4,
        bathrooms: 3,
        area: 2500.0,
        maintenanceIssues:
            maintenanceIssues
                .where((issue) => issue.propertyId == '2')
                .toList(),
        yearBuilt: 2010,
        amenities: ['Garden', 'Garage', 'Basement'],
      ),
      Property(
        id: '3',
        title: 'Studio Loft',
        description:
            'Cozy studio with modern amenities, perfect for young professionals',
        type: 'Studio',
        price: 1800.0,
        status: 'Occupied',
        images: ['assets/images/lukavac_villa.jpg'],
        address: '789 Pine St, Arts District',
        bedrooms: 1,
        bathrooms: 1,
        area: 800,
        yearBuilt: 2020,
        amenities: ['High-Speed Internet', 'Laundry', 'Bike Storage'],
        maintenanceIssues:
            maintenanceIssues
                .where((issue) => issue.propertyId == '3')
                .toList(),
        lastInspectionDate: DateTime.now().subtract(const Duration(days: 15)),
        nextInspectionDate: DateTime.now().add(const Duration(days: 75)),
      ),
      Property(
        id: '4',
        title: 'Luxury Penthouse Suite',
        description:
            'Exclusive penthouse with panoramic city views and premium finishes',
        type: 'Penthouse',
        price: 5000.0,
        status: 'Available',
        images: ['assets/images/penthouse.jpg'],
        address: '101 Sky Tower, Downtown',
        bedrooms: 3,
        bathrooms: 3,
        area: 2000,
        yearBuilt: 2022,
        amenities: [
          'Private Elevator',
          'Rooftop Terrace',
          'Smart Home System',
          'Concierge',
        ],
        maintenanceIssues: [],
        lastInspectionDate: DateTime.now().subtract(const Duration(days: 10)),
        nextInspectionDate: DateTime.now().add(const Duration(days: 80)),
      ),
      Property(
        id: '5',
        title: 'Garden Villa',
        description:
            'Charming villa with private garden and modern interior design',
        type: 'Villa',
        price: 4300.0,
        status: 'Occupied',
        images: ['assets/images/villa.jpg'],
        address: '234 Garden Lane, Green Valley',
        bedrooms: 3,
        bathrooms: 2,
        area: 1800,
        yearBuilt: 2019,
        amenities: [
          'Private Garden',
          'Patio',
          'Storage Shed',
          'Security System',
        ],
        maintenanceIssues: [],
        lastInspectionDate: DateTime.now().subtract(const Duration(days: 20)),
        nextInspectionDate: DateTime.now().add(const Duration(days: 70)),
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
        tenant: 'John Smith',
        property: 'Greenview Apartments A101',
        leaseStart: '01/01/2023',
        leaseEnd: '31/12/2023',
        costOfRent: 1200.00,
        totalPaidRent: 14400.00,
      ),
      TenantReportItem(
        tenant: 'Jane Doe',
        property: 'Sunnydale Complex B205',
        leaseStart: '15/03/2023',
        leaseEnd: '14/03/2024',
        costOfRent: 950.00,
        totalPaidRent: 11400.00,
      ),
      TenantReportItem(
        tenant: 'Robert Johnson',
        property: 'Riverfront Towers C310',
        leaseStart: '01/11/2022',
        leaseEnd: '31/10/2023',
        costOfRent: 1350.00,
        totalPaidRent: 16200.00,
      ),
      TenantReportItem(
        tenant: 'Mary Williams',
        property: 'Greenview Apartments A102',
        leaseStart: '01/02/2023',
        leaseEnd: '31/01/2024',
        costOfRent: 1100.00,
        totalPaidRent: 13200.00,
      ),
      TenantReportItem(
        tenant: 'David Brown',
        property: 'Sunnydale Complex B208',
        leaseStart: '01/05/2023',
        leaseEnd: '31/07/2023',
        costOfRent: 1050.00,
        totalPaidRent: 3150.00,
      ),
    ];
  }

  static FinancialStatistics getMockFinancialStatistics(
    DateTime startDate,
    DateTime endDate,
  ) {
    final reportItems = getMockFinancialReportData(startDate, endDate);

    if (reportItems.isEmpty) {
      return FinancialStatistics(
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

    return FinancialStatistics(
      totalRent: totalRent,
      totalMaintenanceCosts: totalMaintenance,
      netTotal: netTotal,
      startDate: startDate,
      endDate: endDate,
      monthlyBreakdown: reportItems,
    );
  }
}
