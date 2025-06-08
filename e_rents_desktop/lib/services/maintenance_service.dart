import 'dart:convert';
import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:e_rents_desktop/services/api_service.dart';

// TODO: Full backend integration for all maintenance features is pending.
// Ensure all endpoints are functional and error handling is robust.
class MaintenanceService extends ApiService {
  MaintenanceService(super.baseUrl, super.storageService);

  Future<List<MaintenanceIssue>> getMaintenanceIssues({
    Map<String, String>? queryParams,
  }) async {
    print('MaintenanceService: Attempting to fetch maintenance issues...');
    if (queryParams != null && queryParams.isNotEmpty) {
      print('MaintenanceService: Using query params: $queryParams');
    }
    String endpoint = '/Maintenance';
    if (queryParams != null && queryParams.isNotEmpty) {
      endpoint += '?${Uri(queryParameters: queryParams).query}';
    }
    print('MaintenanceService: Calling endpoint: $endpoint');
    try {
      final response = await get(endpoint, authenticated: true);
      print('MaintenanceService: API Response status: ${response.statusCode}');
      print('MaintenanceService: Raw API Response body: ${response.body}');

      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      print(
        'MaintenanceService: Parsed JSON response structure: ${jsonResponse.keys.toList()}',
      );

      // Handle paginated response from Universal System
      List<dynamic> itemsJson;
      if (jsonResponse.containsKey('items')) {
        // Paginated response
        itemsJson = jsonResponse['items'] as List<dynamic>;
        print(
          'MaintenanceService: Found paginated response with ${itemsJson.length} items',
        );
        if (jsonResponse.containsKey('totalCount')) {
          print(
            'MaintenanceService: Total count: ${jsonResponse['totalCount']}',
          );
        }
      } else {
        // Direct list response (fallback for non-paginated)
        itemsJson = jsonResponse as List<dynamic>;
        print(
          'MaintenanceService: Found direct list response with ${itemsJson.length} items',
        );
      }

      // Log the first item to see the structure
      if (itemsJson.isNotEmpty) {
        print('MaintenanceService: First item structure: ${itemsJson.first}');
      }

      // Add individual item parsing try-catch if needed, similar to other services
      final maintenanceIssues =
          itemsJson
              .map((json) {
                try {
                  print(
                    'MaintenanceService: Parsing item with keys: ${json.keys.toList()}',
                  );
                  final maintenanceIssue = MaintenanceIssue.fromJson(json);
                  print(
                    'MaintenanceService: Successfully parsed issue with ID: ${maintenanceIssue.maintenanceIssueId}',
                  );
                  return maintenanceIssue;
                } catch (e) {
                  print(
                    'MaintenanceService: Error parsing a maintenance issue: $e. Item data: $json',
                  );
                  return null; // Or handle more gracefully depending on UI needs
                }
              })
              .where((maintenanceIssue) => maintenanceIssue != null)
              .cast<MaintenanceIssue>()
              .toList();
      print(
        'MaintenanceService: Successfully fetched ${maintenanceIssues.length} maintenance issues.',
      );
      return maintenanceIssues;
    } catch (e) {
      print(
        'MaintenanceService: Error fetching maintenance issues: $e. Backend integration might be pending or endpoint unavailable.',
      );
      throw Exception(
        'Failed to fetch maintenance issues. Backend integration pending or endpoint unavailable. Cause: $e',
      );
    }
  }

  Future<MaintenanceIssue> getMaintenanceIssueById(
    String maintenanceIssueId,
  ) async {
    print(
      'MaintenanceService: Attempting to fetch maintenance issue $maintenanceIssueId...',
    );
    try {
      final response = await get(
        '/Maintenance/$maintenanceIssueId',
        authenticated: true,
      );
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final maintenanceIssue = MaintenanceIssue.fromJson(jsonResponse);
      print(
        'MaintenanceService: Successfully fetched maintenance issue $maintenanceIssueId.',
      );
      return maintenanceIssue;
    } catch (e) {
      print(
        'MaintenanceService: Error fetching maintenance issue $maintenanceIssueId: $e. Backend integration might be pending or endpoint unavailable.',
      );
      throw Exception(
        'Failed to fetch maintenance issue $maintenanceIssueId. Backend integration pending or endpoint unavailable. Cause: $e',
      );
    }
  }

  Future<MaintenanceIssue> createMaintenanceIssue(
    MaintenanceIssue issue,
  ) async {
    print('MaintenanceService: Attempting to create maintenance issue...');
    try {
      final response = await post(
        '/Maintenance',
        issue.toJson(),
        authenticated: true,
      );
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final createdMaintenanceIssue = MaintenanceIssue.fromJson(jsonResponse);
      print(
        'MaintenanceService: Successfully created maintenance issue ${createdMaintenanceIssue.maintenanceIssueId}.',
      );
      return createdMaintenanceIssue;
    } catch (e) {
      print(
        'MaintenanceService: Error creating maintenance issue: $e. Backend integration might be pending or endpoint unavailable.',
      );
      throw Exception(
        'Failed to create maintenance issue. Backend integration pending or endpoint unavailable. Cause: $e',
      );
    }
  }

  Future<MaintenanceIssue> updateMaintenanceIssue(
    String maintenanceIssueId,
    MaintenanceIssue maintenanceIssueData,
  ) async {
    print(
      'MaintenanceService: Attempting to update maintenance issue $maintenanceIssueId...',
    );
    try {
      final response = await put(
        '/Maintenance/$maintenanceIssueId',
        maintenanceIssueData.toJson(),
        authenticated: true,
      );
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final updatedMaintenanceIssue = MaintenanceIssue.fromJson(jsonResponse);
      print(
        'MaintenanceService: Successfully updated maintenance issue $maintenanceIssueId.',
      );
      return updatedMaintenanceIssue;
    } catch (e) {
      print(
        'MaintenanceService: Error updating maintenance issue $maintenanceIssueId: $e. Backend integration might be pending or endpoint unavailable.',
      );
      throw Exception(
        'Failed to update maintenance issue $maintenanceIssueId. Backend integration pending or endpoint unavailable. Cause: $e',
      );
    }
  }

  Future<void> deleteMaintenanceIssue(String maintenanceIssueId) async {
    print(
      'MaintenanceService: Attempting to delete maintenance issue $maintenanceIssueId...',
    );
    try {
      await delete('/Maintenance/$maintenanceIssueId', authenticated: true);
      print(
        'MaintenanceService: Successfully deleted maintenance issue $maintenanceIssueId.',
      );
    } catch (e) {
      print(
        'MaintenanceService: Error deleting maintenance issue $maintenanceIssueId: $e. Backend integration might be pending or endpoint unavailable.',
      );
      throw Exception(
        'Failed to delete maintenance issue $maintenanceIssueId. Backend integration pending or endpoint unavailable. Cause: $e',
      );
    }
  }

  Future<MaintenanceIssue> updateMaintenanceIssueStatus(
    String maintenanceIssueId,
    IssueStatus newStatus, {
    String? resolutionNotes,
    double? cost,
  }) async {
    print(
      'MaintenanceService: Attempting to update status for maintenance issue $maintenanceIssueId...',
    );
    print('MaintenanceService: New status: $newStatus');
    print('MaintenanceService: Resolution notes: $resolutionNotes');
    print('MaintenanceService: Cost: $cost');

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

    print('MaintenanceService: Request payload: ${jsonEncode(payload)}');
    print(
      'MaintenanceService: Request URL: $baseUrl/Maintenance/$maintenanceIssueId/status',
    );

    // Add platform header to ensure backend recognizes this as desktop request
    final customHeaders = {'Client-Type': 'Desktop'};

    try {
      final response = await put(
        '/Maintenance/$maintenanceIssueId/status',
        payload,
        authenticated: true,
        customHeaders: customHeaders,
      );
      print('MaintenanceService: Response status code: ${response.statusCode}');
      print('MaintenanceService: Raw response body: ${response.body}');

      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final updatedIssue = MaintenanceIssue.fromJson(jsonResponse);
      print(
        'MaintenanceService: Successfully updated status for maintenance issue $maintenanceIssueId.',
      );
      return updatedIssue;
    } catch (e) {
      print(
        'MaintenanceService: Error updating status for maintenance issue $maintenanceIssueId: $e. Backend integration might be pending or endpoint unavailable.',
      );
      print('MaintenanceService: Error type: ${e.runtimeType}');
      print('MaintenanceService: Full error details: $e');
      throw Exception(
        'Failed to update status for maintenance issue $maintenanceIssueId. Backend integration pending or endpoint unavailable. Cause: $e',
      );
    }
  }

  // Placeholder for image uploads if they are handled separately
  // Future<List<String>> uploadIssueImages(String issueId, List<String> imagePaths) async { ... }
}
