import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:e_rents_desktop/services/mock_data_service.dart';

class MaintenanceProvider extends BaseProvider<MaintenanceIssue> {
  MaintenanceProvider(ApiService apiService) : super(apiService) {
    // Enable mock data for development
    enableMockData();
  }

  @override
  String get endpoint => '/maintenance-issues';

  @override
  MaintenanceIssue fromJson(Map<String, dynamic> json) =>
      MaintenanceIssue.fromJson(json);

  @override
  Map<String, dynamic> toJson(MaintenanceIssue item) => item.toJson();

  @override
  List<MaintenanceIssue> getMockItems() =>
      MockDataService.getMockMaintenanceIssues();

  // Fetch issues using the base provider's fetch method
  Future<void> fetchIssues() async {
    await fetchItems();
  }

  // Getters to match the screen's expectations
  bool get isLoading => state == ViewState.Busy;
  String? get error => errorMessage;

  // Additional maintenance-specific methods
  List<MaintenanceIssue> getIssuesForProperty(String propertyId) {
    return items.where((issue) => issue.propertyId == propertyId).toList();
  }

  List<MaintenanceIssue> getIssuesByStatus(IssueStatus status) {
    return items.where((issue) => issue.status == status).toList();
  }

  List<MaintenanceIssue> getIssuesByPriority(IssuePriority priority) {
    return items.where((issue) => issue.priority == priority).toList();
  }

  List<MaintenanceIssue> getTenantComplaints() {
    return items.where((issue) => issue.isTenantComplaint).toList();
  }

  // Alias for items to maintain backward compatibility
  List<MaintenanceIssue> get issues => items;
}
