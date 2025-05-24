import 'dart:convert';
import 'dart:io';
import 'package:e_rents_mobile/core/models/maintenance_issue.dart';
import 'package:e_rents_mobile/core/services/api_service.dart';

class MaintenanceService {
  final ApiService _apiService;

  MaintenanceService(this._apiService);

  /// Submit a maintenance issue report
  Future<bool> reportMaintenanceIssue(
      MaintenanceIssue issue, List<File> images) async {
    try {
      // For now, mock the API call
      await Future.delayed(const Duration(milliseconds: 1500));

      // In a real implementation, you would:
      // 1. Upload images to the server
      // 2. Create the maintenance issue with image references
      // 3. Send notification to landlord

      /* Real API implementation would look like this:
      
      // First, upload images
      List<int> imageIds = [];
      for (File image in images) {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('${_apiService.baseUrl}/api/maintenance/upload-image'),
        );
        
        // Add auth token
        final token = await _apiService.secureStorageService.getToken();
        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }
        
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          image.path,
        ));
        
        var response = await request.send();
        if (response.statusCode == 200) {
          final responseData = await response.stream.bytesToString();
          final imageData = json.decode(responseData);
          imageIds.add(imageData['imageId']);
        }
      }
      
      // Then submit the maintenance issue
      final issueData = issue.toJson();
      issueData['imageIds'] = imageIds;
      
      final response = await _apiService.post(
        '/api/maintenance/issues',
        issueData,
        authenticated: true,
      );
      
      return response.statusCode == 201;
      */

      return true; // Mock success
    } catch (e) {
      print('Error reporting maintenance issue: $e');
      return false;
    }
  }

  /// Get maintenance issues for a tenant
  Future<List<MaintenanceIssue>> getMaintenanceIssues(int tenantId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));

      // Mock data - in real app, this would come from API
      return [
        MaintenanceIssue(
          issueId: 1,
          propertyId: 101,
          tenantId: tenantId,
          title: 'Leaky Faucet',
          description: 'The kitchen faucet has been leaking for the past week.',
          priority: MaintenanceIssuePriority.medium,
          status: MaintenanceIssueStatus.inProgress,
          dateReported: DateTime.now().subtract(const Duration(days: 3)),
          landlordResponse: 'Plumber scheduled for tomorrow morning.',
          landlordResponseDate:
              DateTime.now().subtract(const Duration(days: 1)),
        ),
        MaintenanceIssue(
          issueId: 2,
          propertyId: 101,
          tenantId: tenantId,
          title: 'Heating Issue',
          description: 'Heating not working properly in bedroom.',
          priority: MaintenanceIssuePriority.high,
          status: MaintenanceIssueStatus.reported,
          dateReported: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ];

      /* Real API call:
      final response = await _apiService.get(
        '/api/maintenance/issues/tenant/$tenantId',
        authenticated: true,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => MaintenanceIssue.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load maintenance issues');
      }
      */
    } catch (e) {
      print('Error getting maintenance issues: $e');
      return [];
    }
  }

  /// Get maintenance issue details
  Future<MaintenanceIssue?> getMaintenanceIssueDetails(int issueId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      // Mock implementation - would be API call in real app
      return null;

      /* Real API call:
      final response = await _apiService.get(
        '/api/maintenance/issues/$issueId',
        authenticated: true,
      );
      
      if (response.statusCode == 200) {
        return MaintenanceIssue.fromJson(jsonDecode(response.body));
      }
      return null;
      */
    } catch (e) {
      print('Error getting maintenance issue details: $e');
      return null;
    }
  }
}
