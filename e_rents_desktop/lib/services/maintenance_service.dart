import 'dart:convert';
import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:e_rents_desktop/services/api_service.dart';

/// ✅ UNIVERSAL SYSTEM MAINTENANCE SERVICE - Full Universal System Integration
///
/// This service provides maintenance management using Universal System:
/// - Universal System pagination as default
/// - Non-paginated requests using noPaging=true parameter
/// - Status updates and image uploads
/// - Property-based filtering and landlord-specific access
class MaintenanceService extends ApiService {
  MaintenanceService(super.baseUrl, super.storageService);

  String get endpoint => '/maintenance';

  /// ✅ UNIVERSAL SYSTEM: Get paginated maintenance issues with full filtering support
  /// DEFAULT METHOD - Uses pagination by default
  /// Matches: GET /maintenance?page=1&pageSize=10&sortBy=Priority&sortDesc=true
  Future<Map<String, dynamic>> getPagedMaintenanceIssues(
    Map<String, dynamic> params,
  ) async {
    try {
      // Build query string from params
      String queryString = '';
      if (params.isNotEmpty) {
        queryString =
            '?' + params.entries.map((e) => '${e.key}=${e.value}').join('&');
      }

      final response = await get('$endpoint$queryString', authenticated: true);
      return json.decode(response.body);
    } catch (e) {
      throw Exception('Failed to fetch paginated maintenance issues: $e');
    }
  }

  /// ✅ UNIVERSAL SYSTEM: Get all maintenance issues without pagination
  /// Uses noPaging=true for cases where all data is needed
  Future<List<MaintenanceIssue>> getMaintenanceIssues({
    Map<String, String>? queryParams,
  }) async {
    print('MaintenanceService: Attempting to fetch maintenance issues...');
    if (queryParams != null && queryParams.isNotEmpty) {
      print('MaintenanceService: Using query params: $queryParams');
    }

    try {
      // Convert to Map<String, dynamic> and add noPaging
      final params = <String, dynamic>{'noPaging': 'true'};
      if (queryParams != null) {
        params.addAll(queryParams);
      }

      String queryString = '';
      if (params.isNotEmpty) {
        queryString =
            '?' + params.entries.map((e) => '${e.key}=${e.value}').join('&');
      }

      final fullEndpoint = '$endpoint$queryString';
      print('MaintenanceService: Calling endpoint: $fullEndpoint');

      final response = await get(fullEndpoint, authenticated: true);
      print('MaintenanceService: API Response status: ${response.statusCode}');
      print('MaintenanceService: Raw API Response body: ${response.body}');

      final responseData = json.decode(response.body);
      print(
        'MaintenanceService: Parsed JSON response structure: ${responseData is Map ? (responseData as Map).keys.toList() : 'List response'}',
      );

      // Handle Universal System response format
      List<dynamic> itemsJson;
      if (responseData is Map && responseData.containsKey('items')) {
        // Paginated response with noPaging=true still returns wrapped format
        itemsJson = responseData['items'] as List<dynamic>;
        print(
          'MaintenanceService: Found Universal System response with ${itemsJson.length} items',
        );
        if (responseData.containsKey('totalCount')) {
          print(
            'MaintenanceService: Total count: ${responseData['totalCount']}',
          );
        }
      } else if (responseData is List) {
        // Direct list response (fallback)
        itemsJson = responseData;
        print(
          'MaintenanceService: Found direct list response with ${itemsJson.length} items',
        );
      } else {
        itemsJson = [];
        print('MaintenanceService: No items found in response');
      }

      // Log the first item to see the structure
      if (itemsJson.isNotEmpty) {
        print('MaintenanceService: First item structure: ${itemsJson.first}');
      }

      // Parse maintenance issues with error handling
      final maintenanceIssues =
          itemsJson
              .map((json) {
                try {
                  print(
                    'MaintenanceService: Parsing item with keys: ${json is Map ? json.keys.toList() : 'Invalid item'}',
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
                  return null; // Skip problematic items
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
      print('MaintenanceService: Error fetching maintenance issues: $e');
      throw Exception('Failed to fetch maintenance issues: $e');
    }
  }

  /// ✅ UNIVERSAL SYSTEM: Get maintenance issue count
  /// Uses Universal System count or extracts from paged response
  Future<int> getMaintenanceIssueCount([Map<String, dynamic>? params]) async {
    try {
      final queryParams = <String, dynamic>{
        'pageSize': 1, // Minimal page size, we only need count
        ...?params,
      };

      String queryString = '';
      if (queryParams.isNotEmpty) {
        queryString =
            '?' +
            queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
      }

      final response = await get('$endpoint$queryString', authenticated: true);
      final responseData = json.decode(response.body);
      return responseData['totalCount'] ?? 0;
    } catch (e) {
      throw Exception('Failed to get maintenance issue count: $e');
    }
  }

  /// ✅ CRUD: Get single maintenance issue by ID
  /// Matches: GET /maintenance/{id}
  Future<MaintenanceIssue> getMaintenanceIssueById(
    String maintenanceIssueId,
  ) async {
    print(
      'MaintenanceService: Attempting to fetch maintenance issue $maintenanceIssueId...',
    );
    try {
      final response = await get(
        '$endpoint/$maintenanceIssueId',
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
        'MaintenanceService: Error fetching maintenance issue $maintenanceIssueId: $e',
      );
      throw Exception(
        'Failed to fetch maintenance issue $maintenanceIssueId: $e',
      );
    }
  }

  /// ✅ CRUD: Create maintenance issue
  /// Matches: POST /maintenance
  Future<MaintenanceIssue> createMaintenanceIssue(
    MaintenanceIssue issue,
  ) async {
    print('MaintenanceService: Attempting to create maintenance issue...');
    try {
      final response = await post(
        endpoint,
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
      print('MaintenanceService: Error creating maintenance issue: $e');
      throw Exception('Failed to create maintenance issue: $e');
    }
  }

  /// ✅ CRUD: Update maintenance issue
  /// Matches: PUT /maintenance/{id}
  Future<MaintenanceIssue> updateMaintenanceIssue(
    String maintenanceIssueId,
    MaintenanceIssue maintenanceIssueData,
  ) async {
    print(
      'MaintenanceService: Attempting to update maintenance issue $maintenanceIssueId...',
    );
    try {
      final response = await put(
        '$endpoint/$maintenanceIssueId',
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
        'MaintenanceService: Error updating maintenance issue $maintenanceIssueId: $e',
      );
      throw Exception(
        'Failed to update maintenance issue $maintenanceIssueId: $e',
      );
    }
  }

  /// ✅ CRUD: Delete maintenance issue
  /// Matches: DELETE /maintenance/{id}
  Future<void> deleteMaintenanceIssue(String maintenanceIssueId) async {
    print(
      'MaintenanceService: Attempting to delete maintenance issue $maintenanceIssueId...',
    );
    try {
      await delete('$endpoint/$maintenanceIssueId', authenticated: true);
      print(
        'MaintenanceService: Successfully deleted maintenance issue $maintenanceIssueId.',
      );
    } catch (e) {
      print(
        'MaintenanceService: Error deleting maintenance issue $maintenanceIssueId: $e',
      );
      throw Exception(
        'Failed to delete maintenance issue $maintenanceIssueId: $e',
      );
    }
  }

  /// ✅ SPECIALIZED: Update maintenance issue status
  /// Matches: PUT /maintenance/{id}/status
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
      payload['resolvedAt'] = DateTime.now().toIso8601String();
    }

    print('MaintenanceService: Request payload: ${json.encode(payload)}');
    print(
      'MaintenanceService: Request URL: $baseUrl$endpoint/$maintenanceIssueId/status',
    );

    // Add platform header to ensure backend recognizes this as desktop request
    final customHeaders = {'Client-Type': 'Desktop'};

    try {
      final response = await put(
        '$endpoint/$maintenanceIssueId/status',
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
        'MaintenanceService: Error updating status for maintenance issue $maintenanceIssueId: $e',
      );
      print('MaintenanceService: Error type: ${e.runtimeType}');
      print('MaintenanceService: Full error details: $e');
      throw Exception(
        'Failed to update status for maintenance issue $maintenanceIssueId: $e',
      );
    }
  }

  /// ✅ SPECIALIZED: Upload maintenance issue images
  /// Matches: POST /maintenance/{id}/images
  /// This method can be implemented when image upload endpoint is available
  // Future<List<String>> uploadIssueImages(String issueId, List<String> imagePaths) async {
  //   // Implementation when backend supports image uploads for maintenance
  // }
}
