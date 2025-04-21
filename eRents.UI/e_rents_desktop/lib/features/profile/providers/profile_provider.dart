import 'package:flutter/material.dart';
import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/services/mock_data_service.dart';
import 'dart:convert';

class ProfileProvider extends BaseProvider<User> {
  final ApiService _apiService;
  User? _currentUser;
  String? _errorMessage;

  ProfileProvider(this._apiService) : super(_apiService) {
    enableMockData(); // Enable mock data by default
  }

  User? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;

  @override
  String get endpoint => '/profile';

  @override
  User fromJson(Map<String, dynamic> json) => User.fromJson(json);

  @override
  Map<String, dynamic> toJson(User item) => item.toJson();

  @override
  List<User> getMockItems() {
    // Use the existing mock data service
    return [MockDataService.getMockUsers().first];
  }

  /// Helper method to determine if we should use mock data
  bool _shouldUseMockData() {
    return state == ViewState.Idle && items.isEmpty;
  }

  /// Helper method to handle mock delay
  Future<void> _simulateMockDelay() async {
    await Future.delayed(const Duration(milliseconds: 10));
  }

  Future<void> fetchUserProfile() async {
    await execute(() async {
      try {
        if (_shouldUseMockData()) {
          await _simulateMockDelay();
          _currentUser = getMockItems().first;
        } else {
          final response = await _apiService.get('$endpoint/me');
          final responseData = json.decode(response.body);
          _currentUser = User.fromJson(responseData);
        }
        notifyListeners();
      } catch (e) {
        _errorMessage = e.toString();
      }
    });
  }

  Future<bool> updateProfile(User user) async {
    bool success = false;
    await execute(() async {
      try {
        if (_shouldUseMockData()) {
          await _simulateMockDelay();
          _currentUser = user;
          success = true;
        } else {
          final response = await _apiService.put('$endpoint/me', user.toJson());
          final responseData = json.decode(response.body);
          _currentUser = User.fromJson(responseData);
          success = true;
        }
      } catch (e) {
        _errorMessage = e.toString();
        success = false;
      }
    });
    return success;
  }

  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    bool success = false;
    await execute(() async {
      try {
        if (_shouldUseMockData()) {
          await _simulateMockDelay();
          success = true;
        } else {
          await _apiService.post('$endpoint/change-password', {
            'currentPassword': currentPassword,
            'newPassword': newPassword,
          });
          success = true;
        }
      } catch (e) {
        _errorMessage = e.toString();
        success = false;
      }
    });
    return success;
  }
}
