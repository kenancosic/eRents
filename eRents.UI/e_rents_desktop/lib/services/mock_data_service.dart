import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:e_rents_desktop/models/property.dart';

class MockDataService {
  static List<MaintenanceIssue> getMockMaintenanceIssues() {
    return [
      MaintenanceIssue(
        id: '1',
        propertyId: '1',
        title: 'Leaking Faucet',
        description:
            'Kitchen faucet is leaking and needs repair. Tenant reported water dripping continuously.',
        priority: IssuePriority.medium,
        status: IssueStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        reportedBy: 'John Doe',
        category: 'Plumbing',
        isTenantComplaint: true,
        images: ['assets/images/leak1.jpg', 'assets/images/leak2.jpg'],
      ),
      MaintenanceIssue(
        id: '2',
        propertyId: '1',
        title: 'Broken Window',
        description:
            'Living room window is cracked and needs replacement. Caused by recent storm.',
        priority: IssuePriority.high,
        status: IssueStatus.inProgress,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        assignedTo: 'Maintenance Team',
        reportedBy: 'Jane Smith',
        category: 'Structural',
        requiresInspection: true,
        isTenantComplaint: true,
        images: ['assets/images/window1.jpg'],
      ),
      MaintenanceIssue(
        id: '3',
        propertyId: '2',
        title: 'Electrical Outlet Not Working',
        description:
            'Bedroom outlet stopped working. No power in the entire room.',
        priority: IssuePriority.medium,
        status: IssueStatus.completed,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        resolvedAt: DateTime.now().subtract(const Duration(days: 1)),
        cost: 150.0,
        assignedTo: 'Electrician',
        reportedBy: 'Mike Johnson',
        category: 'Electrical',
        isTenantComplaint: true,
        resolutionNotes:
            'Replaced faulty circuit breaker and rewired the outlet.',
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
    return [
      Property(
        id: '1',
        title: 'Luxury Apartment Downtown',
        description: 'Modern apartment in the heart of the city',
        type: 'Apartment',
        price: 2500.0,
        status: 'Occupied',
        images: ['assets/images/apartment.jpg'],
        address: '123 Main St, City Center',
        bedrooms: 2,
        bathrooms: 2,
        area: 1200,
        maintenanceRequests: [],
      ),
      Property(
        id: '2',
        title: 'Suburban Family Home',
        description: 'Spacious family home in quiet neighborhood',
        type: 'House',
        price: 3500.0,
        status: 'Available',
        images: ['assets/images/house.jpg'],
        address: '456 Oak Ave, Suburbia',
        bedrooms: 4,
        bathrooms: 3,
        area: 2500,
        maintenanceRequests: [],
      ),
      Property(
        id: '3',
        title: 'Studio Loft',
        description: 'Cozy studio with modern amenities',
        type: 'Studio',
        price: 1800.0,
        status: 'Occupied',
        images: ['assets/images/lukavac_villa.jpg'],
        address: '789 Pine St, Arts District',
        bedrooms: 1,
        bathrooms: 1,
        area: 800,
        maintenanceRequests: [],
      ),
    ];
  }
}
