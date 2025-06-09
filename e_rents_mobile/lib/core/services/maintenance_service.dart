import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:e_rents_mobile/core/models/maintenance_issue.dart';
import 'package:e_rents_mobile/core/services/api_service.dart';

class MaintenanceService {
  final ApiService _apiService;

  MaintenanceService(this._apiService);

  /// Get maintenance issue by ID
  Future<MaintenanceIssue?> getMaintenanceIssueById(int issueId) async {
    try {
      final response = await _apiService.get(
        '/MaintenanceIssues/$issueId',
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return MaintenanceIssue.fromJson(data);
      } else if (response.statusCode == 404) {
        debugPrint('MaintenanceService: Issue $issueId not found');
        return null;
      } else {
        debugPrint(
            'MaintenanceService: Failed to load issue: ${response.statusCode} ${response.body}');
        throw Exception(
            'Failed to load maintenance issue: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('MaintenanceService.getMaintenanceIssueById: $e');
      if (e is Exception) rethrow;
      throw Exception('An error occurred while fetching maintenance issue: $e');
    }
  }

  /// Get maintenance issues with optional filtering parameters
  Future<List<MaintenanceIssue>> getMaintenanceIssues(
      [Map<String, dynamic>? params]) async {
    try {
      String endpoint = '/MaintenanceIssues';

      // Add query parameters if provided
      if (params != null && params.isNotEmpty) {
        final queryParams = params.entries
            .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
            .join('&');
        endpoint += '?$queryParams';
      }

      final response = await _apiService.get(endpoint, authenticated: true);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => MaintenanceIssue.fromJson(json)).toList();
      } else {
        debugPrint(
            'MaintenanceService: Failed to load issues: ${response.statusCode} ${response.body}');
        throw Exception(
            'Failed to load maintenance issues: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('MaintenanceService.getMaintenanceIssues: $e');
      if (e is Exception) rethrow;
      throw Exception(
          'An error occurred while fetching maintenance issues: $e');
    }
  }

  /// Create a new maintenance issue
  Future<MaintenanceIssue> createMaintenanceIssue(
      MaintenanceIssue issue) async {
    try {
      final response = await _apiService.post(
        '/MaintenanceIssues',
        issue.toJson(),
        authenticated: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return MaintenanceIssue.fromJson(data);
      } else {
        debugPrint(
            'MaintenanceService: Failed to create issue: ${response.statusCode} ${response.body}');
        throw Exception(
            'Failed to create maintenance issue: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('MaintenanceService.createMaintenanceIssue: $e');
      if (e is Exception) rethrow;
      throw Exception('An error occurred while creating maintenance issue: $e');
    }
  }

  /// Update an existing maintenance issue
  Future<MaintenanceIssue> updateMaintenanceIssue(
      int issueId, MaintenanceIssue issue) async {
    try {
      final response = await _apiService.put(
        '/MaintenanceIssues/$issueId',
        issue.toJson(),
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return MaintenanceIssue.fromJson(data);
      } else {
        debugPrint(
            'MaintenanceService: Failed to update issue: ${response.statusCode} ${response.body}');
        throw Exception(
            'Failed to update maintenance issue: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('MaintenanceService.updateMaintenanceIssue: $e');
      if (e is Exception) rethrow;
      throw Exception('An error occurred while updating maintenance issue: $e');
    }
  }

  /// Delete a maintenance issue
  Future<bool> deleteMaintenanceIssue(int issueId) async {
    try {
      final response = await _apiService.delete(
        '/MaintenanceIssues/$issueId',
        authenticated: true,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        debugPrint(
            'MaintenanceService: Failed to delete issue: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('MaintenanceService.deleteMaintenanceIssue: $e');
      return false;
    }
  }

  /// Upload images for maintenance issue
  Future<List<String>> uploadMaintenanceImages(List<File> images) async {
    try {
      List<String> uploadedImageIds = [];

      for (File image in images) {
        // For multipart file upload, you might need to implement this differently
        // based on your backend API requirements
        final response = await _apiService.post(
          '/MaintenanceIssues/upload-image',
          {'image': image.path}, // This would need proper multipart handling
          authenticated: true,
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          uploadedImageIds.add(data['imageId'].toString());
        }
      }

      return uploadedImageIds;
    } catch (e) {
      debugPrint('MaintenanceService.uploadMaintenanceImages: $e');
      return [];
    }
  }

  /// Submit a maintenance issue report with images
  Future<MaintenanceIssue> reportMaintenanceIssue(
      MaintenanceIssue issue, List<File> images) async {
    try {
      // First upload images if any
      List<String> imageIds = [];
      if (images.isNotEmpty) {
        imageIds = await uploadMaintenanceImages(images);
      }

      // Create issue with image references
      // You might need to modify the issue to include imageIds
      final createdIssue = await createMaintenanceIssue(issue);

      debugPrint('MaintenanceService: Issue reported successfully');
      return createdIssue;
    } catch (e) {
      debugPrint('MaintenanceService.reportMaintenanceIssue: $e');
      rethrow;
    }
  }

  /// Convenience methods for common operations

  /// Get user's maintenance issues (as reporter)
  Future<List<MaintenanceIssue>> getUserMaintenanceIssues(int userId) async {
    return await getMaintenanceIssues({'reportedByUserId': userId});
  }

  /// Get property maintenance issues
  Future<List<MaintenanceIssue>> getPropertyMaintenanceIssues(
      int propertyId) async {
    return await getMaintenanceIssues({'propertyId': propertyId});
  }

  /// Get pending maintenance issues
  Future<List<MaintenanceIssue>> getPendingMaintenanceIssues() async {
    return await getMaintenanceIssues({'statusId': 1}); // 1 = Pending
  }

  /// Get emergency maintenance issues
  Future<List<MaintenanceIssue>> getEmergencyMaintenanceIssues() async {
    return await getMaintenanceIssues({'priorityId': 4}); // 4 = Emergency
  }

  /// Assign maintenance issue to user
  Future<MaintenanceIssue> assignMaintenanceIssue(
      int issueId, int assigneeUserId) async {
    try {
      final response = await _apiService.put(
        '/MaintenanceIssues/$issueId/assign',
        {'assignedToUserId': assigneeUserId},
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return MaintenanceIssue.fromJson(data);
      } else {
        throw Exception(
            'Failed to assign maintenance issue: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('MaintenanceService.assignMaintenanceIssue: $e');
      rethrow;
    }
  }

  /// Update maintenance issue status
  Future<MaintenanceIssue> updateMaintenanceIssueStatus(
      int issueId, int statusId) async {
    try {
      final response = await _apiService.put(
        '/MaintenanceIssues/$issueId/status',
        {'statusId': statusId},
        authenticated: true,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return MaintenanceIssue.fromJson(data);
      } else {
        throw Exception('Failed to update status: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('MaintenanceService.updateMaintenanceIssueStatus: $e');
      rethrow;
    }
  }
}
