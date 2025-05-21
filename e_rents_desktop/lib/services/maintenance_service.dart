import 'dart:convert';
import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:http/http.dart' as http;

class MaintenanceService extends ApiService {
  MaintenanceService(super.baseUrl, super.storageService);

  Future<List<MaintenanceIssue>> getIssues({
    Map<String, String>? queryParams,
  }) async {
    String endpoint = '/maintenance';
    if (queryParams != null && queryParams.isNotEmpty) {
      endpoint += '?' + Uri(queryParameters: queryParams).query;
    }
    final response = await get(endpoint, authenticated: true);
    final List<dynamic> jsonResponse = json.decode(response.body);
    return jsonResponse.map((json) => MaintenanceIssue.fromJson(json)).toList();
  }

  Future<MaintenanceIssue> getIssueById(String issueId) async {
    final response = await get('/maintenance/$issueId', authenticated: true);
    final Map<String, dynamic> jsonResponse = json.decode(response.body);
    return MaintenanceIssue.fromJson(jsonResponse);
  }

  Future<MaintenanceIssue> createIssue(MaintenanceIssue issue) async {
    // The backend should ideally generate the ID.
    // The issue.toJson() should not send an ID if it's meant to be new.
    // Or the backend should ignore the ID if provided for a POST request.
    final response = await post(
      '/maintenance',
      issue.toJson(),
      authenticated: true,
    );
    final Map<String, dynamic> jsonResponse = json.decode(response.body);
    return MaintenanceIssue.fromJson(jsonResponse);
  }

  Future<MaintenanceIssue> updateIssue(
    String issueId,
    MaintenanceIssue issueData,
  ) async {
    final response = await put(
      '/maintenance/$issueId',
      issueData.toJson(),
      authenticated: true,
    );
    final Map<String, dynamic> jsonResponse = json.decode(response.body);
    return MaintenanceIssue.fromJson(jsonResponse);
  }

  Future<void> deleteIssue(String issueId) async {
    await delete('/maintenance/$issueId', authenticated: true);
  }

  Future<MaintenanceIssue> updateIssueStatus(
    String issueId,
    IssueStatus newStatus, {
    String? resolutionNotes,
    double? cost,
  }) async {
    // This endpoint might be more specific, e.g., '/maintenance/{issueId}/status'
    // Or it could be part of the general updateIssue if the backend supports partial updates via PUT.
    // Assuming a specific endpoint or that PUT to /maintenance/{issueId} can handle status changes.
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
      payload['resolvedAt'] = DateTime.now().toIso8601String();
    }

    final response = await put(
      '/maintenance/$issueId/status',
      payload,
      authenticated: true,
    ); // Assuming a dedicated status update endpoint
    final Map<String, dynamic> jsonResponse = json.decode(response.body);
    return MaintenanceIssue.fromJson(jsonResponse);
  }

  // Placeholder for image uploads if they are handled separately
  // Future<List<String>> uploadIssueImages(String issueId, List<String> imagePaths) async { ... }
}
