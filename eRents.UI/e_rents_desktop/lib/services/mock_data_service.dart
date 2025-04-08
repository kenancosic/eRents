import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/user.dart';

class MockDataService {
  static List<User> getMockUsers() {
    return [
      User(
        id: '1',
        email: 'admin@erents.com',
        name: 'Admin User',
        role: 'admin',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      ),
      User(
        id: '2',
        email: 'manager@erents.com',
        name: 'Property Manager',
        role: 'manager',
        phone: '+1234567890',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now(),
      ),
      User(
        id: '3',
        email: 'tenant@erents.com',
        name: 'John Doe',
        role: 'tenant',
        phone: '+0987654321',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now(),
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
        price: 4200.0,
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
}
