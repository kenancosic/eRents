import 'dart:convert';
import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:e_rents_desktop/services/api_service.dart';

// TODO: Full backend integration for all maintenance features is pending.
// Ensure all endpoints are functional and error handling is robust.
class MaintenanceService extends ApiService {
  MaintenanceService(super.baseUrl, super.storageService);

  Future<List<MaintenanceIssue>> getIssues({
    Map<String, String>? queryParams,
  }) async {
    print('MaintenanceService: Attempting to fetch maintenance issues...');
    if (queryParams != null && queryParams.isNotEmpty) {
      print('MaintenanceService: Using query params: $queryParams');
    }
    String endpoint = '/maintenance';
    if (queryParams != null && queryParams.isNotEmpty) {
      endpoint += '?' + Uri(queryParameters: queryParams).query;
    }
    print('MaintenanceService: Calling endpoint: $endpoint');
    try {
      final response = await get(endpoint, authenticated: true);
      final List<dynamic> jsonResponse = json.decode(response.body);
      // Add individual item parsing try-catch if needed, similar to other services
      final issues =
          jsonResponse
              .map((json) {
                try {
                  return MaintenanceIssue.fromJson(json);
                } catch (e) {
                  print(
                    'MaintenanceService: Error parsing a maintenance issue: $e. Returning null for this item.',
                  );
                  return null; // Or handle more gracefully depending on UI needs
                }
              })
              .where((issue) => issue != null)
              .cast<MaintenanceIssue>()
              .toList();
      print(
        'MaintenanceService: Successfully fetched ${issues.length} maintenance issues.',
      );
      return issues;
    } catch (e) {
      print(
        'MaintenanceService: Error fetching maintenance issues: $e. Backend integration might be pending or endpoint unavailable.',
      );
      throw Exception(
        'Failed to fetch maintenance issues. Backend integration pending or endpoint unavailable. Cause: $e',
      );
    }
  }

  Future<MaintenanceIssue> getIssueById(String issueId) async {
    print(
      'MaintenanceService: Attempting to fetch maintenance issue $issueId...',
    );
    try {
      final response = await get('/maintenance/$issueId', authenticated: true);
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final issue = MaintenanceIssue.fromJson(jsonResponse);
      print(
        'MaintenanceService: Successfully fetched maintenance issue $issueId.',
      );
      return issue;
    } catch (e) {
      print(
        'MaintenanceService: Error fetching maintenance issue $issueId: $e. Backend integration might be pending or endpoint unavailable.',
      );
      throw Exception(
        'Failed to fetch maintenance issue $issueId. Backend integration pending or endpoint unavailable. Cause: $e',
      );
    }
  }

  Future<MaintenanceIssue> createIssue(MaintenanceIssue issue) async {
    print('MaintenanceService: Attempting to create maintenance issue...');
    try {
      final response = await post(
        '/maintenance',
        issue.toJson(),
        authenticated: true,
      );
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final createdIssue = MaintenanceIssue.fromJson(jsonResponse);
      print(
        'MaintenanceService: Successfully created maintenance issue ${createdIssue.id}.',
      );
      return createdIssue;
    } catch (e) {
      print(
        'MaintenanceService: Error creating maintenance issue: $e. Backend integration might be pending or endpoint unavailable.',
      );
      throw Exception(
        'Failed to create maintenance issue. Backend integration pending or endpoint unavailable. Cause: $e',
      );
    }
  }

  Future<MaintenanceIssue> updateIssue(
    String issueId,
    MaintenanceIssue issueData,
  ) async {
    print(
      'MaintenanceService: Attempting to update maintenance issue $issueId...',
    );
    try {
      final response = await put(
        '/maintenance/$issueId',
        issueData.toJson(),
        authenticated: true,
      );
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final updatedIssue = MaintenanceIssue.fromJson(jsonResponse);
      print(
        'MaintenanceService: Successfully updated maintenance issue $issueId.',
      );
      return updatedIssue;
    } catch (e) {
      print(
        'MaintenanceService: Error updating maintenance issue $issueId: $e. Backend integration might be pending or endpoint unavailable.',
      );
      throw Exception(
        'Failed to update maintenance issue $issueId. Backend integration pending or endpoint unavailable. Cause: $e',
      );
    }
  }

  Future<void> deleteIssue(String issueId) async {
    print(
      'MaintenanceService: Attempting to delete maintenance issue $issueId...',
    );
    try {
      await delete('/maintenance/$issueId', authenticated: true);
      print(
        'MaintenanceService: Successfully deleted maintenance issue $issueId.',
      );
    } catch (e) {
      print(
        'MaintenanceService: Error deleting maintenance issue $issueId: $e. Backend integration might be pending or endpoint unavailable.',
      );
      throw Exception(
        'Failed to delete maintenance issue $issueId. Backend integration pending or endpoint unavailable. Cause: $e',
      );
    }
  }

  Future<MaintenanceIssue> updateIssueStatus(
    String issueId,
    IssueStatus newStatus, {
    String? resolutionNotes,
    double? cost,
  }) async {
    print(
      'MaintenanceService: Attempting to update status for maintenance issue $issueId...',
    );
    Map<String, dynamic> payload = {
      'status':
          newStatus.toString().split('.').last, // Send string representation
    };
    if (resolutionNotes != null) {
      payload['resolutionNotes'] = resolutionNotes;
    }
    if (cost != null) {
      payload['cost'] = cost;
    }
    if (newStatus == IssueStatus.completed) {
      // Added resolved as per typical flows
      payload['resolvedAt'] = DateTime.now().toIso8601String();
    }

    try {
      final response = await put(
        '/maintenance/$issueId/status',
        payload,
        authenticated: true,
      );
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final updatedIssue = MaintenanceIssue.fromJson(jsonResponse);
      print(
        'MaintenanceService: Successfully updated status for maintenance issue $issueId.',
      );
      return updatedIssue;
    } catch (e) {
      print(
        'MaintenanceService: Error updating status for maintenance issue $issueId: $e. Backend integration might be pending or endpoint unavailable.',
      );
      throw Exception(
        'Failed to update status for maintenance issue $issueId. Backend integration pending or endpoint unavailable. Cause: $e',
      );
    }
  }

  // Placeholder for image uploads if they are handled separately
  // Future<List<String>> uploadIssueImages(String issueId, List<String> imagePaths) async { ... }
}
